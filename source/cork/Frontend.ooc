
import Settings
import Parser
import AST

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
    parseRecursive: func (path: String) {
        file := File new(path)
        if (!file exists?()) {
            "File not found: #{file path}, bailling out.." println()
            exit(1)
        }

        canonicalPath := file getAbsolutePath()
        if (cache contains?(canonicalPath)) {
            // already done
            return
        }

        parser := Parser new(settings)
        parser parse(file path)

        for (imp in parser module imports) {
            parseRecursive(imp path)
        }
    }

}

