
// third-party
import nagaqueen/[callbacks, OocListener]
import libtoken/Token

// ours
import cork/[Settings, Project, AST, CompileError]

// sdk
import io/File
import structs/Stack

/**
 * Builds the AST of an ooc module using nagaqueen.
 * cf. https://github.com/fasterthanlime/nagaqueen
 */
OocParser: class extends OocListener {

    DEBUG := false

    settings: Settings
    module: Module

    stack := Stack<OocNode> new()

    init: func (=settings)

    parse: func ~cork (project: Project, path: String) {
        module = Module new(project, path)
        if (!module file) {
            err("Could not find #{path} in #{project sourceFolder path}")
        }

        contents := File new(module file path) read()
        nq_memparse(this, contents, contents size)
    }

    err: func (msg: String) {
        settings throw(CompileError new(msg))
    }

    /**
     * Do not throw an exception on unknown AST nodes.
     */
    strict?: func -> Bool { false }

    /*
     * Directives
     */

    onUse: func (name: CString) {
        use := Use new(token(), name toString())
        module uses add(use)
    }

    onImport: func (path, name: CString) {
        fullPath := match {
            case path == null || path@ == '\0' =>
                "#{name}"
            case =>
                "#{path}/#{name}"
        }

        imp := Import new(token(), fullPath)
        module imports add(imp)
    }

    /*
     * Functions
     */

    onFunctionStart: func (name, doc: CString) {
        push(Function new(token(), name toString()))
    }

    onFunctionEnd: func -> Function {
        pop(Function)
    }

    /*
     * Operator overload
     */

    onOperatorBodyStart: func {
        push(Function new(token(), ""))
    }

    /*
     * Expressions
     */

    onVarAccess: func (expr: Object, name: CString) -> Object {
        null
    }
    /**
     * Build a token from the start/end/lineno information passed by nagaqueen
     */
    token: func -> Token {
        (module token path, tokenPosPointer[0], tokenPosPointer[1], module token path) as Token
    }

    push: func <T> (t: T) -> T {
        node := t as OocNode
        debug("Pushing #{node}")
        stack push(node)
        node
    }

    pop: func <T> (T: Class) -> T {
        node := stack pop()
        debug("Popped #{node}")
        if (!node instanceOf?(T)) {
            msg := "In parser, expected to pop a #{T name}, but popped a #{node class name}"
            settings throw(CompileError new(token(), msg))
        }
        return node
    }

    debug: func (msg: String) {
        if (DEBUG) {
            "[cork debug] [#{module file path}] #{msg}" println()
        }
    }
    
}
