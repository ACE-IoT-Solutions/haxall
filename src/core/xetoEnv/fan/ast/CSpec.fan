//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Apr 2023  Brian Frank  Creation
//

using xeto
using util

**
** CSpec is common API shared by both ASpec, RSpec, and XetoSpec
**
@Js
mixin CSpec : CNode
{
  ** Return if this an AST ASpec
  abstract Bool isAst()

  ** Assembled XetoSpec (stub only in AST until Assemble step)
  override abstract XetoSpec asm()

  ** Simple name
  abstract Str name()

  ** Qualified name
  abstract Str qname()

  ** Ref for qualified name
  abstract override haystack::Ref id()

  ** Factory for spec type
  abstract SpecFactory factory()

  ** Type of the spec or if this a type then return self
  abstract CSpec? ctype()

  ** Base spec or null if this sys::Obj itself
  abstract CSpec? cbase()

  ** Effective meta
  abstract MNameDict cmeta()

  ** Lookup effective slot
  abstract CSpec? cslot(Str name, Bool checked := true)

  ** Iterate the effective slots as map
  abstract Void cslots(|CSpec, Str| f)

  ** Return list of component specs for a compound type
  abstract CSpec[]? cofs()

  ** MSpecFlags bitmask flags
  abstract Int flags()

  ** MSpecArgs
  abstract MSpecArgs args()

  ** Is scalar flag set
  abstract Bool isScalar()

  ** Is maybe flag set
  abstract Bool isList()

  ** Is maybe flag set
  abstract Bool isMaybe()

  ** Is query flag set
  abstract Bool isQuery()
}

**************************************************************************
** CNode
**************************************************************************

@Js
mixin CNode
{
  ** Required for covariant conflict so that signature matches ANode
  abstract Obj asm()

  ** Qualified name as Ref
  abstract haystack::Ref id()
}


