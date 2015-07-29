
use nagaqueen
import nagaqueen/OocListener

import Settings
import AST

/**
 * Builds the AST of an ooc module using nagaqueen.
 * cf. https://github.com/fasterthanlime/nagaqueen
 */
Parser: class extends OocListener {

    settings: Settings
    module: Module

    init: func (=settings)

    parse: func (path: String) {
        module = Module new()

        super(path)
    }

    /**
     * Do not throw an exception on unknown AST nodes.
     */
    strict?: func -> Bool { false }

    onVarAccess: func (expr: Object, name: CString) -> Object {
        "Got variable access to #{name}" println()
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
