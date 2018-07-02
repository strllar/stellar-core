import qbs
import qbs.FileInfo
import qbs.TextFile

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
        Depends {name: "libsoci_sqlite3"}
        Depends {name: "libsoci_pgsql"; required: false}
        Depends {name: "libsodium"}

        stellar_qbs_module.usePostgres: true
        property stringList moredefs: []

        property var x: {
            console.warn("stellar-core : found libpq : "+ libsoci_pgsql.present)
            console.warn("stellar-core : defines : "+ cpp.defines)
        }

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
            condition: libsoci_pgsql.present
            moredefs: ["USE_POSTGRES"]
        }

        Properties {
            condition: qbs.targetOS.contains("windows")
            cpp.windowsApiCharacterSet: "mbcs"
            cpp.defines: [
                "NOMINMAX",
                "ASIO_STANDALONE",
                "ASIO_HAS_THREADS",
                "_WINSOCK_DEPRECATED_NO_WARNINGS",
                "SODIUM_STATIC",
                "ASIO_SEPARATE_COMPILATION",
                "ASIO_ERROR_CATEGORY_NOEXCEPT=noexcept",
                "_CRT_SECURE_NO_WARNINGS",
                "_WIN32_WINNT=0x0501",
                "WIN32",
            ].concat(moredefs)
            cpp.dynamicLibraries:  ["ws2_32", "Psapi", "Mswsock"]
        }
        Properties {
            condition: qbs.targetOS.contains("unix")
            cpp.defines: [
                "NOMINMAX",
                "ASIO_STANDALONE",
                "ASIO_HAS_THREADS",
                "SODIUM_STATIC",
                "ASIO_SEPARATE_COMPILATION",
                "ASIO_ERROR_CATEGORY_NOEXCEPT=noexcept",
            ].concat(moredefs)
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

        Group {
            files: stellarCoreVersion
            fileTags: "corever_template"
        }

        readonly property path stellarCoreVersion: stellar_qbs_module.rootDirectory + "/src/main" +"/StellarCoreVersion.cpp.in"

        Rule {
            inputs: ["corever_template"]
            Artifact {
                filePath: "src/main/StellarCoreVersion.cpp"
                fileTags: "cpp"
            }
            prepare: {
                var cmd = new JavaScriptCommand();
                cmd.description = "generating build_endian.h";
                cmd.highlight = "codegen";
                cmd.onWindows = (product.moduleProperty("qbs", "targetOS").contains("windows"));
                cmd.sourceCode = function() {
                    var file = new TextFile(input.filePath);
                    var content = file.readAll();
                    // replace quoted quotes
                    content = content.replace(/\\\"/g, '"');
                    // replace Windows line endings
                    if (onWindows)
                        content = content.replace(/\r\n/g, "\n");

                    content = content.replace(/%%VERSION%%/, "sp-9.2.0")

                    file = new TextFile(output.filePath, TextFile.WriteOnly);
                    file.truncate();
                    file.write(content);
                    file.close();

                }
                return cmd;
            }
        }
    }

    references: [
        "xdrpp.qbs",
        "medida.qbs",
        "soci.qbs",
        "sodium.qbs"
    ]
}
