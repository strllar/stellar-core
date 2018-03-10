import qbs
import qbs.FileInfo

Project {

    Product {
        name: "generated-xdr-header"
        type: "hpp"
        Depends {name: "xdrc"}
        Depends {name: "stellar_qbs_module"}
        Group {
            name: "XDR files"
            prefix: stellar_qbs_module.srcDirectory + "/xdr/"
            files: "*.x"
            fileTags: "xdr-file"
        }

        Export {
            Depends { name: "cpp" }
            cpp.windowsApiCharacterSet: "mbcs"
            cpp.includePaths: product.buildDirectory
        }

        Rule {
            inputs: "xdr-file"
            Artifact {
                filePath: "xdr/"+input.fileName.replace(/\.x$/, ".h")
                fileTags: ["hpp"]
            }
            prepare: {
                var xdrc;
                for (var i in product.dependencies) {
                    var dep = product.dependencies[i];
                    if (dep.name != "xdrc")
                        continue;
                    xdrc = dep.buildDirectory + "/" + dep.targetName;
                }
                var cmd = new Command(xdrc, ["-hh", "-o", output.filePath, input.filePath])
                cmd.description = "xdrc " + input.filePath
                return cmd
            }
        }
    }

    CppApplication  {
        name: "stellar-core"
        Depends {name: "stellar_qbs_module"}
        Depends {name: "generated-xdr-header"}
        Depends {name: "libxdrpp"}
        Depends {name: "libmedida"}
        Depends {name: "libsoci"}
        Depends {name: "libsoci-sqlite3"}
        Depends {name: "libsodium"}

        cpp.includePaths: [
            stellar_qbs_module.srcDirectory,
            stellar_qbs_module.rootDirectory,
            stellar_qbs_module.rootDirectory + "/lib",
            stellar_qbs_module.rootDirectory + "/Builds/VisualStudio/src/generated",
            stellar_qbs_module.rootDirectory + "/lib/autocheck/include",
            stellar_qbs_module.rootDirectory + "/lib/cereal/include",
            stellar_qbs_module.rootDirectory + "/lib/asio/include",
        ]
        Properties {
            condition: qbs.targetOS.contains("windows")
            cpp.windowsApiCharacterSet: "mbcs"
            cpp.defines: [
                "NOMINMAX",
                "ASIO_STANDALONE",
                "ASIO_HAS_THREADS",
                //"USE_POSTGRES",
                "_WINSOCK_DEPRECATED_NO_WARNINGS",
                "SODIUM_STATIC",
                "ASIO_SEPARATE_COMPILATION",
                "ASIO_ERROR_CATEGORY_NOEXCEPT=noexcept",
                "_CRT_SECURE_NO_WARNINGS",
                "_WIN32_WINNT=0x0501",
                "WIN32",
            ]
            cpp.dynamicLibraries:  ["ws2_32", "Psapi", "Mswsock"]
        }
        Properties {
            condition: qbs.targetOS.contains("unix")
            cpp.defines: [
                "NOMINMAX",
                "ASIO_STANDALONE",
                "ASIO_HAS_THREADS",
                //"USE_POSTGRES",
                "SODIUM_STATIC",
                "ASIO_SEPARATE_COMPILATION",
                "ASIO_ERROR_CATEGORY_NOEXCEPT=noexcept",
            ]
            cpp.dynamicLibraries:  ["dl", "pthread"]
        }

        Group {
            name: "3rd-party C++ Sources"
            prefix: stellar_qbs_module.rootDirectory + "/lib"
            files:[
                "/asio/src/asio.cpp",
                "/json/jsoncpp.cpp",
                "/http/*.cpp",
                "/util/*.c*"            ]
        }

        Group {
            name: "C++ Sources"
            prefix: stellar_qbs_module.srcDirectory
            files:[
                "/**/*.cpp"
            ]
        }
    }

    references: [
        "xdrpp.qbs",
        "medida.qbs",
        "soci.qbs",
        "sodium.qbs"
    ]
}
