
use libuse
import libuse/UseFile

import io/File

/**
 * An ooc project contains a bunch of .ooc files, usually a .use file
 * to describe its structure (but not necessarily)
 */
Project: class {

    sourceFolder: File
    useFile: UseFile

    init: func (=useFile) {
        if (!useFile sourcePath) {
            "Use file #{useFile identifier} has no sourcePath." println()
            exit(1)
        }

        if (useFile file) {
            sourceFolder = File new(useFile file getParent(), useFile sourcePath)
        } else {
            sourceFolder = File new(useFile sourcePath)
        }

        if (!sourceFolder exists?()) {
            "Source path #{useFile sourcePath} non-existent (from #{useFile identifier}.use)"
        }
    }

    /**
     * Find a given file in our source path.
     */
    find: func (path: String, ext := "ooc") -> File {
        f := File new(sourceFolder, "#{path}.#{ext}")
        "Attempting #{f}" println()
        if (!f exists?()) return null
        f
    }

}

