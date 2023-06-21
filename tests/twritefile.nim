import pathX/[base, readfile, writefile]

when BuildOS != HostOS:
  import pathX/private/readwrite

type
  BuildOSFile = PathX[fdFile, arRela, BuildOS, true]
  HostOSFile = PathX[fdFile, arRela, HostOS, true]

proc test(testpath: BuildOSFile or HostOSFile) =
  const content = "Test content"

  write(testpath, content)
  # If it was const instead of let, read called before above write.
  let readContent = read(testpath)

  doAssert readContent == content

static: test(BuildOSFile"testcompiletime.txt")
test(HostOSFile"testruntime.txt")

when BuildOS != HostOS:
  static:
    doAssertRaises(InvalidOSDefect): discard read(HostOSFile"testruntime.txt")
    doAssertRaises(InvalidOSDefect, write(HostOSFile"testruntime.txt", "content"))

  doAssert not compiles(read(BuildOSFile"testruntime.txt"))
  doAssert not compiles(write(BuildOSFile"testruntime.txt", "content"))
