import qbs
import qbs.FileInfo
import qbs.TextFile


Project {
    name: "xdrpp"

    Product {
        name: "build_endian_header"
        type: "hpp"        

        Group {
            files: buildEndianFile
            fileTags: "endian_header"
        }

        Depends{name: "stellar_qbs_module"}

        readonly property path buildEndianFile: stellar_qbs_module.rootDirectory + "/lib/xdrpp" +"/xdrpp/build_endian.h.in"

        Rule {
            inputs: ["endian_header"]
            Artifact {
                filePath: "xdrpp/build_endian.h"
                fileTags: "hpp"
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

                    content = content.replace(/@IS_BIG_ENDIAN@/, "0")

                    file = new TextFile(output.filePath, TextFile.WriteOnly);
                    file.truncate();
                    file.write(content);
                    file.close();

                }
                return cmd;
            }
        }

        Export {
            Depends { name: "cpp" }
            cpp.windowsApiCharacterSet: "mbcs"
            cpp.includePaths: product.buildDirectory
        }
    }

    CppApplication {
        name: "xdrc"
        Depends {name: "stellar_qbs_module"}
        Depends {name: "build_endian_header"}
        readonly property path baseDirectory: stellar_qbs_module.rootDirectory + "/lib/xdrpp"
        readonly property path targetBinPath: destinationDirectory
        readonly property string cpreprocessor: "cpp"

        Properties {
            condition: qbs.targetOS.contains("windows")
            cpp.includePaths: [baseDirectory, baseDirectory+"/msvc_xdrpp/include"]
            cpp.windowsApiCharacterSet: "mbcs"
        }
        Properties {
            condition: qbs.targetOS.contains("unix")
            cpp.includePaths: [baseDirectory, destinationDirectory]
        }
        Properties {
            condition: qbs.targetOS.contains("darwin")
            targetBinPath: destinationDirectory + "/" + targetName + ".app/Contents/MacOS"
            cpreprocessor: "cc -xc -E -P"
        }

        Rule {
            multiplex: true
            condition: qbs.targetOS.contains("unix")
            Artifact {
                filePath: "xdrpp/config.h"
                fileTags: "hpp"
            }
            prepare: {
                var cmd = new JavaScriptCommand();
                cmd.description = "generating config.h";
                cmd.highlight = "codegen";
                cmd.sourceCode = function() {
                    var content = "\n#define CPP_COMMAND \""+product.cpreprocessor+"\" \n#define PACKAGE \"xdrpp\"\n#define PACKAGE_NAME \"xdrpp\"\n#define PACKAGE_VERSION \"0\"\n#define WORDS_BIGENDIAN 0\n",
                    file = new TextFile(output.filePath, TextFile.WriteOnly);
                    file.truncate();
                    file.write(content);
                    file.close();

                }
                return cmd;
            }
        }

        files: [baseDirectory+"/compat/getopt_long.c"]
        Group {
            name: "C++ Sources"
            prefix: baseDirectory + "/xdrc/"
            files: "*.cc"
        }

        Group {
            name: "Lex file"
            prefix: baseDirectory + "/xdrc/"
            files:[
                "scan.ll",
            ]
            fileTags: ["lex_file"]
        }

        Group {
            name: "Yacc file"
            prefix: baseDirectory + "/xdrc/"
            files:[
                "parse.yy",
            ]
            fileTags: ["yacc_file"]
        }

        Rule {
            inputs: "lex_file"
            Artifact {
                filePath: "scan.cc"
                fileTags: ["cpp"]
            }
            prepare: {
                var cmd = new Command("flex", [
                                          "--nounistd",
                                          "--outfile="+outputs.cpp[0].filePath,
                                          input.filePath
                                      ]);
                cmd.description = "running flex"
                return cmd
            }
        }

        Rule {
            inputs: "yacc_file"
            Artifact {
                filePath: "parse.cc"
                fileTags: ["cpp"]
            }
            Artifact {
                filePath: "parse.hh"
                fileTags: ["hpp"]
            }
            prepare: {
                var cmd = new Command("bison", [
                                          "--defines=" + outputs.hpp[0].filePath,
                                          "--output=" + outputs.cpp[0].filePath,
                                          input.filePath
                                      ]);
                cmd.description = "running bison"
                return cmd
            }
        }
    }

    StaticLibrary {
        name: "libxdrpp"

        Depends {name: "cpp"}
        Depends {name: "build_endian_header"}
        Depends{name: "stellar_qbs_module"}
        readonly property path baseDirectory: stellar_qbs_module.rootDirectory + "/lib/xdrpp"

        cpp.includePaths: [baseDirectory]
        cpp.windowsApiCharacterSet: "mbcs"

        Group {
            name: "C++ Sources"
            prefix: baseDirectory + "/xdrpp/"
            files: ["marshal.cc", "printer.cc"]
        }

        Export {
            Depends { name: "cpp" }
            Depends {name: "build_endian_header"}
            cpp.windowsApiCharacterSet: "mbcs"
            cpp.includePaths: [product.baseDirectory]
        }

    }
}
