
import Settings
import Frontend

import structs/ArrayList

/**
 * The heart of cork - drives the front-end, middle-end,
 * and back-end.
 */
Compiler: class {

    units := ArrayList<String> new()
    settings: Settings

    init: func (=settings) {
        // nothing
    }

    addUnit: func (path: String) {
        units add(path)
    }

    run: func {
        if (units empty?()) {
            "Nothing to compile, bailing out." println()
            return
        }

        frontend := Frontend new(settings)

        for (unit in units) {
            frontend parseRecursive(unit)
        }
    }

}

cop: func (path: String) {

}

