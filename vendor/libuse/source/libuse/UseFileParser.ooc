
// sdk
import io/[File, FileReader]
import structs/[ArrayList, HashMap]

// ours
import UseFile

UseFileParser: class {

    cache := HashMap<String, UseFile> new()
    libDirs := ArrayList<File> new()

    init: func
    
    parse: func (file: File) -> UseFile {
        if (!file exists?()) {
            ".use file not found: #{file path}" println()
            exit(1)
        }

        useFile := UseFile new()
        useFile file = file

        "Reading use file #{file}" println()

        fR := FileReader new(file)
        while (fR hasNext?()) {
            line := fR readLine()
            "line: #{line}" println()
        }

        useFile
    }

    findUse: func (identifier: String) -> File {
        fileName := "#{identifier}.use"

        for(dir in libDirs) {
            if(dir path == null) continue
            res := dir findShallow(fileName, 2)
            if (res) return res
        }

        null
    }

}

