//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 2023  Brian Frank  Creation
//

using util
using xeto
using xeto::Dict
using xeto::Lib
using haystack
using haystack::Ref

**
** CompileTest
**
@Js
class CompileTest : AbstractXetoTest
{

//////////////////////////////////////////////////////////////////////////
// Scalars
//////////////////////////////////////////////////////////////////////////

  Void testScalars()
  {
    verifyScalar("sys::Marker",   Str<|Marker "marker"|>, env.marker)
    verifyScalar("sys::Marker",   Str<|sys::Marker "marker"|>, env.marker)
    verifyScalar("sys::None",     Str<|None "none"|>, env.none)
    verifyScalar("sys::None",     Str<|sys::None "none"|>, env.none)
    verifyScalar("sys::NA",       Str<|sys::NA "na"|>, env.na)
    verifyScalar("sys::Str",      Str<|"hi"|>, "hi")
    verifyScalar("sys::Str",      Str<|Str "123"|>, "123")
    verifyScalar("sys::Str",      Str<|sys::Str "123"|>, "123")
    verifyScalar("sys::Bool",     Str<|Bool "true"|>, true)
    verifyScalar("sys::Int",      Str<|Int "123"|>, 123)
    verifyScalar("sys::Int",      Str<|Int 123|>, 123)
    verifyScalar("sys::Int",      Str<|Int -123|>, -123)
    verifyScalar("sys::Float",    Str<|Float 123|>, 123f)
    verifyScalar("sys::Duration", Str<|Duration "123sec"|>, 123sec)
    verifyScalar("sys::Number",   Str<|Number "123kW"|>, n(123, "kW"))
    verifyScalar("sys::Number",   Str<|Number 123kW|>, n(123, "kW"))
    verifyScalar("sys::Number",   Str<|Number -89m/s|>, n(-89, "m/s"))
    verifyScalar("sys::Number",   Str<|Number 100$|>, n(100, "\$"))
    verifyScalar("sys::Number",   Str<|Number 50%|>, n(50, "%"))
    verifyScalar("sys::Date",     Str<|Date "2023-02-24"|>, Date("2023-02-24"))
    verifyScalar("sys::Date",     Str<|Date 2023-03-04|>, Date("2023-03-04"))
    verifyScalar("sys::Time",     Str<|Time "02:30:00"|>, Time("02:30:00"))
    verifyScalar("sys::Time",     Str<|Time 02:30:00|>, Time("02:30:00"))
    verifyScalar("sys::Ref",      Str<|Ref "abc"|>, Ref("abc"))
    verifyScalar("sys::Version",  Str<|Version "1.2.3"|>, Version("1.2.3"))
    verifyScalar("sys::Version",  Str<|sys::Version "1.2.3"|>, Version("1.2.3"))
    verifyScalar("sys::Uri",      Str<|Uri "file.txt"|>, `file.txt`)
    verifyScalar("sys::DateTime", Str<|DateTime "2023-02-24T10:51:47.21-05:00 New_York"|>, DateTime("2023-02-24T10:51:47.21-05:00 New_York"))
    verifyScalar("sys::DateTime", Str<|DateTime "2023-03-04T12:26:41.495Z"|>, DateTime("2023-03-04T12:26:41.495Z UTC"))
    verifyScalar("sys::DateTime", Str<|DateTime 2023-03-04T12:26:41.495Z|>, DateTime("2023-03-04T12:26:41.495Z UTC"))
  }

