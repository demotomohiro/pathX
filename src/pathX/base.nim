import "$nim"/compiler/platform
export platform.TSystemOS

type
  FileOrDire* = enum ## Specify if it is a path to file or directory.
    fdUnknown
    fdFile
    fdDire

  AbsoOrRela* = enum ## Specify if the path is absolute or relative.
    arUnknown
    arAbso
    arRela

  PathX*[FoD: static[FileOrDire]; AoR: static[AbsoOrRela]; EOS: static[TSystemOS]; DoesFollowLink: static[bool]] = distinct string
    ## Generic type repesents a path.

const
  buildOSName {.magic: "BuildOS".}: string = ""

  BuildOS* = nameToOS(buildOSName)
    ## `TSystemOS` enum value correspondings to the OS that compiler is running.
    ## You can use this value to the `EOS` generic parameter of `PathX`.

  HostOS* = nameToOS(hostOS)
    ## `TSystemOS` enum value correspondings to the OS that program runs.
    ## You can use this value to the `EOS` generic parameter of `PathX`.

  DosLikeFileSystem* = {osDos, osWindows, osOs2}
    ## OSs that handle paths in MS DOS/Windows way.

func `$`*(x: PathX): string = x.string
func len*(x: PathX): int {.borrow.}

func isDosLikeFileSystem*(t: typedesc[PathX]): bool =
  t.EOS in DosLikeFileSystem

func isDosLikeFileSystem*(x: PathX): bool =
  typeof(x).isDosLikeFileSystem

when isMainModule:
  let
    p0 = PathX[fdFile, arAbso, osLinux, true]("/tmp")
  doAssert $p0 == "/tmp"
  doAssert p0.len == 4

  let q0 = PathX[fdDire, arRela, BuildOS, true]("aa")
  doAssert $q0 == "aa"
