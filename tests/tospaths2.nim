import pathX/[base, lowlevel, ospaths2]

type
  LinuxAbsoFile = PathX[fdFile, arAbso, osLinux, true]
  LinuxAbsoDire = PathX[fdDire, arAbso, osLinux, true]
  LinuxRelaFile = PathX[fdFile, arRela, osLinux, true]
  LinuxRelaDire = PathX[fdDire, arRela, osLinux, true]

  WinAbsoFile = PathX[fdFile, arAbso, osWindows, true]
  WinAbsoDire = PathX[fdDire, arAbso, osWindows, true]
  WinRelaFile = PathX[fdFile, arRela, osWindows, true]
  WinRelaDire = PathX[fdDire, arRela, osWindows, true]

block: # normalizePathEnd
  # handle edge cases correctly: shouldn't affect whether path is
  # absolute/relative
  doAssert $(LinuxRelaDire"".normalizePathEnd(true)) == ""
  doAssert $(LinuxRelaDire"".normalizePathEnd(false)) == ""
  doAssert $(LinuxAbsoDire"/".normalizePathEnd(true)) == "/"
  doAssert $(LinuxAbsoDire"/".normalizePathEnd(false)) == "/"

  doAssert $(LinuxAbsoDire"//".normalizePathEnd(false)) == "/"
  doAssert $(LinuxRelaDire"foo.bar//".normalizePathEnd) == "foo.bar"
  doAssert $(LinuxRelaDire"bar//".normalizePathEnd(trailingSep = true)) == "bar/"

  doAssert $(WinAbsoDire"C:\foo\\".normalizePathEnd) == r"C:\foo"
  doAssert $(WinAbsoFile"C:\foo".normalizePathEnd(trailingSep = true)) == r"C:\foo\"
  # this one is controversial: we could argue for returning `D:\` instead,
  # but this is simplest.
  doAssert $(WinAbsoDire"D:\".normalizePathEnd) == r"D:"
  doAssert $(WinAbsoDire"E:/".normalizePathEnd(trailingSep = true)) == r"E:\"
  doAssert $(WinAbsoDire"/".normalizePathEnd) == r"\"

block: # joinPath
  doAssert joinPath(LinuxRelaDire"usr", LinuxRelaDire"").exactEq LinuxRelaDire"usr"
  doAssert joinPath(LinuxRelaDire"", LinuxRelaDire"lib").exactEq LinuxRelaDire"lib"
  #doAssert joinPath("", "/lib") == unixToNativePath"/lib"
  #doAssert joinPath("usr/", "/lib").exactEq unixToNativePath"usr/lib"
  doAssert joinPath(LinuxRelaDire"", LinuxRelaDire"").exactEq LinuxRelaDire"" # issue #13455
  #doAssert joinPath("", "/") == unixToNativePath"/"
  #doAssert joinPath("/", "/") == unixToNativePath"/"
  doAssert joinPath(LinuxAbsoDire"/", LinuxRelaDire"").exactEq LinuxAbsoDire"/"
  #doAssert joinPath("/" / "") == unixToNativePath"/" # weird test case...
  #doAssert joinPath("/", "/a/b/c") == unixToNativePath"/a/b/c"
  doAssert joinPath(LinuxRelaDire"foo/", LinuxRelaDire"").exactEq LinuxRelaDire"foo/"
  doAssert joinPath(LinuxRelaDire"foo/", LinuxRelaFile"abc").exactEq LinuxRelaFile"foo/abc"
  doAssert joinPath(LinuxRelaDire"foo//./", LinuxRelaDire"abc/.//").exactEq LinuxRelaDire"foo/abc/"
  doAssert joinPath(LinuxRelaDire"foo", LinuxRelaDire"abc").exactEq LinuxRelaDire"foo/abc"
  doAssert joinPath(LinuxRelaDire"", LinuxRelaFile"abc").exactEq LinuxRelaFile"abc"

  doAssert joinPath(LinuxRelaDire"zook/.", LinuxRelaDire"abc").exactEq LinuxRelaDire"zook/abc"

  # controversial: inconsistent with `joinPath("zook/.","abc")`
  # on linux, `./foo` and `foo` are treated a bit differently for executables
  # but not `./foo/bar` and `foo/bar`
  #doAssert joinPath(".", "/lib") == unixToNativePath"./lib"
  doAssert joinPath(LinuxRelaDire".", LinuxRelaDire"abc").exactEq LinuxRelaDire"./abc"

  # cases related to issue #13455
  #doAssert joinPath("foo", "", "") == "foo"
  doAssert joinPath(LinuxRelaDire"foo", LinuxRelaDire"").exactEq LinuxRelaDire"foo"
  doAssert joinPath(LinuxRelaDire"foo/", LinuxRelaDire"").exactEq LinuxRelaDire"foo/"
  doAssert joinPath(LinuxRelaDire"foo/", LinuxRelaDire".").exactEq LinuxRelaDire"foo"
  doAssert joinPath(LinuxRelaDire"foo", LinuxRelaDire"./").exactEq LinuxRelaDire"foo/"
  #doAssert joinPath("foo", "", "bar/") == unixToNativePath"foo/bar/"

  # issue #13579
  doAssert joinPath(LinuxAbsoDire"/foo", LinuxRelaFile"../a").exactEq LinuxAbsoFile"/a"
  doAssert joinPath(LinuxAbsoDire"/foo/", LinuxRelaFile"../a").exactEq LinuxAbsoFile"/a"
  doAssert joinPath(LinuxAbsoDire"/foo/.", LinuxRelaFile"../a").exactEq LinuxAbsoFile"/a"
  doAssert joinPath(LinuxAbsoDire"/foo/.b", LinuxRelaFile"../a").exactEq LinuxAbsoFile"/foo/a"
  doAssert joinPath(LinuxAbsoDire"/foo///", LinuxRelaDire"..//a/").exactEq LinuxAbsoDire"/a/"
  doAssert joinPath(LinuxRelaDire"foo/", LinuxRelaFile"../a").exactEq LinuxRelaFile"a"

  doAssert joinPath(WinAbsoDire"C:\\Program Files (x86)\\Microsoft Visual Studio 14.0\\Common7\\Tools\\", WinRelaFile"..\\..\\VC\\vcvarsall.bat").exactEq WinAbsoFile"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
  doAssert joinPath(WinAbsoDire"C:\foo", WinRelaFile"..\a").exactEq WinAbsoFile"C:\a"
  doAssert joinPath(WinAbsoDire"C:\foo\", WinRelaFile"..\a").exactEq WinAbsoFile"C:\a"
  doAssert joinPath(WinAbsoDire"\\○△\a", WinRelaDire"□\..\◇").exactEq WinAbsoDire"\\○△\a\◇"

block: # parentDir
  doAssert parentDir(LinuxAbsoDire"/").exactEq LinuxAbsoDire"/"
  doAssert parentDir(LinuxAbsoDire"/a").exactEq LinuxAbsoDire"/"
  doAssert parentDir(LinuxAbsoDire"/aa").exactEq LinuxAbsoDire"/"
  doAssert parentDir(LinuxAbsoDire"/a/b").exactEq LinuxAbsoDire"/a"
  doAssert parentDir(LinuxRelaFile"a/b").exactEq LinuxRelaDire"a"
  doAssert parentDir(LinuxRelaFile"a/bb").exactEq LinuxRelaDire"a"
  doAssert parentDir(LinuxRelaFile"aa/bb").exactEq LinuxRelaDire"aa"
  doAssert parentDir(LinuxRelaFile"").exactEq LinuxRelaDire".."
  doAssert parentDir(LinuxRelaFile".").exactEq LinuxRelaDire".."
  doAssert parentDir(LinuxRelaFile"a/../b").exactEq LinuxRelaDire"."
  doAssert parentDir(LinuxRelaFile"../a").exactEq LinuxRelaDire".."
  doAssert parentDir(LinuxRelaFile"../../a").exactEq LinuxRelaDire"../.."
  doAssert parentDir(WinAbsoDire"\\?\c:").exactEq WinAbsoDire"\\?\c:"
  doAssert parentDir(WinAbsoDire"//?/c:/Users").exactEq WinAbsoDire"\\?\c:"
  doAssert parentDir(WinAbsoDire"\\localhost\c$").exactEq WinAbsoDire"\\localhost\c$"
  doAssert parentDir(WinAbsoDire"\Users").exactEq WinAbsoDire"\"
  doAssert parentDir(WinRelaDire"").exactEq WinRelaDire".."
  doAssert parentDir(WinRelaDire".").exactEq WinRelaDire".."
  doAssert parentDir(WinRelaDire".\").exactEq WinRelaDire".."
  doAssert parentDir(WinRelaDire"a").exactEq WinRelaDire"."
  doAssert parentDir(WinRelaDire"a\b").exactEq WinRelaDire"a"
  doAssert parentDir(WinRelaDire"a/b").exactEq WinRelaDire"a"
  doAssert parentDir(WinRelaDire"a\b\\").exactEq WinRelaDire"a"
  doAssert parentDir(WinRelaDire"a\b\c").exactEq WinRelaDire"a\b"
