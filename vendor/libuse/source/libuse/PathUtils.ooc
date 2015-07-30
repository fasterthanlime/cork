
import io/File

extend String {

    /**
     * For "path/to/some/file.something", return "path/to/some/file"
     */
    trimExt: func -> This {
        idx := lastIndexOf('.')
        if (idx == -1) {
            return this
        }
        this[0..-(size - idx + 1)]
    }

}

extend File {

    /**
     * Same as String trimExt, but operate on a File's path directly
     */
    trimExt: func -> String {
        path trimExt()
    }

}

