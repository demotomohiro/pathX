# Based on lib/std/private/ospaths2.nim in Nim standard library.

import base, lowlevel, pathnorm
import std/private/ntpath

proc normalizePathEnd*(path: var PathX; trailingSep = false) =
  ## Ensures ``path`` has exactly 0 or 1 trailing directory separator, depending on
  ## ``trailingSep``, and taking care of edge cases: it preservers whether
  ## a path is absolute or relative, and makes sure trailing sep is `DirSep`,
  ## not `AltSep`. Trailing `/.` are compressed, see examples.
  if path.len == 0: return
  var i = path.len
  while i >= 1:
    if path.isDireSepa(i - 1): dec(i)
    elif path.isCurrDire(i - 1) and path.isDireSepa(i - 2): dec(i)
    else: break
  if trailingSep:
    # foo// => foo
    path.setLen(i)
    # foo => foo/
    path.addDireSepa
  elif i > 0:
    # foo// => foo
    path.setLen(i)
  else:
    # // => / (empty case was already taken care of)
    path.setDireSepa

proc normalizePathEnd*(path: PathX; trailingSep = false): typeof(path) =
  ## outplace overload
  runnableExamples:
    import pathX/[base, lowlevel]
    type
      AbsoDire = PathX[fdDire, arAbso, osLinux, true]
      RelaDire = PathX[fdDire, arRela, osLinux, true]
    assert normalizePathEnd(AbsoDire"/lib//.//", trailingSep = true).exactEq AbsoDire"/lib/"
    assert normalizePathEnd(RelaDire"lib/./.", trailingSep = false).exactEq RelaDire"lib"
    assert normalizePathEnd(RelaDire".//./.", trailingSep = false).exactEq RelaDire"."
    assert normalizePathEnd(RelaDire"", trailingSep = true).exactEq RelaDire"" # not / !
    assert normalizePathEnd(AbsoDire"/", trailingSep = false).exactEq AbsoDire"/" # not "" !
  result = path
  result.normalizePathEnd(trailingSep)

proc joinPathImpl[PR: PathX; PT: PathX](result: var PR, state: var int, tail: PT) =
  static:
    assert PR.EOS == PT.EOS

  let trailingSep = tail.isDireSepa(^1) or tail.len == 0 and result.isDireSepa(^1)
  normalizePathEnd(result, trailingSep=false)
  addNormalizePath(tail, result, state, PR.direSepaChar)
  normalizePathEnd(result, trailingSep=trailingSep)

func joinPath*[PH: PathX; PT: PathX](head: PH; tail: PT):
  PathX[PT.FoD, PH.AoR, PH.EOS, PT.DoesFollowLink] =
  ## Joins two directory names to one.
  ##
  ## Returns normalized path concatenation of `head` and `tail`, preserving
  ## whether or not `tail` has a trailing slash (or, if tail if empty, whether
  ## head has one).
  ##
  ## See also:
  ## * `/ proc`_
  runnableExamples:
    import pathX/[base, lowlevel]
    type
      AbsoDire = PathX[fdDire, arAbso, osLinux, true]
      RelaDire = PathX[fdDire, arRela, osLinux, true]
    assert joinPath(RelaDire"usr", RelaDire"lib").exactEq RelaDire"usr/lib"
    assert joinPath(RelaDire"usr", RelaDire"lib/").exactEq RelaDire"usr/lib/"
    assert joinPath(RelaDire"usr", RelaDire"").exactEq RelaDire"usr"
    assert joinPath(RelaDire"usr/", RelaDire"").exactEq RelaDire"usr/"
    assert joinPath(RelaDire"", RelaDire"").exactEq RelaDire""
    assert joinPath(RelaDire"", RelaDire"lib").exactEq RelaDire"lib"
    assert joinPath(RelaDire"usr/lib", RelaDire"../bin").exactEq RelaDire"usr/bin"
    assert joinPath(AbsoDire"/usr/lib", RelaDire"../bin").exactEq AbsoDire"/usr/bin"

  when PH.EOS != PT.EOS:
    {.error: "Don't mix pathes for different OS".}
  elif PH.FoD != fdDire:
    {.error: "head must be directory".}
  elif PT.AoR != arRela:
    {.error: "tail must be relative path".}

  result = newPathXOfCap[typeof(result)](head.len + tail.len)
  var state = 0
  joinPathImpl(result, state, head)
  joinPathImpl(result, state, tail)

