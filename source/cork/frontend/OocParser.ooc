
use nagaqueen
import nagaqueen/OocListener

import cork/[Settings, Project, Token, AST, CompileError]

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

        super(module file path)
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
        (tokenPosPointer[0], tokenPosPointer[1], module token path, lineNoPointer@) as Token
    }
    
}
