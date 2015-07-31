
// third-party
import libtoken/ErrorOutput

// ours
import Project, CompileError

// sdk
import structs/ArrayList
import os/Env
import os/Terminal
import io/File
import text/StringTokenizer

/**
 * Compiler settings - library paths, verbosity level, you name it.
 */
Settings: class {

    main: Project

    oocLibDirs := ArrayList<String> new()
    cArgs := ArrayList<String> new()

    defaultUses := ArrayList<String> new()

    verbosity := Verbosity NORMAL

    errorHandler := TerminalErrorOutput new()

    init: func {
        readOocLibs()

        // use the SDK by default
        defaultUses add("sdk")
    }

    readOocLibs: func {
        oocLibs := Env get("OOC_LIBS")
        if (!oocLibs) {
            err("$OOC_LIBS environment variable not set, bailing out")
        }

        oocLibDirs addAll(oocLibs split(File pathDelimiter))
    }

    err: func (msg: String) {
        throw(ConfigurationError new(msg))
    }

    /**
     * Throw a compilation error
     */
    throw: func (err: CompileError) {
        if (err token path) {
            err token writeMessage("", err msg, err level toString(), errorHandler)
        } else {
            color := match (err level) {
                case ErrorLevel ERROR   => Color red
                case ErrorLevel WARNING => Color yellow
                case ErrorLevel WARNING => Color blue
            }
            errorHandler setColor(color)
            "[cork error] #{err msg}" println()
            errorHandler reset()
        }

        match (err level) {
            case ErrorLevel ERROR =>
                CompilationFailed new(err) throw()
        }
    }

}

/**
 * Thrown when a compilation error is thrown inside
 * of cork, inside of calling exit (in case cork is ever
 * used as a library..)
 */
CompilationFailed: class extends Exception {

    err: CompileError

    init: func (=err) {
        super("There was a problem in the compilation process.")
    }

}

Verbosity: enum {
    SILENT  // -s
    NORMAL  // -vn
    VERBOSE // -v
    CHATTY  // -vv
    DEBUG   // -vvv
}

operator <=> (v, w: Verbosity) {
    v as Int <=> w as Int
}

/**
 * Thrown when some setting is invalid
 */
ConfigurationError: class extends CompileError {

    init: func (.msg) {
        super(msg)
    }

}

