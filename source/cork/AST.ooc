
import Project

import structs/[HashMap, MultiMap, ArrayList]
import io/File

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

    project: Project
    path: String

    file: File
    projectPath: String

    init: func (=project, =path) {
        file = project find(path, "ooc")
        projectPath = file rebase(project sourcePath) path
    }

}

/**
 * An import directive
 */
Import: class {

    path: String

    init: func (=path)

}