proc `/`*[PH: PathX; PT: PathX](head: PH; tail: PT):
  PathX[PT.FoD, PH.AoR, PH.EOS, PT.DoesFollowLink]
  {.noSideEffect, inline.} =
  ## The same as `joinPath(head, tail) proc`_.
  ##
  ## See also:
  ## * `joinPath(head, tail) proc`_
  runnableExamples:
    import pathX/[base, lowlevel]
    type
      AbsoDire = PathX[fdDire, arAbso, osLinux, true]
      RelaDire = PathX[fdDire, arRela, osLinux, true]
      AbsoFile = PathX[fdFile, arAbso, osLinux, true]
      RelaFile = PathX[fdFile, arRela, osLinux, true]
    assert (RelaDire"usr" / RelaDire"").exactEq RelaDire"usr"
    assert (RelaDire"" / RelaDire"lib").exactEq RelaDire"lib"
    assert (RelaDire"usr" / RelaDire"lib" / RelaDire"../bin").exactEq RelaDire"usr/bin"
    assert (AbsoDire"/bin" / RelaFile"nim").exactEq AbsoFile"/bin/nim"

  result = joinPath(head, tail)

func parentDirPos(path: PathX): int =
  var q = 1
  if path.isDireSepa(^1): q = 2
  for i in countdown(len(path)-q, 0):
    if path.isDireSepa(i):
      return i
  result = -1

func parentDir*[T: PathX](path: T): PathX[fdDire, T.AoR, T.EOS, T.DoesFollowLink] =
  ## Returns the parent directory of `path`.
  ##
  ## This is similar to ``splitPath(path).head`` when ``path`` doesn't end
  ## in a dir separator, but also takes care of path normalizations.
  ## The remainder can be obtained with `lastPathPart(path) proc`_.
  ##
  ## See also:
  runnableExamples:
    import pathX/[base, lowlevel]
    type
      AbsoDire = PathX[fdDire, arAbso, osLinux, true]
      RelaDire = PathX[fdDire, arRela, osLinux, true]
      AbsoFile = PathX[fdFile, arAbso, osLinux, true]
    assert parentDir(RelaDire"").exactEq RelaDire".."
    assert parentDir(AbsoDire"/usr/local/bin").exactEq AbsoDire"/usr/local"
    assert parentDir(RelaDire"foo/bar//").exactEq RelaDire"foo"
    assert parentDir(AbsoDire"//foo//bar//.").exactEq AbsoDire"/foo"
    assert parentDir(RelaDire"./foo").exactEq RelaDire"."
    assert parentDir(AbsoDire"/./foo//./").exactEq AbsoDire"/"
    assert parentDir(RelaDire"a//./").exactEq RelaDire"."
    assert parentDir(RelaDire"a/b/c/..").exactEq RelaDire"a"
    assert parentDir(AbsoFile"/bin/nim").exactEq AbsoDire"/bin"
  result = typeof(result)(pathnorm.normalizePath(path))
  when path.typeof.isDoslikeFileSystem:
    let (drive, splitpath) = splitDrive($result)
    result = typeof(result)(splitpath)
  var sepPos = parentDirPos(result)
  if sepPos >= 0:
    result.setLen(sepPos + 1)
    normalizePathEnd(result)
  elif result.isCurrDireOnly or result.isEmpty:
    when path.typeof.isDoslikeFileSystem:
      if drive.len == 0:
        result.setPareDire
    else:
      result.setPareDire
  elif result.isDireSepa(^1) or result.isPareDireOnly:
    discard
  else:
    result = typeof(result).currDire
  when path.typeof.isDoslikeFileSystem:
    if drive.len > 0 and result.isDireSepaOnly:
      result = typeof(result)(drive)
    else:
      result = typeof(result)(drive) & result
