
import os/Terminal

/** 
 * Can receive error messages. Implementations may format to a string or
 * directly write on a terminal.
 */
ErrorOutput: abstract class {
    /* colors */
    setColor: abstract func (color: Color)
    reset: abstract func

    /*  output */
    append: abstract func ~char (c: Char)
    append: abstract func ~string (s: String)
    append: func ~buffer (buffer: Buffer) {
        append(buffer toString())
    }
}

/**
 * Outputs an error to a buffer, without color support (for example when rock's
 * output is being redirected, or when it's used on a platform that doesn't support
 * ANSI escapes)
 */
TextErrorOutput: class extends ErrorOutput {
    buffer := Buffer new()

    init: func
    
    setColor: func (color: Color) {
        /* text output is not colored - setColor is a no-op */
    }

    reset: func {
        /* nothing to reset, no-op as well */
    }

    append: func ~char (c: Char) {
        buffer append(c)
    }
    
    append: func ~string (s: String) {
        buffer append(s)
    }

    append: func ~buffer (b: Buffer) {
        buffer append(b)
    }
    
    toString: func -> String {
        buffer toString()
    }
}

/**
 * Outputs an error to a terminal, with color support. Relies on os/Terminal to
 * do so.
 */
TerminalErrorOutput: class extends ErrorOutput {

    init: func
    
    setColor: func (color: Color) {
        Terminal setFgColor(color)
    }

    reset: func {
        Terminal reset()
    }

    append: func ~char (c: Char) {
        c print()
    }
    
    append: func ~string (s: String) {
        s print()
    }
}

