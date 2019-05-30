import qbs

Project {
    name: "soci"

    StaticLibrary {
        name: "sqlite3"
        Depends {name: "cpp"}
        Depends{name: "stellar_qbs_module"}
        readonly property path baseDirectory: stellar_qbs_module.rootDirectory + "/lib/sqlite"

        cpp.windowsApiCharacterSet: "mbcs"

        files: [baseDirectory+"/*.c"]
        Export {
            Depends {name: "cpp"}
            cpp.windowsApiCharacterSet: "mbcs"
            cpp.includePaths: [product.baseDirectory]
        }
    }

    StaticLibrary {
        name: "libsoci_sqlite3"
        Depends{name: "cpp"}
        Depends{name: "stellar_qbs_module"}
        Depends{name: "sqlite3"}
        Depends{name: "libsoci"}
        readonly property path baseDirectory: stellar_qbs_module.rootDirectory + "/lib/soci"
        readonly property path srcDirectory: baseDirectory + "/src/backends/sqlite3"

        cpp.windowsApiCharacterSet: "mbcs"

        Group {
            name: "C++ Sources"
            prefix: srcDirectory + "/"
            files: "*.cpp"
        }
    }

    StaticLibrary {
        name: "libsoci_pgsql"
        Depends{name: "cpp"}
        Depends{name: "stellar_qbs_module"}
        Depends{name: "libsoci"}
        readonly property path baseDirectory: stellar_qbs_module.rootDirectory + "/lib/soci"
        readonly property path srcDirectory: baseDirectory + "/src/backends/postgresql"
        property bool condition: stellar_qbs_module.usePostgres && stellar_qbs_module.libpq.found

        property var x: {
            console.warn("libsoci-pgsql: found libpq :"+stellar_qbs_module.libpq.found)
        }

        cpp.windowsApiCharacterSet: "mbcs"

        Group {
            name: "C++ Sources"
            prefix: srcDirectory + "/"
            files: "*.cpp"
        }
    }

    StaticLibrary {
        name: "libsoci"

        Depends {name: "cpp"}
        Depends{name: "stellar_qbs_module"}
        readonly property path baseDirectory: stellar_qbs_module.rootDirectory + "/lib/soci"
        readonly property path srcDirectory: baseDirectory + "/src/core"

        cpp.includePaths: [srcDirectory]
        cpp.windowsApiCharacterSet: "mbcs"

        Group {
            name: "C++ Sources"
            prefix: srcDirectory + "/"
            files: [
                "backend-loader.cpp",
                "blob.cpp",
                "connection-parameters.cpp",
                "connection-pool.cpp",
                "error.cpp",
                "into-type.cpp",
                "once-temp-type.cpp",
                "prepare-temp-type.cpp",
                "procedure.cpp",
                "ref-counted-prepare-info.cpp",
                "ref-counted-statement.cpp",
                "row.cpp",
                "rowid.cpp",
                "session.cpp",
                "soci-simple.cpp",
                "statement.cpp",
                "transaction.cpp",
                "use-type.cpp",
                "values.cpp"
            ]
        }

        Export {
            Depends { name: "cpp" }
            cpp.windowsApiCharacterSet: "mbcs"
            cpp.includePaths: [product.srcDirectory]
        }
    }
}
