
// third-party
use libtoken
import libtoken/[Token]

// sdk
import io/[File, FileReader, StringReader]
import structs/[ArrayList, HashMap, Stack]
import text/StringTokenizer

// ours
import UseFile
import PathUtils

/**
 * Error handler for use files
 */
UseErrorHandler: class {

    init: func

    throw: func (t: Token, msg: String) {
        raise(msg)
    }

}

/**
 * Caching interface to `UseFileReader`
 */
UseFileParser: class {

    libDirs := ArrayList<String> new()

    errorHandler := UseErrorHandler new()

    init: func
    
    parse: func (file: File) -> UseFile {
        reader := UseFileReader new(errorHandler, file)
        reader useFile
    }

    findUse: func (identifier: String) -> File {
        fileName := "#{identifier}.use"

        for (dir in libDirs) {
            res := File new(dir) findShallow(fileName, 3)
            if (res) return res
        }

        null
    }

}

/**
 * Recursive descent parser for .use files
 * cf. https://ooc-lang.org/docs/tools/rock/usefiles/
 */
UseFileReader: class {

    file: File
    useFile: UseFile

    errorHandler: UseErrorHandler

    versionStack := Stack<UseProperties> new()

    init: func (=errorHandler, =file) {
        if (!file exists?()) {
            errorHandler throw(nullToken, ".use file not found: #{file path}")
        }

        useFile = UseFile new()
        useFile file = file
        useFile identifier = file name trimExt()
        
        "[parse] [#{useFile identifier}] .use file" println()
        readTop()
    }

    /**
     * Top reading method - reads the whole .use file line by line, calls
     * reading sub-methods for complicated stuff.
     */
    readTop: func {
        reader := FileReader new(file)

        versionStack push(UseProperties new(useFile, UseVersion new(useFile)))

        while (reader hasNext?()) {
            start := reader mark()

            line := reader readLine() \
                           trim() /* general whitespace */ \
                           trim(8 as Char /* backspace */) \
                           trim(0 as Char /* null byte */)

            if (line empty?() || line startsWith?('#')) {
                // skip comments
                continue
            }

            lineReader := StringReader new(line)
            if (line startsWith?("version")) {
                lineReader readUntil('(')
                lineReader rewind(1)
                start += lineReader mark() - 1
                versionExpr := lineReader readAll()[0..-2] trim()

                useVersion := readVersionExpr(start, versionExpr)
                versionStack push(UseProperties new(useFile, useVersion))
                continue
            }

            if (line startsWith?("}")) {
                child := versionStack pop()
                parent := versionStack peek()

                child useVersion = UseVersionAnd new(useFile, parent useVersion, child useVersion)
                useFile properties add(child)
                continue
            }

            id := lineReader readUntil(':')
            value := lineReader readAll() trim()

            if (id startsWith?("_")) {
                // reserved ids for external tools (packaging, etc.)
                continue
            }

            current := versionStack peek()

            if (id == "Name") {
                useFile name = value
            } else if (id == "Description") {
                useFile description = value
            } else if (id == "Pkgs") {
                for (pkg in value split(',')) {
                    current pkgs add(pkg trim())
                }
            } else if (id == "CustomPkg") {
                current customPkgs add(readCustomPkg(value))
            } else if (id == "Libs") {
                for (lib in value split(',')) {
                    current libs add(lib trim())
                }
            } else if (id == "Frameworks") {
                for (framework in value split(',')) {
                    current frameworks add(framework trim())
                }
            } else if (id == "Includes") {
                for (inc in value split(',')) {
                    current includes add(inc trim())
                }
            } else if (id == "PreMains") {
                for (pm in value split(',')) {
                    useFile preMains add(pm trim())
                }
            } else if (id == "Linker") {
                useFile linker = value trim()
            } else if (id == "BinaryPath") {
                useFile binaryPath = value trim()
            } else if (id == "LibPaths") {
                for (path in value split(',')) {
                    libFile := File new(path trim())
                    if (libFile relative?()) {
                        libFile = file parent getChild(path) getAbsoluteFile()
                    }
                    current libPaths add(libFile path)
                }
            } else if (id == "IncludePaths") {
                for (path in value split(',')) {
                    incFile := File new(path trim())
                    if (incFile relative?()) {
                        incFile = file parent getChild(path) getAbsoluteFile()
                    }
                    current includePaths add(incFile path)
                }
            } else if (id == "AndroidLibs") {
                for (path in value split(',')) {
                    useFile androidLibs add(path trim())
                }
            } else if (id == "AndroidIncludePaths") {
                for (path in value split(',')) {
                    useFile androidIncludePaths add(path trim())
                }
            } else if (id == "OocLibPaths") {
                for (path in value split(',')) {
                    relative := File new(path trim()) getReducedFile()

                    if (!relative relative?()) {
                        "[WARNING]: ooc lib path #{relative path} is absolute - it's been ignored" println()
                        continue
                    }

                    candidate := file parent getChild(relative path)

                    absolute := match (candidate exists?()) {
                        case true =>
                            candidate getAbsoluteFile()
                        case =>
                            relative
                    }

                    useFile oocLibPaths add(absolute)
                }
            } else if (id == "Additionals") {
                for (path in value split(',')) {
                    relative := File new(path trim()) getReducedFile()

                    if (!relative relative?()) {
                        "[WARNING]: Additional path #{relative path} is absolute - it's been ignored" println()
                        continue
                    }

                    candidate := file parent getChild(relative path)

                    absolute := match (candidate exists?()) {
                        case true =>
                            candidate getAbsoluteFile()
                        case =>
                            relative
                    }
                    current additionals add(Additional new(relative, absolute))
                }
            } else if (id == "Requires") {
                for (req in value split(',')) {
                    useFile requirements add(Requirement new(req trim(), "0"))
                }
            } else if (id == "SourcePath") {
                if (useFile sourcePath) {
                    "Duplicate SourcePath entry in #{file path}" println()
                } else {
                    useFile sourcePath = value
                }
            } else if (id == "Version") {
                useFile versionNumber = value
            } else if (id == "Imports") {
                readImports(value)
            } else if (id == "Origin" || id == "Variant") {
                // known, but ignored ids
            } else if (id == "Main") {
                main := value
                if (main toLower() endsWith?(".ooc")) {
                    main = main trimExt()
                }
                useFile main = main
            } else if (id == "LuaBindings") {
                useFile luaBindings = value
            } else if (!id empty?()) {
                "Unknown key in %s: %s" format(file getPath(), id) println()
            }
        }

        reader close()
        useFile properties add(versionStack pop())
    }

    /**
     * Read a custom pkg directive
     */
    readCustomPkg: func (value: String) -> CustomPkg {
        vals := value split(',')
        pkg := CustomPkg new(vals[0])

        if (vals size >= 2) {
            pkg names addAll(vals[1] trim() split(' ', false))
        }

        if (vals size >= 4) {
            pkg cflagArgs addAll(vals[2] trim() split(' ', false))
            pkg libsArgs addAll(vals[3] trim() split(' ', false))
        } else {
            // If 3rd and 4th argument aren't present, assume pkgconfig-like behavior
            pkg cflagArgs add("--cflags")
            pkg libsArgs add("--libs")
        }

        pkg
    }

    /**
     * Parse a version expression such as:
     *
     *   windows && !(linux || (apple && ios))
     *
     */
    readVersionExpr: func (offset: Long, expr: String) -> UseVersion {
        reader := StringReader new(expr)
        not := false

        if (reader peek() == '!') {
            reader read()
            not = true
        }

        result: UseVersion

        if (reader peek() == '(') {
            reader read()
            level := 1

            buff := Buffer new()
            while (reader hasNext?()) {
                c := reader read()
                match c {
                    case '(' =>
                        level += 1
                        buff append(c)
                    case ')' =>
                        level -= 1
                        if (level == 0) {
                            break
                        }
                        buff append(c)
                    case =>
                        buff append(c)
                }
            }

            inner := buff toString()
            result = readVersionExpr(offset + reader mark(), inner)
        } else {
            // read an identifier
            value := reader readWhile(|c| c alphaNumeric?())
            result = UseVersionValue new(useFile, value)
        }

        if (not) {
            result = UseVersionNot new(useFile, result)
        }

        // skip whitespace
        reader skipWhile(|c| c whitespace?())

        if (reader hasNext?()) {
            c := reader read()
            match c {
                case '&' =>
                    // skip the second one
                    reader read()
                    reader skipWhile(|c| c whitespace?())

                    inner := readVersionExpr(offset + reader mark(), reader readAll())
                    result = UseVersionAnd new(useFile, result, inner)
                case '|' =>
                    // skip the second one
                    reader read()
                    reader skipWhile(|c| c whitespace?())

                    inner := readVersionExpr(offset + reader mark(), reader readAll())
                    result = UseVersionOr new(useFile, result, inner)
                case =>
                    errorHandler throw(token(offset + reader mark() - 1, 1), "Malformed version expression: #{expr}. Unexpected char `#{c}`")
            }
        }

        result
    }

    /**
     * Read an imports directive, could be:
     *
     *   some/module, some/other/module
     *
     * Or grouped imports:
     *
     *   some/package/contains/[a, few, modules]
     *
     */
    readImports: func (value: String) {
        sr := StringReader new(value)

        while (sr hasNext?()) {
            start := sr readUntil('[')

            if (sr hasNext?()) {
                inside := sr readUntil(']')

                // grouped imports
                inside split(',') each(|s|
                    useFile imports add(start + s trim())
                )
            } else {
                // regular imports
                value split(',') each(|s|
                    useFile imports add(s trim())
                )
            }
        }
    }

    token: func (start, length: Int) -> Token {
        (start, length, file path, 0) as Token
    }

}

