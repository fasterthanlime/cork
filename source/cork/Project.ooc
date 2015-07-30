
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

    id: String { get { useFile identifier } }

    init: func (=useFile) {
        if (useFile sourcePath) {
            if (useFile file) {
                sourceFolder = File new(useFile file getParent(), useFile sourcePath)
            } else {
                sourceFolder = File new(useFile sourcePath)
            }

            if (!sourceFolder exists?()) {
                "Source path #{useFile sourcePath} non-existent (from #{useFile identifier}.use)"
            }
        }
    }

    /**
     * Find a given file in our source path.
     */
    find: func (path: String, ext := "ooc") -> File {
        if (!sourceFolder) return null

        f := File new(sourceFolder, "#{path}.#{ext}")
        if (!f exists?()) return null
        f
    }

}

