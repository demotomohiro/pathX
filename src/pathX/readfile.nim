## This module provides procedures to open and read a file.

import pathX/base
import private/readwrite

proc read*(filePath: HostOSFile): string =
  when nimvm:
    when filePath.EOS != BuildOS:
      raise newException(InvalidOSDefect, "Reading a file with host OS path at compile time is an error.")
  else:
    discard
 
  readFile($filePath)

when BuildOS != HostOS:
  proc read*(filePath: BuildOSFile): string {.compileTime.} =
    readFile($filePath)
