#! /usr/bin/env fan
//
// Copyright (c) 2015, SkyFoundry LLC
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2015   Brian Frank  Creation
//

using build

**
** Build: folio
**
class Build : BuildPod
{
  new make()
  {
    podName = "folio"
    summary = "Folio database APIs"
    meta    = ["org.name":     "SkyFoundry",
               "org.uri":      "https://skyfoundry.com/",
               "proj.name":    "Haxall",
               "proj.uri":     "https://haxall.io/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/haxall/haxall"
              ]
    depends = ["sys @{fan.depend}",
               "concurrent @{fan.depend}",
               "haystack @{hx.depend}"]
    srcDirs = [`fan/`]
  }
}