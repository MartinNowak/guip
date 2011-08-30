module guip.color;

import std.algorithm, std.array, std.exception, std.string, std.ascii, std.conv : to;

//version=VERBOSE;

struct Color
{
  uint argb;

  immutable Color Black     = Color(0xff000000);
  immutable Color DarkGray  = Color(0xff444444);
  immutable Color Gray      = Color(0xff888888);
  immutable Color LightGray = Color(0xffcccccc);
  immutable Color WarmGray  = Color(0xffaab2b7);
  immutable Color ColdGray  = Color(0xff67748c);
  immutable Color White     = Color(0xffffffff);
  immutable Color Red       = Color(0xffff0000);
  immutable Color Green     = Color(0xff00ff00);
  immutable Color Blue      = Color(0xff0000ff);
  immutable Color Yellow    = Color(0xffffff00);
  immutable Color Cyan      = Color(0xff00ffff);
  immutable Color Magenta   = Color(0xffff00ff);
  immutable Color Orange    = Color(0xffffa500);

  @property string toString() const {
    version (VERBOSE) {
      return "Color a: " ~ to!string(this.a) ~
        " r: " ~ to!string(this.r) ~
        " g: " ~ to!string(this.g) ~
        " b: " ~ to!string(this.b);
    } else {
      auto ret = "0x" ~ toHexDigit(this.a) ~ toHexDigit(this.r)
        ~ toHexDigit(this.g) ~ toHexDigit(this.b);
      return ret.idup;
    }
  }

  unittest {
    assert(color("00000001").argb == 1);
    assert(color("80000000").argb == (1u << 31));
    const uint exp = 10u * (1<<28) + 10u * (1<<24) + 11u * (1<<20) + 11u * (1<<16)
      + 12u * (1<<12) + 12u * (1<<8) + 13u * (1<<4) + 13u;
    assert(color("AABBCCDD").argb == exp);
  }

  @property bool opaque() const {
    return this.a == 255;
  }

  @property Color complement() const {
    return color(a, cast(ubyte)(255 - r), cast(ubyte)(255 - g), cast(ubyte)(255 - b));
  }

  const Color opBinary(string op)(Color rhs) const
    if (op == "+") {
      return color(this.argb + rhs.argb);
  }

  mixin SetGet!("a");
  mixin SetGet!("r");
  mixin SetGet!("g");
  mixin SetGet!("b");

private:
  mixin template SetGet(string s)
  {
    mixin("@property ubyte "~s~"() const { return get!('"~s~"'); }");
    mixin("@property ref Color "~s~"(ubyte v) { return set!('"~s~"')(v); }");
  }

  ref Color set(char m)(ubyte val)
  {
    static const KShift = Shift!(m);
    this.argb = this.argb & ~(0xff << KShift) | (val << KShift);
    return this;
  }

  const(ubyte) get(char m)() const {
    static const KShift = Shift!(m);
    return this.argb >> KShift & 0xff;
  }
}

unittest
{
  Color c;
  c.a = 10;
  c.r = 20;
  c.g = 30;
  c.b = 40;
  auto ShiftVal = (10 << 24) | (20 << 16) | (30 << 8) | (40 << 0);
  assert(c.argb == ShiftVal);
  assert(Color.Black.a == 255 && Color.Black.r == 0 && Color.Black.g == 0 && Color.Black.b == 0);
  assert(Color.Red.r == 255);
  assert(Color.Green.g == 255);
  assert(Color.Blue.b == 255);
  assert(Color.Magenta.g == 0);
}

Color color(uint argb) {
  Color res;
  res.argb = argb;
  return res;
}

Color color(ubyte a, ubyte r, ubyte g, ubyte b) {
  Color res;
  res.a = a;
  res.r = r;
  res.g = g;
  res.b = b;
  return res;
}

Color color(string colorCode) {
  colorCode = strip(colorCode).toUpper();
  if (colorCode.startsWith("0X"))
    colorCode = colorCode[2 .. $];
  else if (colorCode.startsWith("#"))
    colorCode = colorCode[1 .. $];

  enforce(colorCode.length);

  if (std.ascii.isHexDigit(colorCode[0])) {
    uint argb;
    switch (colorCode.length) {
    case 8:
      argb = cast(uint)reduce!("(a << 4) | b")(0, map!fromHexDigit(colorCode));
      break;
    case 6:
      argb = cast(uint)(
          (0xFF << 24) | reduce!("(a << 4) | b")(0, map!fromHexDigit(colorCode)));
      break;
    case 4:
      argb = cast(uint)(
          reduce!("(a << 8) | (b << 4 | b)")(0, map!fromHexDigit(colorCode)));
      break;
    case 3:
      argb = cast(uint)(
          (0xFF << 24) | reduce!("(a << 8) | (b << 4 | b)")(0, map!fromHexDigit(colorCode)));
      break;

    default:
      enforce(0);
    }
    return Color(argb);
  } else if (colorCode.startsWith("RGB(")) {
    enforce(colorCode.endsWith(")"));
    auto triple = colorCode[4 .. $-1].split(",");
    enforce(triple.length == 3);

    ubyte r, g, b;
    if (strip(triple[0]).endsWith("%")) {
      r = to!ubyte(to!uint(strip(triple[0])[0 .. $-1]) * 255 / 100);
      g = to!ubyte(to!uint(strip(triple[1])[0 .. $-1]) * 255 / 100);
      b = to!ubyte(to!uint(strip(triple[2])[0 .. $-1]) * 255 / 100);
    } else {
      r = to!ubyte(strip(triple[0]));
      g = to!ubyte(strip(triple[1]));
      b = to!ubyte(strip(triple[2]));
      return color(0xFF, r, g, b);
    }
    return color(0xFF, r, g, b);
  } else {
    assert(isAlpha(colorCode[0]));
//    need to make the named color enum scoped
//    auto capCol = capitalize(colorCode);
//    foreach(c; __traits(allMembers, Color))
//      if (colorCode == c) {
//        return mixin("Color." ~ c);
//      }
  }
  assert(0, colorCode);
}

package:

template ColorMask(string s) {
  static assert(s.length <=4 && s.length > 0);
  enum ColorMask = StringToMask!(s);
}

template StringToMask(string s) {
  static if (s.length)
    enum StringToMask = (0xFF << Shift!(s[0])) | StringToMask!(s[1..$]);
  else
    enum StringToMask = 0;
}

template Shift(char m) {
  static if (m == 'a')
    enum Shift = 24;
  else static if (m == 'r')
    enum Shift = 16;
  else static if (m == 'g')
    enum Shift = 8;
  else static if (m == 'b')
    enum Shift = 0;
}

unittest {
  static assert(ColorMask!("rb") == 0x00ff00ff);
  static assert(ColorMask!("ab") == 0xff0000ff);
  static assert(ColorMask!("ag") == 0xff00ff00);
}


enum hexLetters = "0123456789ABCDEF";

public uint fromHexDigit(dchar c) {
  assert(isHexDigit(c));
  return c <= '9' ? (c & 0xF) : 9 + (c & 0xF);
}

char[2] toHexDigit(ubyte n) {
  return [hexLetters[(n >> 4) & 0xF], hexLetters[n & 0xF]];
}
