
use cork
import Settings, Compiler

import Version
VERSION := Version new(0, 1, 0)

import structs/ArrayList

/**
 * Main entry point into cork
 */
main: func (args: ArrayList<String>) -> Int {
    "cork v#{VERSION}" println()

    settings := Settings new()
    compiler := Compiler new(settings)
    for ((i, arg) in args) {
        if (i == 0) continue
        compiler addUnit(arg)
    }
    compiler run()

    0
}

