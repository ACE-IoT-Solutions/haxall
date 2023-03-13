//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 2023  Brian Frank  Creation
//

using data
using util

**
** Utility functions
**
@Js
internal const class XetoUtil
{

//////////////////////////////////////////////////////////////////////////
// Naming
//////////////////////////////////////////////////////////////////////////

  ** Return if valid spec name
  static Bool isSpecName(Str n)
  {
    if (n.isEmpty || !n[0].isAlpha) return false
    return n.all |c| { c.isAlphaNum || c == '_' }
  }

//////////////////////////////////////////////////////////////////////////
// Inherit Meta
//////////////////////////////////////////////////////////////////////////

  ** Inherit spec meta data
  static DataDict inheritMeta(MSpec spec)
  {
    own := spec.own

    base := spec.base as XetoSpec
    if (base == null) return own

    if (own.isEmpty) return base.m.meta

    acc := Str:Obj[:]
    base.m.meta.each |v, n|
    {
      if (isMetaInherited(n)) acc[n] = v
    }
    own.each |v, n|
    {
      acc[n] = v
    }
    return spec.env.dictMap(acc)
  }

  static Bool isMetaInherited(Str name)
  {
    // we need to make this use reflection at some point
    if (name == "abstract") return false
    if (name == "sealed") return false
    return true
  }

//////////////////////////////////////////////////////////////////////////
// Inherit Slots
//////////////////////////////////////////////////////////////////////////

  ** Inherit spec slots
  static MSlots inheritSlots(MSpec spec)
  {
    own := spec.slotsOwn
    supertype := spec.base

    if (supertype == null) return own
    if (own.isEmpty) return supertype.slots

    // add supertype slots
    acc := Str:XetoSpec[:]
    acc.ordered = true
    supertype.slots.each |s, n|
    {
      acc[n] = s
    }

    // add in my own slots
    own.each |s, n|
    {
      inherit := acc[n]
      if (inherit != null) s = overrideSlot(inherit, s)
      acc[n] = s
    }

    return MSlots(acc)
  }

  ** Merge inherited slot 'a' with override slot 'b'
  static XetoSpec overrideSlot(XetoSpec a, XetoSpec b)
  {
    XetoSpec(MSpec(b.loc, b.parent, b.name, a, b.type, b.own, b.slotsOwn, b.m.flags))
  }

//////////////////////////////////////////////////////////////////////////
// Is-A
//////////////////////////////////////////////////////////////////////////

  ** Return if a is-a b
  static Bool isa(XetoSpec a, XetoSpec b)
  {
    // check direct inheritance
    and := a.m.env.sys.and
    maybe := a.m.env.sys.maybe
    isAnd := false
    isMaybe := false
    for (DataSpec? x := a; x != null; x = x.base)
    {
      if (x === b) return true

      if (x === and) isAnd = true
      else if (x === maybe) isMaybe = true
    }

    // if A is "maybe" type, then check his "of"
    if (isMaybe)
    {
      of := a.get("of", null) as DataSpec
      if (of != null) return of.isa(b)
    }

    // if A is "and" type, then check his "ofs"
    if (isAnd)
    {
      ofs := a.get("ofs", null) as DataSpec[]
      if (ofs != null && ofs.any |x| { x.isa(b) }) return true
    }

    return false
  }

//////////////////////////////////////////////////////////////////////////
// Derive
//////////////////////////////////////////////////////////////////////////

  ** Dervice a new spec from the given base, meta, and map
  static DataSpec derive(XetoEnv env, Str name, XetoSpec base, DataDict meta, [Str:DataSpec]? slotsMap)
  {
    // create MSlots for map
    slots := (slotsMap == null || slotsMap.isEmpty) ? MSlots.empty : MSlots(slotsMap)

    // sanity checking
    if (!isSpecName(name)) throw ArgErr("Invalid spec name: $name")
    if (meta.isEmpty && slots.isEmpty) throw ArgErr("Must specify meta or slots")
    if (base.own.has("sealed")) throw ArgErr("Cannot derive from sealed type: $base")
    if (!base.isDict)
    {
      if (!slots.isEmpty) throw ArgErr("Cannot add slots to non-dict type: $base")
    }

    return XetoSpec(MDerivedSpec(env, name, base, meta, slots))
  }
}
