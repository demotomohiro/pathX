import ../base

type
  InvalidOSDefect* = object of Defect

  BuildOSFile*[AoR: static[AbsoOrRela]; DoesFollowLink: static[bool]] = PathX[fdFile, AoR, BuildOS, DoesFollowLink]
  HostOSFile*[AoR: static[AbsoOrRela]; DoesFollowLink: static[bool]] = PathX[fdFile, AoR, HostOS, DoesFollowLink]
