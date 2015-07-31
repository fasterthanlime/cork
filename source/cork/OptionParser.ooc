
// third-party
import libuse/[UseFile, UseFileParser, PathUtils]

// ours
import Settings
import Project
import CompileError

// sdk
import structs/ArrayList
import io/File

/**
 * Goes through each command line option, validates them,
 * parses them as needed.
 */
OptionParser: class {

    settings: Settings
    useFileParser: UseFileParser

    init: func (=settings) {
        useFileParser = UseFileParser new()
        useFileParser libDirs addAll(settings oocLibDirs)
    }
    
    /**
     * Actually parse arguments, fill Settings with it
     */
    parse: func (args: ArrayList<String>) {
        // get rid of $0, it's the path to our binary.
        args removeAt(0)

        while (!args empty?()) {
            arg := args removeAt(0)

            match {
                case arg startsWith?("+") =>
                    settings cArgs add(arg[1..-1])

                case arg startsWith?("--") =>
                    "Unknown arg: #{arg}" println()

                case arg startsWith?("-") =>
                    "Unknown arg: #{arg}" println()

                case =>
                    addMain(arg)
            }

        }
    }

    addMain: func (arg: String) {
        if (settings main) {
            err("Can only compile one file - extra file is #{arg}")
        }

        larg := arg toLower()
        useFile: UseFile

        match {
            case larg endsWith?(".use") =>
                useFile = useFileParser parse(File new(arg))

            case =>
                if (!larg endsWith?(".ooc")) {
                    arg += ".ooc"
                }

                oocFile := File new(arg)
                if (!oocFile exists?()) {
                    err("Compilation arg not found: #{oocFile path}")
                }

                name := oocFile name trimExt()

                useFile = UseFile new()
                useFile identifier = "<cork-main>"
                useFile binaryPath = name
                useFile sourcePath = oocFile parent path
                useFile main = name
        }

        if (useFile) {
            settings main = Project new(useFile)
        } else {
            err("Don't know how to compile file: #{arg}")
        }
    }

    err: func (msg: String) {
        settings throw(CompileError new(msg))
    }

}

