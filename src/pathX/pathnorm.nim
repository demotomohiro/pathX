# Based on lib/pure/pathnorm.nim in Nim standard library.

import base, lowlevel
import "$nim"/compiler/platform
import std/private/ntpath
import std/[assertions]

type
  PathIter* = object
    i, prev: int
    notFirst: bool

proc hasNext*(it: PathIter; x: PathX): bool =
  it.i < x.len

proc next*(it: var PathIter; x: PathX): (int, int) =
  it.prev = it.i
  if not it.notFirst and x.isDireSepa(it.i):
    # absolute path:
    inc it.i
  else:
    while it.i < x.len and (not x.isDireSepa(it.i)): inc it.i
  if it.i > it.prev:
    result = (it.prev, it.i-1)
  elif hasNext(it, x):
    result = next(it, x)
  # skip all separators:
  while it.i < x.len and x.isDireSepa(it.i): inc it.i
  it.notFirst = true

proc addNormalizePath*[T: PathX; U: PathX](x: T; result: var U; state: var int;
    direSepa: char) =
  ## Low level proc. Undocumented.

  assert x.isDireSepa(direSepa)

  let x = when x.EOS in DosLikeFileSystem: # Add Windows drive at start without normalization
      if result.isEmpty:
        let (drive, file) = splitDrive(x.string)
        var x = typeof(x)(file)
        result.add typeof(result)(drive)
        for i in 0 ..< result.len:
          if result.isDireSepa(i):
            result[i] = direSepa
        x
      else:
        x
    else:
      x

  # state: 0th bit set if isAbsolute path. Other bits count
  # the number of path components.
  var it: PathIter
  it.notFirst = (state shr 1) > 0
  if it.notFirst:
    while it.i < x.len and x.isDireSepa(it.i): inc it.i
  while hasNext(it, x):
    let b = next(it, x)
    if (state shr 1 == 0) and b[0] == b[1] and x.isDireSepa(b[0]):
      if result.len == 0 or not result.isDireSepa(^1):
        result.add direSepa
      state = state or 1
    elif b[1] == b[0] + 1 and x.isPareDire(b[0]):
      if (state shr 1) >= 1:
        var d = result.len
        # f/..
        # We could handle stripping trailing sep here: foo// => foo like this:
        # while (d-1) > (state and 1) and result[d-1] in {DirSep, AltSep}: dec d
        # but right now we instead handle it inside os.joinPath

        # strip path component: foo/bar => foo
        while (d-1) > (state and 1) and not result.isDireSepa(d - 1):
          dec d
        if d > 0:
          setLen(result, d-1)
          dec state, 2
      else:
        if result.len > 0 and not result.isDireSepa(^1):
          result.add direSepa
        result.add substr(x.string, b[0], b[1])
    elif b[1] == b[0] and x.isCurrDire(b[0]):
      discard "discard the dot"
    elif b[1] >= b[0]:
      if result.len > 0 and not result.isDireSepa(^1):
        result.add direSepa
      result.add substr(x.string, b[0], b[1])
      inc state, 2
  if result.isEmpty and not x.isEmpty:
    result.setCurrDire

proc addNormalizePath*[T: PathX; U: PathX](x: T; result: var U; state: var int) =
  addNormalizePath(x, result, state, OS[T.EOS].dirSep[0])

proc normalizePath*(path: PathX; direSepa: char): typeof(path) =
  runnableExamples:
    import base, lowlevel
    type
      RelaDire = PathX[fdDire, arRela, osLinux, true]
      AbsoFile = PathX[fdFile, arAbso, osWindows, true]
    doAssert normalizePath(RelaDire"./foo//bar/../baz").exactEq RelaDire"foo/baz"
    doAssert normalizePath(AbsoFile"c:\Users/nimmer/..\\vimmer///vimrc").exactEq AbsoFile"c:\Users\vimmer\vimrc"

  ## - Turns multiple slashes into single slashes.
  ## - Resolves `'/foo/../bar'` to `'/bar'`.
  ## - Removes `'./'` from the path, but `"foo/.."` becomes `"."`.
  result = typeof(result) newStringOfCap(path.len)
  var state = 0
  addNormalizePath(path, result, state, direSepa)

proc normalizePath*(path: PathX): typeof(path) =
  normalizePath(path, OS[path.EOS].dirSep[0])

