import pathX/[base, lowlevel, pathnorm]

iterator dirs(x: PathX): (int, int) =
  var it = default PathIter
  while hasNext(it, x): yield next(it, x)

proc toSeq(x: PathX): seq[string] =
  for b in x.dirs:
    result.add x.string[b[0] .. b[1]]

doAssert PathX[fdFile, arRela, osLinux, true]("").toSeq == @[]
doAssert PathX[fdFile, arAbso, osLinux, true]("/").toSeq == @["/"]
doAssert PathX[fdFile, arAbso, osLinux, true]("//").toSeq == @["/"]
doAssert PathX[fdFile, arAbso, osLinux, true]("///").toSeq == @["/"]
doAssert PathX[fdFile, arAbso, osLinux, true]("/foo").toSeq == @["/", "foo"]
doAssert PathX[fdFile, arAbso, osLinux, true]("/foo/bar").toSeq == @["/", "foo", "bar"]
doAssert PathX[fdFile, arAbso, osLinux, true]("//foo//bar").toSeq == @["/", "foo", "bar"]
doAssert PathX[fdFile, arAbso, osLinux, true]("//foo//bar//").toSeq == @["/", "foo", "bar"]
doAssert PathX[fdFile, arRela, osLinux, true]("a").toSeq == @["a"]
doAssert PathX[fdFile, arRela, osLinux, true]("ab").toSeq == @["ab"]
doAssert PathX[fdFile, arRela, osLinux, true]("ab/").toSeq == @["ab"]
doAssert PathX[fdFile, arRela, osLinux, true]("ab//").toSeq == @["ab"]
doAssert PathX[fdFile, arRela, osLinux, true]("ab/a").toSeq == @["ab", "a"]
doAssert PathX[fdFile, arRela, osLinux, true]("ab//a").toSeq == @["ab", "a"]
doAssert PathX[fdFile, arRela, osLinux, true]("ab/a/").toSeq == @["ab", "a"]
doAssert PathX[fdFile, arRela, osLinux, true]("ab/a//").toSeq == @["ab", "a"]
doAssert PathX[fdFile, arRela, osLinux, true]("a/b/c").toSeq == @["a", "b", "c"]
doAssert PathX[fdFile, arAbso, osWindows, true]("").toSeq == @[]
doAssert PathX[fdFile, arAbso, osWindows, true]("a:\\").toSeq == @["a:"]
doAssert PathX[fdFile, arAbso, osWindows, true]("a:\\b").toSeq == @["a:", "b"]
doAssert PathX[fdFile, arAbso, osWindows, true]("a:\\bar\\c").toSeq == @["a:", "bar", "c"]

type
  WinAbsoPath = PathX[fdFile, arAbso, osWindows, true]
  WinRelaPath = PathX[fdFile, arRela, osWindows, true]

template initVars =
  var state {.inject.} = 0
  var result {.inject.}: WinAbsoPath

block: # / -> /
  initVars
  addNormalizePath(WinAbsoPath "//?/c:/./foo//bar/../baz", result, state, '/')
  doAssert $result == "//?/c:/foo/baz"
  addNormalizePath(WinRelaPath "me", result, state, '/')
  doAssert $result == "//?/c:/foo/baz/me"

block: # / -> \
  initVars
  addNormalizePath(WinAbsoPath r"//?/c:/./foo//bar/../baz", result, state)
  doAssert $result == r"\\?\c:\foo\baz"
  addNormalizePath(WinRelaPath "me", result, state)
  doAssert $result == r"\\?\c:\foo\baz\me"

block: # Append path component to UNC drive
  initVars
  addNormalizePath(WinAbsoPath r"//?/c:", result, state)
  doAssert $result == r"\\?\c:"
  addNormalizePath(WinRelaPath "Users", result, state)
  doAssert $result == r"\\?\c:\Users"
  addNormalizePath(WinRelaPath "me", result, state)
  doAssert $result == r"\\?\c:\Users\me"
