//
// Copyright (c) 2010, SkyFoundry LLC
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 2010  Brian Frank  Creation
//    3 Jan 2016  Brian Frank  Refactor for 3.0
//

using concurrent

**
** PasswordStore manages plaintext/hashed passwords and other secrets.
** It is stored via an obscured props file to prevent casual reading,
** but is not encrypted.  The passwords file must be kept secret and
** reads must be sequestered from all network access.  We separate secrets
** from the main database so that it may be more easily secured.
**
const class PasswordStore
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Open for the given file
  @NoDoc static PasswordStore open(File file, FolioConfig config)
  {
    ps := make(file, config)
    ps.actor.send(ps).get(timeout) // load message
    return ps
  }

  private new make(File file, FolioConfig config)
  {
    this.file     = file
    this.idPrefix = config.idPrefix
    this.log      = config.log
    this.actor    = Actor(config.pool) |msg| { receive(msg); return null }
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  ** File used to store passwords passed to `open` method.
  @NoDoc const File file

  ** Logging
  @NoDoc const Log log

  ** Ref prefix
  @NoDoc const Str? idPrefix

  ** Get a password by its key or return null if not found.
  Str? get(Str key)
  {
    val := cache[key]
    if (val == null && idPrefix != null && key.startsWith(idPrefix))
      val = cache[key[idPrefix.size..-1]]
    if (val == null) return null
    return decode(val)
  }

  ** Set a password by its key.
  Void set(Str key, Str val)
  {
    // relative key if necessary
    if (idPrefix != null && key.startsWith(idPrefix))
      key = key[idPrefix.size..-1]

    actor.send([key, encode(val)].toImmutable).get(timeout)
  }

  ** Remove a password by its key.
  Void remove(Str key)
  {
    if (cache[key] != null)
      actor.send(key).get(timeout)
  }

//////////////////////////////////////////////////////////////////////////
// Messaging
//////////////////////////////////////////////////////////////////////////

  private Void receive(Obj? msg)
  {
    // null if sync for testing only
    if (msg == null) return

    // if this, its startup load message
    if (msg === this)
    {
      try
        if (file.exists) cacheRef.val = file.readProps.toImmutable
      catch (Err e)
        log.err("Failed to load $file", e)
      return
    }

    // set or remove
    newCache := cache.dup
    set := msg as List
    if (set != null)
      newCache[set[0]] = set[1]
    else
      newCache.remove((Str)msg)

    // update cache
    cacheRef.val = newCache.toImmutable

    // rewrite file
    out := file.out
    try
      file.writeProps(newCache)
    catch (Err e)
      log.err("Failed to save $file", e)
    finally
      out.close
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Encode a password into an obsured format that provides
  ** marginal protection over plaintext.
  @NoDoc static Str encode(Str password)
  {
    // pad short passwords
    if (password.size < 10)
      password += "\u0000" + Str.spaces(10-password.size)
    buf := Buf()
    rs := rands.size
    x := Int.random(0..<rs)
    y := Int.random(0..<rs)
    z := Int.random(0..<rs)
    buf.write(0x6C)  // ver/magic
    buf.write(x)     // index into rands
    buf.write(y)     // index into rands
    buf.write(z)     // index into rands
    password.each |ch, i|
    {
      if (ch > 0x3fff) throw IOErr("Unsupported unicode chars")
      mask := rands[(x+i)%rs]
         .xor(rands[(y+i)%rs])
         .xor(rands[(z+i)%rs])
      buf.writeI2(ch.shiftl(2).xor(mask).and(0xffff))
    }
    return buf.toBase64
  }

  ** Given an encoded password, decode into the actual password.
  @NoDoc static Str decode(Str password)
  {
    buf := Buf.fromBase64(password)
    if (buf.readU1 != 0x6C) throw IOErr("bad password")
    rs := rands.size
    x := buf.readU1  // index into rands
    y := buf.readU1  // index into rands
    z := buf.readU1  // index into rands
    s := StrBuf()
    while (buf.more)
    {
      i := s.size
      mask := rands[(x+i)%rs]
         .xor(rands[(y+i)%rs])
         .xor(rands[(z+i)%rs])
      ch := buf.readU2.xor(mask).shiftr(2).and(0x3fff)
      if (ch == 0) break
      s.addChar(ch)
    }
    return s.toStr
    return ""
  }

  private static const Int[] rands :=
  [
    0x8b173c97d70961c1,
    0xcf8e5bfa60994287,
    0xcbdd1d43df008afe,
    0x961097d99af14ac0,
    0x06a5f6771246a91d,
    0x2ee1ba8375b4d34b,
    0x060e3e6cb0f9b632,
    0x20a6b6643e5e3f8a,
    0x0428f439342e73c3,
    0x54a6ec0f585f7042,
    0xe827f4494c90a635,
    0x3abedd06bb8f7d0a,
    0xc79f221912d25608,
    0x2c62534b3bea2d44,
    0xd632b4ffdaeca67c,
    0x68ad1e314553f07d,
    0xe5e1c7fdbc3e4193,
    0x232840bc25563c2b,
    0x127e2cf874dee710,
    0x7fe9487be804a253
  ]

//////////////////////////////////////////////////////////////////////////
// Private Fields
//////////////////////////////////////////////////////////////////////////

  private static const Duration timeout := 15sec
  private Str:Str cache() { cacheRef.val }
  private const AtomicRef cacheRef := AtomicRef(Str:Str[:].toImmutable)
  private const Actor actor
}

