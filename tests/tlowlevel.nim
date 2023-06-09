import pathX/[base, lowlevel]

type
  LinuxAbsoFile = PathX[fdFile, arAbso, osLinux, true]
  LinuxRelaFile = PathX[fdFile, arRela, osLinux, true]

block:
  let
    p0 = LinuxAbsoFile"/tmp"

  doAssert p0.isDireSepa(0)
  doAssert not p0.isDireSepa(int.high)
  doAssert not p0.isDireSepa(-1)
  doAssert p0.isDireSepa(^4)
  doAssert not p0.isDireSepa(^1)
  doAssert not p0.isPareDire(0)

block:
  let p0 = LinuxRelaFile"."
  doAssert p0.isCurrDire(0)
  doAssert p0.isCurrDireOnly()

  let p1 = LinuxAbsoFile"/."
  doAssert not p1.isCurrDire(0)
  doAssert p1.isCurrDire(1)
  doAssert not p1.isCurrDireOnly()

block:
  let p0 = LinuxRelaFile".."
  doAssert p0.isPareDire(0)
  doAssert not p0.isPareDire(1)
  doAssert p0.isPareDireOnly()

  let p1 = LinuxAbsoFile"/abc/../def"
  doAssert p1.isPareDire(5)
  doAssert not p1.isPareDire(0)
  doAssert not p1.isPareDireOnly
