## This module implements path handlings.
## Procedures in this module only do string manipulation
## and never access file systems.

import base, ospaths2

func joinDire*[PH: PathX](head: PH; tailDire: string{lit}):
  PathX[fdDire, PH.AoR, PH.EOS, PH.DoesFollowLink] =
  ## Joins `tailDire` directory to `head` and returns it.
  ## `tailDire` must be a single directory name.
  runnableExamples:
    import base, lowlevel
    type
      AbsoDire = PathX[fdDire, arAbso, osLinux, true]
    assert AbsoDire"/home".joinDire"nimmer".exactEq AbsoDire"/home/nimmer"
  ospaths2.joinPath(head,
                    PathX[fdDire, arRela, PH.EOS, PH.DoesFollowLink](tailDire))

func joinFile*[PH: PathX](head: PH; tailFile: string{lit}):
  PathX[fdFile, PH.AoR, PH.EOS, PH.DoesFollowLink] =
  ## Joins `tailFile` file to `head` and returns it.
  ## `tailFile` must be a single file name.
  runnableExamples:
    import base, lowlevel
    type
      AbsoDire = PathX[fdDire, arAbso, osLinux, true]
      AbsoFile = PathX[fdFile, arAbso, osLinux, true]
    assert AbsoDire"/bin".joinFile"nim".exactEq AbsoFile"/bin/nim"
  ospaths2.joinPath(head,
                    PathX[fdFile, arRela, PH.EOS, PH.DoesFollowLink](tailFile))
