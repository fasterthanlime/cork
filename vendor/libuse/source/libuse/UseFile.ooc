
// sdk
import structs/[ArrayList, HashMap]
import io/File

/**
 * AST for a .use file
 */
UseFile: class {

    identifier: String
    name: String
    description: String
    versionNumber: String
    sourcePath: String
    linker: String
    main: String
    binaryPath: String
    luaBindings: String

    imports := ArrayList<String> new()
    preMains := ArrayList<String> new()
    androidLibs := ArrayList<String> new()
    androidIncludePaths := ArrayList<String> new()
    oocLibPaths := ArrayList<File> new()
    requirements := ArrayList<Requirement> new()

    properties := ArrayList<UseProperties> new()

    file: File

    /**
     * Initialize an empty use file
     */
    init: func ~empty

}

/**
 * Properties in a .use file that are versionable
 */
UseProperties: class {
    useFile: UseFile
    useVersion: UseVersion

    pkgs := ArrayList<String> new()
    customPkgs := ArrayList<CustomPkg> new()
    additionals := ArrayList<Additional> new()
    frameworks := ArrayList<String> new()
    includePaths := ArrayList<String> new()
    includes := ArrayList<String> new()
    libPaths := ArrayList<String> new()
    libs := ArrayList<String> new()

    init: func (=useFile, =useVersion)

    merge!: func (other: This) -> This {
        pkgs addAll(other pkgs)
        customPkgs addAll(other customPkgs)
        additionals addAll(other additionals)
        frameworks addAll(other frameworks)
        includePaths addAll(other includePaths)
        includes addAll(other includes)
        libPaths addAll(other libPaths)
        libs addAll(other libs)

        this
    }
}

/**
 * Represents the requirement for a .use file, ie. a dependency
 * The 'ver' string, if non-null/non-empty, should specify a minimal
 * accepted version.
 */
Requirement: class {
    name, ver: String

    init: func (=name, =ver)
}

/**
 * A custom package is an inline pkg-config like definition
 * that allows specifying copmiler and linker flags.
 */
CustomPkg: class {
    utilName: String
    names := ArrayList<String> new()
    cflagArgs := ArrayList<String> new()
    libsArgs := ArrayList<String> new()

    init: func (=utilName)
}

/**
 * An additional is a .c file that you want to add to your ooc project to be
 * compiled in.
 */
Additional: class {
    relative: File { get set }
    absolute: File { get set }

    init: func (=relative, =absolute)
}

/**
 * Versioned block in a use def file
 */
UseVersion: class {
    useFile: UseFile

    init: func (=useFile)

    satisfied?: func (target: Target) -> Bool {
        true
    }

    toString: func -> String {
        "true"
    }

    _: String { get { toString() } }
}

UseVersionValue: class extends UseVersion {
    value: String

    init: func (.useFile, =value) {
        super(useFile)
    }

    satisfied?: func (target: Target) -> Bool {
        match value {
            case "linux" =>
                target == Target LINUX
            case "windows" =>
                target == Target WINDOWS
            case "solaris" =>
                target == Target SOLARIS
            case "haiku" =>
                target == Target HAIKU
            case "apple" =>
                target == Target OSX
            case "freebsd" =>
                target == Target FREEBSD
            case "openbsd" =>
                target == Target OPENBSD
            case "netbsd" =>
                target == Target NETBSD
            case "dragonfly" =>
                target == Target DRAGONFLY
            case "android" =>
                // android version not supported yet, false by default
                false
            case "ios" =>
                // ios version not supported yet, false by default
                false
            case =>
                message := "Unknown version #{value}"
                raise(UseFormatError new(useFile, message) toString())
                false
        }
    }

    toString: func -> String {
        "%s" format(value)
    }
}

UseVersionAnd: class extends UseVersion {
    lhs, rhs: UseVersion

    init: func (.useFile, =lhs, =rhs) {
        super(useFile)
    }

    satisfied?: func (target: Target) -> Bool {
        lhs satisfied?(target) && rhs satisfied?(target)
    }

    toString: func -> String {
        "(%s && %s)" format(lhs _, rhs _)
    }
}

UseVersionOr: class extends UseVersion {
    lhs, rhs: UseVersion

    init: func (.useFile, =lhs, =rhs) {
        super(useFile)
    }

    satisfied?: func (target: Target) -> Bool {
        lhs satisfied?(target) || rhs satisfied?(target)
    }

    toString: func -> String {
        "(%s || %s)" format(lhs _, rhs _)
    }
}

UseVersionNot: class extends UseVersion {
    inner: UseVersion

    init: func (.useFile, =inner) {
        super(useFile)
    }

    satisfied?: func (target: Target) -> Bool {
        !inner satisfied?(target)
    }

    toString: func -> String {
        "!(%s)" format(inner _)
    }
}

/**
 * Compilation target
 */
Target: enum {
    LINUX
    WINDOWS
    SOLARIS
    HAIKU
    OSX
    FREEBSD
    OPENBSD
    NETBSD
    DRAGONFLY
}

/**
 * Syntax or other error in .use file
 */
UseFormatError: class {
    useFile: UseFile
    message: String

    init: func (=useFile, =message)

    toString: func -> String {
        "Error while parsing #{useFile file path}: #{message}"
    }
}

