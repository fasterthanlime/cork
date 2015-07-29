
~~~ July 29th, 3AM ~~~

I (amos) have been wanting to rewrite rock's ast & resolve process for a while now.

## How rock works

rock's AST is a mix of ooc and C. There's stuff you can achieve with the ooc
AST that you can't write with ooc syntax.

For example, rock's AST contains a `StructLiteral` node, which is only achievable
in ooc via something like `(a, b, c) as Foo` where `Foo` is a compound cover
type.

So, the parsed AST looks something like:

```
Cast(inner=Tuple(a, b, c), type=Foo)
```

rock's resolve process is a remnant of what I thought OO programming was about
back in 2009. I hadn't touched much FP, arguably, and so, every AST node is
responsible for resolving itself.

Every Node has a resolve method, like so:

```
resolve: func (res: Resolver, trail: Trail) -> Response {
  // do things

  if (condition) {
    // soft loop
    res wholeAgain(this, "waiting on something")
    return Response OK
  }

  if (condition2) {
    if (!trail peek() replace(this, transformed)) {
      err := CouldntReplace new(this, transformed)
      res throwError(err)
    }

    // replaced ourselves, trail is messed up, hard loop
    return Response LOOP
  }

  Response OK
}
```

Note that the resolver is responsible for catching errors and printing them
properly (all children of the `Error` class take a token, so we know which
part of the source to show), it also remembers the last `wholeAgain` call
(or prints all in the fatal round, if --allerrors is enabled), and it does
something particular if the root node (a `Module`) returns Response LOOP

Nodes often have children, for example, a `BinaryOp` has two children:
left, and right. It's the node's responsibility to resolve its children,
which causes problems sometimes. Badly coded Nodes might call resolve once
on children and then forget to loop if they're not done - since only the
return value from the parent ultimately counts.

Example of badly coded node:

```
BinaryOp: class extends Node {

  left, right: Expression

  resolve: func (res: Resolver, trail: Trail) -> Response {
    trail push(this)
    left resolve(res, trail) // oops, not checking return value
    right resolve(res, trail)
    trail pop(this)

    // oops, not checking if left & right have a proper type,
    // if `isResolved()` returns true, etc.

    Response OK
  }

}
```

So, every `resolve()` method has many responsibilities:

  * It mustn't forget about any child nodes
  * If it infers something (for example, `_` in a tuple assignment shouldn't
  err with `Undefined symbol` but rather omit that part) then it might want
  to hold on resolving child nodes until later - sometimes it gets tricky(1)
  * If a child returns `Response LOOP`, it must immediately relay that as its
  return value. If any of the nodes in the trail fail to do that, the chain
  is broken and the hard loop is ignored, causing hard-to-debug problems.
  * It must manually push and pop itself off the trail when resolving child
  nodes (the Trail is mutable! even though it's passed by argument and could
  just as well be a member of Resolver)
  * If it makes AST modifications, it must figure out if the trail is now
  invalid (because node changed parents), and provoke a hard loop, which wastes
  a lot of time.

(1): `FunctionDecl` the largest AST node after `FunctionCall`, has a hack
called `countdown`, where it will make sure it `wholeAgain(s)` at least 5 times
before attempting to unwrap a closure. This is madness.

Why do loops waste a lot of time? Because a lot of checks are being done again,
for each round, even when it wouldn't be necessary. To prove my point, I just
added a simple `timesResolved` counter to VariableAccess, and found that the `code`
variable in `sdk/lang/Eception` was resolved up to 67 times!

Why do we go through the whole AST on every round? Isn't that why we have
`isResolved`? Well, `isResolved` lies, even when it's implemented in a smart way.
`isResolved` is a method that's supposed to return true when there is no further
reason to call `resolve` on a Node anymore - when all its children, its type,
etc., is all done, set in stone, nothing more to change about it.

But some nodes' `resolvedness` depends on their trail. Most nodes act differently
depending on what their parent is. For example, `VariableAccess` checks if it is
the LHS(2) of an assignment, and if it refers to a property access - in which case,
it should be replaced with a property setter call.

(2): Left-hand-side

So, if those nodes are being moved around, they need to resolve again (discarding
their `_resolved` internal marker) to make sure they didn't miss anything.

I've tried implementing `isResolved` to avoid unnecessary re-resolving, but with
little success. Once stumbling upon the more complicated AST nodes, it's rock
error (unsuccessful resolve) upon rock crash (unresolved stuff being written
in the backend) piling up.

## How oc works

oc is an experimental compiler I wrote back in 2010, out of frustration with rock.

It has a few notable differences - the resolving process revolves around Tasks,
which are basically coroutines on steroids.

Nodes still have a `resolve` method, but they take a `Task`, and queue stuff
onto it. `Task` instances have a pool of things to do. They have ways to queue
a single task, multiple tasks, that they'll exhaust by switching to them one after
the other, adding the unfinished ones to the next pool, then running the next pool
and so on until the next pool is the empty set.

It also has some additional logic to handle node indices, so that the following
code:

```
main: func {
  a println()
  a := "Hello"
}
```

Can fail with `Undefined symbol 'a'` rather than generate invalid C code.

The ideas in oc are seductive, but simplistic. Trying to implement generics in
it would be impossible. Many other things that ooc now allows would be
unachievable with that simple concept.

## Building a better compiler

I've wanted to mess around with an immutable AST for a while, because rock's
AST made me run my head into a wall on many occasions - forgetting to call
`clone()`, or Nodes incorrectly implementing `clone()`, for example.

But implementing performant immutable data structure is another big project,
and since my time is limited, I believe a better compiler can be built.

Lessons learned from previous attempts:

  - Nodes having a `resolve` method with a return value is bad - desugaring
  algorithms should be implemented as function *outside* of nodes. AST nodes
  should be dumb data classes that can be navigated easily.
  - Looping is bad, we shouldn't have to 'empirically come up with a sane
  default for maxrounds'. maxrounds shouldn't exist at all.
  - Coroutines are a good idea, but desugaring algorithms can be written such
  that context can be kept in a more lightweight structure (not the full C
  stack), so that resumable tasks are stored as plain data.
  - both rock & oc try to do too many things in a single pass - it looks like
  a single pass, but it's actually a dozen passes intertwined, and rock is
  full of hacks to make sure they don't clash, but sometimes it still fails.
  - dynamic libraries for pluggable frontends & backends is cute, but the result
  is that rock changed and oc no longer compiles, so let's go with something
  simple for now.
  - being able to dump the AST to a sane format (JSON?) would be invaluable,
  would enable building an AST explorer for various stages of the compilation,
  possibly in another, friendlier language.
  - mixing ooc AST and C ast isn't a good idea. However, having more specific
  ooc AST nodes (e.g. PropertySetterCall, GenericUnboxing) is a good idea.

So: separate functions and data (sound familiar?), embrace the idea of having
several passes, forget about coroutines and dynlibs.

Let's see where this goes.

