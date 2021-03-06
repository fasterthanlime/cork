
// third-party
import libuse/[UseFile, UseFileParser, PathUtils]
import libtoken/Token

// ours
import Settings
import Project
import AST
import frontend/OocParser
import CompileError
import CorkUseErrorHandler

// sdk
import structs/HashMap
import io/File

/**
 * Parses ooc modules, their uses and their imports
 */
Frontend: class {

    settings: Settings

    useFileParser: UseFileParser

    cache := HashMap<String, Object> new()
    projectCache := HashMap<String, Project> new()

    init: func (=settings) {
        useFileParser = UseFileParser new()
        useFileParser errorHandler = CorkUseErrorHandler new(settings)
        useFileParser libDirs addAll(settings oocLibDirs)
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

        "[parse] [#{project useFile identifier}] #{path}" println()

        parser := OocParser new(settings)
        parser parse(project, path)
        module := parser module

        cache put(canonicalPath, module)

        for (defaultUse in settings defaultUses) {
            // TODO: don't use a nullToken
            module uses add(Use new(nullToken, defaultUse))
        }

        for (use in module uses) {
            dependency := findProject(use identifier)
            for (path in dependency useFile imports) {
                // TODO: don't use a nullToken
                module imports add(Import new(nullToken, path))
            }
        }

        for (import in module imports) {
            (impProject, impPath) := findModule(import token, module, import path)
            parseRecursive(impProject, impPath)
        }
    }

    findProject: func (identifier: String) -> Project {
        cached := projectCache get(identifier)
        if (cached) {
            return cached
        }

        file := useFileParser findUse(identifier)

        if (!file) {
            msg := "#{identifier}.use not found in any element of $OOC_LIBS"
            settings throw(CompileError new(msg))
        }

        useFile := useFileParser parse(file)
        project := Project new(useFile)

        projectCache put(identifier, project)
        project
    }

    /**
     * Given an ooc module (for context) and an import path, find
     * the project and canonical path of the module referenced by the
     * import.
     */
    findModule: func (importToken: Token, module: Module, importPath: String) -> (Project, String) {

        project := module project

        // try as a relative import
        subPath := "#{module path}/../#{importPath}"
        subPath = File new(subPath) getReducedPath()
        file := project find(subPath)

        if (!file) {
            // try as an absolute import
            file = project find(importPath)
        }

        // try as an absolute import in used projects
        if (!file) for (use in module uses) {
            project = findProject(use identifier)
            file = project find(importPath)
            if (file) break
        }

        // try as an absolute import in requirements
        if (!file) for (req in module project useFile requirements) {
            project = findProject(req name)
            file = project find(importPath)
            if (file) break
        }

        if (!file) {
            msg := "Couldn't resolve import #{importPath} in #{module project sourceFolder path}/#{module path}"
            settings throw(CompileError new(importToken, msg))
        }

        resolvedPath := file rebase(project sourceFolder) trimExt()
        (project, resolvedPath)
    }

}

