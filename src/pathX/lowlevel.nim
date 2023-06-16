## Low level procs and funcs that are required to implement this library
## but library users would not use.

import base
import "$nim"/compiler/platform

func `[]`*(x: PathX; i: Natural): char = x.string[i]

func `[]=`*(x: var PathX; i: Natural; c: char) =
  x.string[i] = c

proc setLen*(s: var PathX; newlen: Natural) {.borrow.}

proc `&`*[T: PathX](x, y: T): T =
  # Cannot borrow this?
  T (x.string & y.string)

func add*(x: var PathX; y: string or char) =
  x.string.add y

func add*[T: PathX](x: var T; y: T) =
  x.string.add y.string

func isEmpty*(x: PathX): bool =
  ## Empty string is a relative path same to current working directory.
  x.len == 0

func direSepaChar*(t: typedesc[PathX]): char =
  ## Returns a directory separator character.
  ##
  ## e.g. Returns '/' on linux and '\' on windows.
  OS[t.EOS].dirSep[0]

func alteDireSepaChar*(t: typedesc[PathX]): char =
  ## Returns alternative directory separator character.
  ##
  ## e.g. Returns '/' on linux and windows.
  OS[t.EOS].altDirSep[0]

func direSepaChar*(x: PathX): char =
  typeof(x).direSepaChar

func alteDireSepaChar*(x: PathX): char =
  typeof(x).alteDireSepaChar

func direSepa*(t: typedesc[PathX]): t =
  t $(t.direSepaChar)

func alteDireSepa*(t: typedesc[PathX]): t =
  t $(t.alteDireSepaChar)

proc setDireSepa*(x: var PathX) =
  x = typeof(x).direSepa

func isDireSepa*(os: TSystemOS; c: char): bool =
  c in {OS[os].dirSep[0], OS[os].altDirSep[0]}

func isDireSepa*(x: PathX; c: char): bool =
  isDireSepa(x.EOS, c)

func isDireSepa*(x: PathX; i: int): bool =
  (i in 0 ..< x.len) and isDireSepa(x.EOS, x[i])

func isDireSepa*(x: PathX; i: BackwardsIndex): bool =
  isDireSepa(x, (x.len - i.int))

func isDireSepaOnly*(x: PathX): bool =
  x.len == 1 and isDireSepa(x.EOS, x[0])

func currDire*(t: typedesc[PathX]): t =
  ## Returns a current directory character.
  ## It is '.' on most of OS.
  t $(OS[t.EOS].curDir[0])

proc setCurrDire*(x: var PathX) =
  x = typeof(x).currDire

func isCurrDire*(os: TSystemOS; c: char): bool =
  c == OS[os].curDir[0]

func isCurrDire*(x: PathX; i: int): bool =
  (i in 0 ..< x.len) and isCurrDire(x.EOS, x[i])

func isCurrDireOnly*(x: PathX): bool =
  x.len == 1 and x.isCurrDire(0)

func pareDire(t: typedesc[PathX]): t =
  ## Returns a parent directory string.
  ## It is ".." on most of OS.
  OS[t.EOS].parDir.t

func setPareDire*(x: var PathX) =
  x = pareDire(typeof(x))

func isPareDire*(x: PathX; i: int): bool =
  (i in 0 ..< (x.len - 1)) and x[i] == OS[x.EOS].parDir[0] and x[i + 1] == OS[x.EOS].parDir[1]

func isPareDireOnly*(x: PathX): bool =
  x.len == 2 and x.isPareDire(0)

func addDireSepa*(x: var PathX) =
  x.string.add typeof(x).direSepaChar

proc newPathXOfCap*[T: PathX](cap: Natural): T =
  newStringOfCap(cap).T

proc exactEq*(x, y: PathX): bool =
  ## Return true if x and y have same string.
  ## It doesn't care if comparing x and y should be case insensitive or not.
  ## This is for testing not for a generic path comparision.
  $x == $y
