import qbs
import qbs.File
import qbs.FileInfo

StaticLibrary {
    name: "libsodium"

    Depends {name: "cpp"}
    Depends{name: "stellar_qbs_module"}
    readonly property path baseDirectory: stellar_qbs_module.rootDirectory + "/lib/libsodium"
    readonly property path srcDirectory: baseDirectory + "/src/libsodium"
    readonly property path versionHeaderFile: baseDirectory + "/builds/msvc/version.h"

    cpp.windowsApiCharacterSet: "mbcs"
    cpp.includePaths: [srcDirectory + "/include/sodium", destinationDirectory + "/sodium"]

    Group {
        files: versionHeaderFile
        fileTags: "version_header"
    }

    Rule {
        inputs: ["version_header"]
        Artifact {
            filePath: "sodium/version.h"
            fileTags: "hpp"
        }
        prepare: {
            var cmd = new JavaScriptCommand();
            cmd.description = "Copying '" + input.fileName + "' to '" + FileInfo.path(output.filePath) + "'";
            cmd.highlight = "codegen";
            cmd.sourceCode = function() {
                File.copy(input.filePath, output.filePath)
            }
            return cmd;
        }
    }

    Group {
        name: "C++ Sources"
        prefix: srcDirectory + "/"
        files: "**/*.c"
    }

    Export {
        Depends { name: "cpp" }
        cpp.windowsApiCharacterSet: "mbcs"
        cpp.includePaths: [product.destinationDirectory, product.srcDirectory + "/include", product.srcDirectory + "/include/sodium"]
    }
}
