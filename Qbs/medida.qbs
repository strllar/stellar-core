import qbs

StaticLibrary {
    name: "libmedida"

    Depends {name: "cpp"}
    Depends{name: "stellar_qbs_module"}
    readonly property path baseDirectory: stellar_qbs_module.rootDirectory + "/lib/libmedida"
    readonly property path srcDirectory: baseDirectory + "/src"

    cpp.windowsApiCharacterSet: "mbcs"
    cpp.includePaths: [srcDirectory]

    Group {
        name: "C++ Sources"
        prefix: srcDirectory + "/medida/"
        files: "**/*.cc"
    }

    Export {
        Depends { name: "cpp" }
        cpp.windowsApiCharacterSet: "mbcs"
        cpp.includePaths: [product.srcDirectory]
    }
}
