//
// Copyright (c) 2022, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Mar 2022  Brian Frank  Creation
//  26 Jan 2023  Brian Frank  Repurpose ProtoCompiler
//

using util
using xetoEnv

**
** Base class for XetoCompiler steps
**
abstract internal class Step
{
  XetoCompiler? compiler

  abstract Void run()

  LocalEnv env() { compiler.env }

  Bool isLib() { compiler.isLib }

  Bool isData() { !compiler.isLib }

  Bool isSys() { compiler.isSys }

  ASys sys() { compiler.sys }

  ANode ast() { compiler.ast }

  ALib lib() { compiler.lib }

  ADict? pragma() { compiler.pragma }

  Void info(Str msg) { compiler.info(msg) }

  XetoCompilerErr err(Str msg, FileLoc loc, Err? err := null) { compiler.err(msg, loc, err) }

  XetoCompilerErr err2(Str msg, FileLoc loc1, FileLoc loc2, Err? err := null) { compiler.err2(msg, loc1, loc2, err) }

  Void bombIfErr() { if (!compiler.errs.isEmpty) throw compiler.errs.first }

}




