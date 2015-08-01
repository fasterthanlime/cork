
// third-party
import nagaqueen/[callbacks, OocListener]
import libtoken/Token

// ours
import cork/[Settings, Project, AST, CompileError]

// sdk
import io/File

/**
 * Builds the AST of an ooc module using nagaqueen.
 * cf. https://github.com/fasterthanlime/nagaqueen
 */
OocParser: class extends OocListener {

    settings: Settings
    module: Module

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

    onVarAccess: func (expr: Object, name: CString) -> Object {
        null
    }

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

    /**
     * Build a token from the start/end/lineno information passed by nagaqueen
     */
    token: func -> Token {
        (module token path, tokenPosPointer[0], tokenPosPointer[1], module token path) as Token
    }
    
}
