
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
    uses := ArrayList<Use> new()

    project: Project
    path: String

    file: File
    projectPath: String

    init: func (=project, =path) {
        file = project find(path, "ooc")
        if (!file) {
            raise("Invalid module instantiation! Couldn't find #{path} in #{project id}")
        }
        projectPath = file rebase(project sourceFolder) path
    }

}

/**
 * A use directive
 */
Use: class {

    identifier: String

    init: func (=identifier)

}

/**
 * An import directive
 */
Import: class {

    path: String

    init: func (=path)

}


