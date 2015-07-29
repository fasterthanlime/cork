
import Project

import structs/ArrayList
import os/Env
import io/File
import text/StringTokenizer

/**
 * Compiler settings - library paths, verbosity level, you name it.
 */
Settings: class {

    main: Project

    oocLibDirs := ArrayList<String> new()
    cArgs := ArrayList<String> new()

    verbosity := Verbosity NORMAL

    init: func {
        readOocLibs()
    }

    readOocLibs: func {
        oocLibs := Env get("OOC_LIBS")
        if (!oocLibs) {
            err("$OOC_LIBS environment variable not set, bailing out")
        }

        oocLibDirs addAll(oocLibs split(File pathDelimiter))
    }

    err: func (msg: String) {
        msg println()
        exit(1)
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

