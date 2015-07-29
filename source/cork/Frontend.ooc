
import Settings
import Project
import Parser
import AST

import libuse/UseFile

import structs/HashMap
import io/File

/**
 * Parses modules and their imports
 */
Frontend: class {

    settings: Settings

    cache := HashMap<String, Object> new()

    init: func (=settings) {
        // muffin.
    }

    /**
     * Parse a given ooc module and all its imports, recursively.
     */
    parseRecursive: func (project: Project, path: String) {
        canonicalPath := "#{project useFile identifier}/#{path}"
        if (cache contains?(canonicalPath)) {
            // already done
            return
        }

        parser := Parser new(settings)
        parser parse(project, path)
        module := parser module

        cache put(canonicalPath, module)

        for (imp in module imports) {
            // TODO: look the imports up
            // parseRecursive(imp path)
        }
    }

}

