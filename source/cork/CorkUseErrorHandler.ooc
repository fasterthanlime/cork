
// third-party
import libuse/UseFileParser
import libtoken/Token

// ours
import Settings
import CompileError

/**
 * Error handler for libuse
 */
CorkUseErrorHandler: class extends UseErrorHandler {

    settings: Settings

    init: func (=settings)

    throw: func (t: Token, msg: String) {
        settings throw(CompileError new(t, msg))
    }

}

