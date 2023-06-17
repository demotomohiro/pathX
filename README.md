# pathX
Generic path handling library
[Document](https://demotomohiro.github.io/pathX/pathX.html)

PathX provides procedures that work like procedures in os module in Nim's stdlib,
but it can create paths for arbitrary OS at both compile time and runtime.

In cross compilation, Nim's os module cannot compose paths that can be used to access the file on the build machine at compile time.
For example, suppose you are cross compiling Windows executable on Linux machine.
If you use `joinPath` procedure at compile time, it works in the same way as on Windows and use '\' to join two paths.
In that case, there is no way to ask `joinPath` to use '/' to generate a path for Linux and you cannot use it on build machine.

PathX allows you to choose which OS paths are composed for.
So in cross compilation, you can create paths for both build machine and target machine at compile time.
You can also create paths for any supported OS that is different from the OS your program runs on.

`PathX` generic type has generic parameters to specify file or directory and absolute or relative to provide type safety.
And it also has a bool generic parameter to specify whether it follow a symbolic link.

### Example code

In following code, `someFile` contains a path for the OS that compiler runs on
even if you cross compile it.
And you can use it to read the file at compile time.
```nim
import pathX

type
  # Type for a relative path to a file on build machine
  BuildOSRelaFile = PathX[fdFile, arRela, BuildOS, true]
  # Type for an absolute path to a directory on build machine
  BuildOSAbsoDire = PathX[fdDire, arAbso, BuildOS, true]

const SomeFile = BuildOSAbsoDire"/tmp" / BuildOSRelaFile"data.txt"

static:
  echo SomeFile

const SomeData = staticRead($SomeFile)
```

If you cross compile above code on Linux with --os:windows option, output is:
```
/tmp/data.txt
```

In following code, `HostFile` contains a path for target OS
and you can use it to read a file at runtime.
```nim
import pathX

type
  # Type for a relative path to the file on the target OS.
  HostOSRelaFile = PathX[fdFile, arRela, HostOS, true]
  # Type for a absolute path to the directory on the target OS.
  HostOSAbsoDire = PathX[fdDire, arAbso, HostOS, true]

const HostFile = HostOSAbsoDire"c:\Users\foo" / HostOSRelaFile"data.txt"

static:
  echo HostFile

let HostData = readFile($HostFile)
```

If you cross compile above code on Linux with --os:windows option, output is:
```
c:\Users\foo\data.txt
```

You can create paths for any supported OS regardless of build OS and target OS:
```nim
import pathX

let someFile = "foo".PathX[:fdDire, arRela, osMacOS, true].joinFile "bar.nim"
echo someFile
```

Output:
```
foo:bar.nim
```

You can specify OS from `TSystemOS` enum in [compiler/platform.nim](https://github.com/nim-lang/Nim/blob/devel/compiler/platform.nim)

## Requirements

- Nim devel version
  - It will support stable version when Nim 2.0 is released if possible
- Nim compiler module
  - Make sure `import compiler/platform` works

