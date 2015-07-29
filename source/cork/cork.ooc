
use cork
import Settings, OptionParser, Compiler

import Version
VERSION := Version new(0, 1, 0)

import structs/ArrayList

/**
 * Main entry point into cork
 */
main: func (args: ArrayList<String>) -> Int {
    "cork v#{VERSION}" println()

    settings := Settings new()
    optParser := OptionParser new(settings)
    optParser parse(args)

    compiler := Compiler new(settings)
    compiler run()

    0
}

