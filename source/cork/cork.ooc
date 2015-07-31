
// third-party
// rock requires a `use` directive in an .ooc file even when they're in the
// `Requires` clause. It's a bit wonky but this'll allow cork to be compiled by
// rock AND self-hosting later.
use nagaqueen
use libuse
use libtoken
use libovum

// ours
use cork
import Settings, OptionParser, Compiler, CompileError
import Version

// sdk
import structs/ArrayList

VERSION := Version new(0, 1, 0)

/**
 * Main entry point into cork
 */
main: func (args: ArrayList<String>) -> Int {
    "cork v#{VERSION}" println()

    try {
        settings := Settings new()
        optParser := OptionParser new(settings)
        optParser parse(args)

        compiler := Compiler new(settings)
        compiler run()
    } catch (e: CompilationFailed) {
        return 1
    }

    0
}

