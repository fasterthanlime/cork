
// third-party
import libtoken/Token

// ours
import Project

// sdk
import structs/[HashMap, MultiMap, ArrayList]
import io/File

/**
 * Base class for all AST nodes
 */
OocNode: class {

    token: Token

    init: func (=token)

}

/**
 * A compilation unit (an .ooc file)
 */
Module: class extends OocNode {

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

        super((0, 0, file getPath(), 0) as Token)
        projectPath = file rebase(project sourceFolder) path
    }

}

/**
 * A use directive
 */
Use: class extends OocNode {

    identifier: String

    init: func (=token, =identifier)

}

/**
 * An import directive
 */
Import: class extends OocNode {

    path: String

    init: func (=token, =path)

}


