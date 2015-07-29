
import structs/[HashMap, MultiMap, ArrayList]

/**
 * Base class for all AST nodes
 */
Node: class {

    init: func

}

/**
 * A compilation unit (an .ooc file)
 */
Module: class {

    imports := ArrayList<Import> new()

    init: func

}

/**
 * An import directive
 */
Import: class {

    path: String

    init: func (=path)

}


