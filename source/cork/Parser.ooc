
use nagaqueen
import nagaqueen/OocListener

import Settings
import Project
import AST

/**
 * Builds the AST of an ooc module using nagaqueen.
 * cf. https://github.com/fasterthanlime/nagaqueen
 */
Parser: class extends OocListener {

    settings: Settings
    module: Module

    init: func (=settings)

    parse: func ~cork (project: Project, path: String) {
        module = Module new(project, path)
        if (!module file) {
            err("Could not find #{path} in #{project sourcePath}")
        }

        super(module file path)
    }

    err: func (msg: String) {
        msg print()
        exit(1)
    }

    /**
     * Do not throw an exception on unknown AST nodes.
     */
    strict?: func -> Bool { false }

    onVarAccess: func (expr: Object, name: CString) -> Object {
        "Got variable access to #{name}" println()
        null
    }

    onImport: func (path, name: CString) {
        fullPath := match {
            case path == null || path@ == '\0' =>
                "#{name}"
            case =>
                "#{path}/#{name}"
        }

        imp := Import new(fullPath)
        module imports add(imp)
    }
    
}
