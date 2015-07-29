
## Dependencies / resolution order

One can view a piece of ooc AST as a dependency tree:

```ooc
a := 1
b := 2
c := a + b
```

Each VDFE depends on its right-hand-side to resolve their own types.

Both `1` and `2` are numeric literals, which are easy to resolve (default to
Int), so the types of a and b are straightforward, and then `a + b` is a binary
operation, the type of which is also easy to infer, which gives us the type of c.

So our tree looks something like:

```
  - vdfe(name = c, expr = binop(+, acc(a), acc(b)))
    - binop(+, acc(a), acc(b))
      - acc(a)
        - vdfe(name = a, expr = literal(1))
          - literal(1)
      - acc(b)
        - vdfe(name = b, expr = literal(2))
          - literal(2)
```

And we can simply resolve that from the bottom up. It's tempting to just have
a `type resolving` phase where we get the types and references of everything,
so that we have:

```
  - literal(1) => Int
  - vdfe(name = a) => Int
  - acc(a) => Int
  - literal(2) => Int
  - vdfe(name = b) => Int
  - acc(b) => Int
  - binop(+, =>Int, =>Int) => Int
  - vdfe(name = c) => Int
```

But what if someone added code like that:

```ooc
operator + (x, y: Int) -> String { "#{x}#{y}" }
```

Then the type of the `binop` isn't `Int`, it's `String`, but we don't know
that unless we've resolved the binop to an operator overload.

So our tree looks something like:

```
  - vdfe(name = c, expr = binop(+, acc(a), acc(b)))
    - binop(+, acc(a), acc(b))
      - acc(a)
        - vdfe(name = a, expr = literal(1))
          - literal(1)
      - acc(b)
        - vdfe(name = b, expr = literal(2))
          - literal(2)
      - opdecl(+, x, y)
        - vdecl(x, Int)
        - vdecl(y, Int)
        - body
          - interpolatedliteral(fmt, x, y)
            - acc(x)
              - vdecl(x, Int)
            - acc(y)
              - vdecl(y, Int)
```

And we're starting to have nodes that appear in several places..

Closures, that infer the types of their arguments, and even sometimes their return
type, also prevent us from building a simple tree.

```ooc
do: func (f: Func (String)) {
  f("Hi")
}

do(|j|
  j println()
)
```

Tentative tree:

```
  - call(name = do, args = closure)
    - fdecl(name = do, args = ...)
      - vdecl(name = f, type = functype(args = [String]))
      - call(name = f, args = [stringliteral("hi")])
        - etc.
    - closure
    - vdecl(name = j)
      - call (name = println, expr = acc(j))
        - fdecl(name = do, args = ...)
          - vdecl(name = f, type = functype(args = [String]))
          - etc.
```

And that tree has cycles..

So, separating passes might be harder than expected.

## AST transformations

Our goal with AST transformations during the reoslve phase would be that each
transformation should be a simple replace, not inserts before, inserts after,
etc.

More complex AST transformations that involve inserts (for example, turning
string literals into global variable declarations with a call to
`makeStringLiteral`, or ooc varargs, closures) should be done in a separate
phase, after resolving is done.

Let's review various AST transformations.

### Property sets / gets

Variable accesses can be turned into property sets or gets:

```ooc
Foo: class {
  a: String { get set }
}

f := Foo new()
f a = "Hello"
f a println()
```

Instead of generating something like:

```c
Foo f = Foo_new();
f->a = "Hello";
String_println(f->a)
```

It generates something like:

```c
Foo f = Foo_new();
Foo_set_a(f, "Hello");
String_println(Foo_get_a(f));
```

However, setters behave like members, so there's no need to do that when
in the resolve pass.

### Tuple decl / tuple assignment

```ooc
a, b: Int
(a, b) = (42, 12)
```

Should generate C code like:

```c
Int a;
Int b;
a = 42;
b = 12;
```

There's several ways to go about this. Assigning to a variable is complicated,
it might involve implicit casts, generic boxing or unboxing, promotion/demotion
of numeric types, etc.

In rock, it's unwrapped:

```ooc
// this code
(a, b, c) = (1, 2, 3)

// becomes:
a = 1
b = 2
c = 3
```

And then all assignments can be resolved as separate nodes (so, looping is
required).

The actual AST manipulation steps that happen are

```ooc
// parsed code
(a, b, c) = (1, 2, 3)

// step 1 - addBeforeInScope
a = 1
(a, b, c) = (1, 2, 3)

// step 2 - addBeforeInScope
a = 1
b = 2
(a, b, c) = (1, 2, 3)

// step 2 - replace
a = 1
b = 2
c = 3
```

If the assignment logic in BinaryOp didn't assume there was a single LHS,
we wouldn't even need to unwrap at this stage, we could create several C AST
nodes to handle each separate assignment.

Declarations are even worse:

```ooc
(a, b, c) := (1, 2, 3)
a toString() println()
```

If we were trying to unwrap to a single node, it would be tempting to unwrap
to a Block, but it wouldn't work, since the variables would be wrongly scoped.

```ooc
{
  a, b, c: Int
  a = 1
  b = 2
  c = 3
}
a toString() println()
```

Hence, the way variable declarations are stored in rock are flawed. Ideally,
we could keep `(a, b, c) := (1, 2, 3)` around in the AST as-is (it might
be transformed later, once the resolve pass is finished), and still be able
to match the right-hand-sides with the left-hand-sides, and have accesses
to it be resolved normally.

(To be continued..)

