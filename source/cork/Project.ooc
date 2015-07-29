
use libuse
import libuse/UseFile

import io/File

/**
 * An ooc project contains a bunch of .ooc files, usually a .use file
 * to describe its structure (but not necessarily)
 */
Project: class {

    sourcePath: File
    useFile: UseFile

    init: func (=useFile) {
        if (!useFile sourcePath) {
            "Use file #{useFile identifier} has no sourcePath." println()
            exit(1)
        }

        if (useFile file) {
            sourcePath = File new(useFile file getParent(), useFile sourcePath)
        } else {
            sourcePath = File new(useFile sourcePath)
        }
        if (!sourcePath exists?()) {
            "Source path #{useFile sourcePath} non-existent (from #{useFile identifier}.use)"
        }
    }

    /**
     * Find a given file in our source path.
     */
    find: func (path: String, ext: String) -> File {
        f := File new(sourcePath, "#{path}.#{ext}")
        "Attempting #{f}" println()
        if (!f exists?()) return null
        f
    }

}

