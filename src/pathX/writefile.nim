## This module provides procedures to open and write a file.

import pathX/base
import private/readwrite

proc write*(filePath: HostOSFile; content: string) =
  when nimvm:
    when filePath.EOS != BuildOS:
      raise newException(InvalidOSDefect, "Writing a file with host OS path at compile time is an error.")
  else:
    discard

  writeFile($filePath, content)

when BuildOS != HostOS:
  proc write*(filePath: BuildOSFile; content: string) {.compileTime.} =
    writeFile($filePath, content)
