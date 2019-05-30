import qbs
import qbs.FileInfo
import qbs.Probes

Module {
    readonly property var rootDirectory: FileInfo.path(project.sourceDirectory)
    readonly property var srcDirectory: rootDirectory + "/src"
    readonly property var libpq : libpqProbe
    property bool usePostgres : false

    Depends {name: "cpp"}
    cpp.cxxLanguageVersion: "c++14"
    cpp.windowsApiCharacterSet: "mbcs" //no effect, product depends on this module should explicitly set this

    Probes.PkgConfigProbe {
        id: libpqProbe
        //TODO: homebrew in macos
        //executable: 'PKG_CONFIG_PATH=/usr/local/opt/libpq/lib/pkgconfig pkg-config'
        executable: '/usr/local/bin/pkg-config'
        name: "libpq"
    }

    Probe {
        id: DebugProbe
        configure: {
            console.warn("DebugProbe:"+libpqProbe.found)
        }
    }

    Properties {
        condition: usePostgres && libpqProbe.found
        cpp.cFlags: libpqProbe.cflags
        cpp.cxxFlags: libpqProbe.cflags
        cpp.dynamicLibraries: libpqProbe.libraries
        cpp.libraryPaths: libpqProbe.libraryPaths
        cpp.linkerFlags: libpqProbe.linkerflags
    }
}
