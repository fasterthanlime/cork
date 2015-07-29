
import Settings
import Project
import Parser
import AST
import PathUtils

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
            (impProject, impPath) := resolveImport(module, imp path)
            parseRecursive(impProject, impPath)
        }
    }

    resolveImport: func (module: Module, importPath: String) -> (Project, String) {
        // TODO: cycle through 'used' projects
        project := module project

        // try as a relative import
        subPath := "#{module path}/../#{importPath}"
        subPath = File new(subPath) getReducedPath()
        file := project find(subPath)

        if (!file) {
            // try as an absolute import
            file := project find(importPath)
        }

        if (!file) {
            "Couldn't resolve import #{importPath} in #{module project sourceFolder path}/#{module path}" println()
            exit(1)
        }

        resolvedPath := file rebase(project sourceFolder) trimExt()
        "Resolved path = #{resolvedPath}" println()

        (module project, resolvedPath)
    }

}

