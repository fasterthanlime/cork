
// third-party
import libtoken/[Token, ErrorOutput]

/**
 * The level of an error. Could just be an information,
 * or a warning, or an error.
 */
ErrorLevel: enum {
    INFO
    WARNING
    ERROR

    toString: func -> String {
        match this {
            case INFO => "info"
            case WARNING => "warning"
            case ERROR => "error"
            case => "<unknown level>"
        }
    }
}

/**
 * A compilation error that can occur anytime in cork — from invalid
 * settings, to modules not found, to invalid ooc code, to problems
 * in the backends, ALL the things.
 */
CompileError: class {

    token: Token
    msg: String
    level := ErrorLevel ERROR

    init: func (=token, =msg)

    init: func ~noToken (=msg) {
        token = nullToken
    }

}