  Void verifyScalar(Str qname, Str src, Obj? expected)
  {
    actual := compileData(src)
    // echo("-- $src")
    // echo("   $actual [$actual.typeof]")
    verifyEq(actual, expected)

    type := env.specOf(actual)
    verifyEq(type.qname, qname)

    pattern := type.get("pattern")
    if (pattern != null && !src.contains("\n"))
    {
      sp := src.index(" ")
      if (src[sp+1] == '"' || src[-1] == '"')
      {
        str := src[sp+2..-2]
        regex := Regex(pattern)
        verifyEq(regex.matches(str), true)
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Multi-line Strings
//////////////////////////////////////////////////////////////////////////

  Void testMultiLineStrs()
  {
    // single lines
    verifyMultiLineStr(Str<|Str """"""|>, "")
    verifyMultiLineStr(Str<|Str """x"""|>, "x")
    verifyMultiLineStr(Str<|Str """\u2022"""|>, "\u2022")
    verifyMultiLineStr(Str<|Str """ """|>, " ")

    // newlines
    verifyMultiLineStr(
      Str<|Str """
           """|>, "")
    verifyMultiLineStr(
      Str<|Str """
             """|>, "")

    // no indention
    verifyMultiLineStr(
      Str<|Str """
           a
            b
             c
           """|>,
      Str<|a
            b
             c
           |>)

    // with indention
    verifyMultiLineStr(
      Str<|Str """
             a
              b
               c
             """|>,
      Str<|a
            b
             c
           |>)

    // with indention in and out
    verifyMultiLineStr(
      Str<|Str """
                 a
                b
               c
                 """|>,
      Str<|  a
            b
           c
           |>)

    // with quotes on last line
    verifyMultiLineStr(
      Str<|Str """
             a
              b
               c"""|>,
      Str<|a
            b
             c|>)

    // based on closing quotes
    verifyMultiLineStr(
      Str<|Str """
              a
               b
                c
             """|>,
      Str<| a
             b
              c
           |>)

    // with first line
    verifyMultiLineStr(
      Str<|Str """a
                   b
                    c
                  """|>,
      Str<|a
            b
             c
           |>)

    // blank lines
    verifyMultiLineStr(
      Str<|Str """a

                   b

                    c

                  """|>,
      Str<|a

            b

             c

           |>)


  }

  Void verifyMultiLineStr(Str src, Str expect)
  {
    Str actual := compileData(src)

    //actual.splitLines.each |line| { echo("| " +  line.replace(" ", ".")) }

    verifyEq(actual, expect)
  }

//////////////////////////////////////////////////////////////////////////
// Dicts
//////////////////////////////////////////////////////////////////////////

  Void testDicts()
  {
    // spec-less
    verifyDict(Str<|{}|>, [:])
    verifyDict(Str<|Dict {}|>, [:])
    verifyDict(Str<|{foo}|>, ["foo":m])
    verifyDict(Str<|{foo, bar}|>, ["foo":m, "bar":m])
    verifyDict(Str<|{dis:"Hi", mark}|>, ["dis":"Hi", "mark":m])

    // LibOrg
    verifyDict(Str<|LibOrg {}|>, ["dis":"", "uri":``, "spec":Ref("sys::LibOrg")], "sys::LibOrg")
    verifyDict(Str<|sys::LibOrg {}|>, ["dis":"", "uri":``, "spec":Ref("sys::LibOrg")], "sys::LibOrg")
    verifyDict(Str<|LibOrg { dis:"Acme" }|>, ["dis":"Acme", "uri":``, "spec":Ref("sys::LibOrg")], "sys::LibOrg")
    verifyDict(Str<|LibOrg { dis:"Acme", uri:Uri "http://acme.com" }|>, ["dis":"Acme", "uri":`http://acme.com`, "spec":Ref("sys::LibOrg")], "sys::LibOrg")

    // whitespace
    /* TODO: how much variation do we want to allow
    verifyDict(Str<|LibOrg
                    {

                    }|>, [:], "sys::LibOrg")
    verifyDict(Str<|LibOrg


                                   {

                    }|>, [:], "sys::LibOrg")
      */
  }

  Void verifyDict(Str src, Str:Obj expected, Str type := "sys::Dict")
  {
    Dict actual := compileData(src)
     // echo("-- $actual [$actual.spec]"); TrioWriter(Env.cur.out).writeDict(actual)
    verifySame(actual.spec, env.type(type))
    if (expected.isEmpty && type == "sys::Dict")
    {
      verifyEq(actual.isEmpty, true)
      verifySame(actual, nameDictEmpty)
      return
    }
    verifyDictEq(actual, expected)
  }

//////////////////////////////////////////////////////////////////////////
// Lib Instances
//////////////////////////////////////////////////////////////////////////

  Void testLibInstances()
  {
    lib := compileLib(
      Str<|Person: Dict {
             person
             first: Str
             last: Str
             born: Date "2000-01-01"
           }

           @brian: Person {first:"Brian", last:"Frank"}

           @alice: Person {
             first: "Alice"
             last: "Smith"
             born: "1980-06-15"
             boss: @brian
           }
           |>)

    spec := lib.type("Person")
    // env.print(spec)

    b := verifyLibInstance(lib, spec, "brian",
      ["person":m, "first":"Brian", "last":"Frank", "born": Date("2000-01-01")])

    a := verifyLibInstance(lib, spec, "alice",
      ["person":m, "first":"Alice", "last":"Smith", "born": Date("1980-06-15"), "boss":b->id])
  }

  Dict verifyLibInstance(Lib lib, Spec spec, Str name, Str:Obj expect)
  {
    x := lib.instance(name)
    id := Ref(lib.name + "::" + name, null)
    // echo("-- $id =>"); TrioWriter(Env.cur.out).writeDict(x)
    verifyEq(lib.instances.containsSame(x), true)
    verifyRefEq(x->id, id)
    verifyDictEq(x, expect.dup.set("id", id).set("spec", Ref(spec.qname)))
    verifySame(x.spec, spec)
    return x
  }

//////////////////////////////////////////////////////////////////////////
// Inherit
//////////////////////////////////////////////////////////////////////////

  Void testInheritSlots()
  {
    lib := compileLib(
      Str<|A: {
             foo: Number <a> 123  // a-doc
           }

           B: A

           C: A {
             foo: Int <c>
           }

           D: A {
             foo: Number 456 // d-doc
           }

           E: D {
           }

           F: D {
             foo: Number <f, baz:"hi">
           }
           |>)

    // env.print(lib)

    num := env.type("sys::Number")
    int := env.type("sys::Int")

    a := lib.type("A"); af := a.slot("foo")
    b := lib.type("B"); bf := b.slot("foo")
    c := lib.type("C"); cf := c.slot("foo")
    d := lib.type("D"); df := d.slot("foo")
    e := lib.type("E"); ef := e.slot("foo")
    f := lib.type("F"); ff := f.slot("foo")

    verifyInheritSlot(a, af, num, num, ["a":m, "val":n(123), "doc":"a-doc"], "a,val,doc")
    verifySame(bf, af)
    verifyInheritSlot(c, cf, af, int, ["a":m, "val":n(123), "doc":"a-doc", "c":m], "c")
    verifyInheritSlot(d, df, af, num, ["a":m, "val":n(456), "doc":"d-doc"], "val,doc")
    verifySame(ef, df)
    verifyInheritSlot(f, ff, df, num, ["a":m, "val":n(456), "doc":"d-doc", "f":m, "baz":"hi"], "f, baz")
  }

  Void verifyInheritSlot(Spec parent, Spec s, Spec base, Spec type, Str:Obj meta, Str ownNames)
  {
    // echo
    // echo("-- testInheritSlot $s base:$s.base type:$s.type")
    // echo("   own = $s.metaOwn")
    // s.each |v, n| { echo("   $n: $v [$v.typeof] " + (s.metaOwn.has(n) ? "own" : "inherit")) }

    verifySame(s.parent, parent)
    verifyEq(s.qname, parent.qname + "." + s.name)
    verifySame(s.base, base)
    verifySame(s.type, type)

    own := ownNames.split(',')
    meta.each |v, n|
    {
      verifyEq(s[n], v)
      verifyEq(s.trap(n), v)
      verifyEq(s.has(n), true)
      verifyEq(s.missing(n), false)

      isOwn := own.contains(n)
      verifyEq(s.metaOwn[n], isOwn ? v : null)
      verifyEq(s.metaOwn.has(n), isOwn)
      verifyEq(s.metaOwn.missing(n), !isOwn)
    }

    s.each |v, n|
    {
      switch (n)
      {
        case "id":   verifyEq(v, s._id)
        case "spec": verifyEq(v, env.ref("sys::Spec"))
        case "type": verifyEq(v, s.type._id)
        default:     verifyEq(meta[n], v, n)
      }
    }

    if (base !== type)
    {
      x := parent.slotsOwn.get(s.name)
      // echo("   ownSlot $x base:$x.base type:$x.type")
      // x.metaOwn.each |v, n| { echo("   $n: $v") }
      verifySame(s, x)
      verifyEq(x.name, s.name)
      verifyEq(x.qname, x.qname)
      verifySame(x.parent, parent)
      verifySame(x.type, type)
      x.metaOwn.each |v, n| { verifyEq(own.contains(n), true) }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Inherit None
//////////////////////////////////////////////////////////////////////////

  Void testInheritNone()
  {
    lib := compileLib(
       Str<|A: Dict <baz, foo: NA "na"> {
              foo: Date <bar, qux> "2023-04-07"
            }
            B : A <baz:None "none"> {
              foo: Date <qux:None "none">
            }
           |>)

    // env.print(lib)

    a := lib.type("A"); af := a.slot("foo")
    b := lib.type("B"); bf := b.slot("foo")

    verifyInheritNone(a, "baz",  env.marker, env.marker)
    verifyInheritNone(a, "foo",  env.na,     env.na)
    verifyInheritNone(af, "bar", env.marker, env.marker)
    verifyInheritNone(af, "qux", env.marker, env.marker)

    verifyInheritNone(b, "baz",  env.none, null)
    verifyInheritNone(b, "foo",  null,     env.na)
    verifyInheritNone(bf, "bar", null,     env.marker)
    verifyInheritNone(bf, "qux", env.none, null)
  }

  private Void verifyInheritNone(Spec s, Str name, Obj? own, Obj? effective)
  {
    // echo("~~ $s.qname own=" + s.metaOwn[name] + " effective=" + s[name])
    verifyEq(s.metaOwn[name], own)
    verifyEq(s[name], effective)
  }

//////////////////////////////////////////////////////////////////////////
// Nested specs
//////////////////////////////////////////////////////////////////////////

  Void testNestedSpecs()
  {
    lib := compileLib(
       Str<|Foo: {
              a: List<of:Foo>
              b: List<of:Spec>
              c: List<of:Ref<of:Foo>>
              d: List<of:Ref<of:Spec>>
              e: List<of:Foo <qux>>
              f: List<of:Foo <> { extra: Str }>
              g: List<of:Foo <qux> { extra: Str }>
              h: List<of:Foo | Bar>
              i: List<of:Foo & Bar>
              j: Dict < x:Foo? >
              k: Dict < x:Foo<qux> >
              l: Dict < x:Foo<y:Bar<z:Str>> >
            }

            Bar: {}
           |>)

    foo := lib.type("Foo")
    /*
    env.print(lib)
    foo.slots.each |slot|
    {
      echo("${slot.name}: " + toNestedSpecSig(lib, slot))
    }
    */

    verifyNestedSpec(foo.slot("a"), "List<of:Foo>")
    verifyNestedSpec(foo.slot("b"), "List<of:Spec>")
    verifyNestedSpec(foo.slot("c"), "List<of:Ref<of:Foo>>")
    verifyNestedSpec(foo.slot("d"), "List<of:Ref<of:Spec>>")
    verifyNestedSpec(foo.slot("e"), "List<of:Foo<qux>>")
    verifyNestedSpec(foo.slot("f"), "List<of:Foo{extra:Str}>")
    verifyNestedSpec(foo.slot("g"), "List<of:Foo<qux>{extra:Str}>")
    verifyNestedSpec(foo.slot("h"), "List<of:Foo|Bar>")
    verifyNestedSpec(foo.slot("i"), "List<of:Foo&Bar>")
    verifyNestedSpec(foo.slot("j"), "Dict<x:Foo<maybe>>")
    verifyNestedSpec(foo.slot("k"), "Dict<x:Foo<qux>>")
    verifyNestedSpec(foo.slot("l"), "Dict<x:Foo<y:Bar<z:Str>>>")
  }

  Void verifyNestedSpec(Spec x, Str expect)
  {
    actual := toNestedSpecSig(x.lib, x)
    verifyEq(actual, expect)
  }

  Str toNestedSpecSig(Lib lib, Spec x)
  {
    if (x.isCompound)
    {
      sep := x.isAnd ? "&" : "|"
      return x.ofs.join(sep) |c| { c.name }
    }

    s := StrBuf()
    if (x.type.name[0] == '_')
      s.add(x.base.name)
    else
      s.add(x.type.name)

    if (!x.metaOwn.isEmpty)
    {
      s.add("<")
      x.metaOwn.each |v, n|
      {
        s.add(n)
        if (v === Marker.val) return
        s.add(":").add(toNestedSpecRef(lib, v))
      }
      s.add(">")
    }

    if (!x.slotsOwn.isEmpty)
    {
      s.add("{")
      x.slotsOwn.each |slot| { s.add(slot.name).add(":").add(slot.type.name) }
      s.add("}")
    }

    return s.toStr
  }

  Str toNestedSpecRef(Lib lib, Ref x)
  {
    name := x.toStr[x.toStr.indexr(":")+1..-1]
    if (name[0] != '_') return name

    deref := lib.type(name)
    return toNestedSpecSig(lib, deref)
  }
}