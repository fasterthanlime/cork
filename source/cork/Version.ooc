
/**
 * A simple semantic version with major, minor, and patch
 * being integers.
 */
Version: class {
    major, minor, patch: Int

    init: func (=major, =minor, =patch)

    toString: func -> String {
        "#{major}.#{minor}.#{patch}"
    }
}

