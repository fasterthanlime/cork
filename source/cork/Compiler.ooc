
import Settings
import Frontend
import Project

import libuse/UseFile

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

    run: func {
        if (!settings main) {
            "Nothing to compile, bailing out." println()
            return
        }

        frontend := Frontend new(settings)

        project := settings main
        if (!project useFile main) {
            "Lib-compilation not supported yet" println()
            return
        }

        frontend projectCache put(project useFile identifier, project)
        frontend parseRecursive(project, project useFile main)
    }

}

