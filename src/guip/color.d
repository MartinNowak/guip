module guip.color;

private {
  import std.conv : to;
  import std.algorithm;
  import std.string : toupper;
  import std.ctype : isxdigit;
}

//version=VERBOSE;

struct Color
{
  uint argb;

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
  this(uint argb) {
    this.argb = argb;
  }

  this(string argbHex) {
    argbHex = argbHex.toupper();
    if (argbHex.startsWith("0X")) {
      argbHex = argbHex[2 .. $];
    }
    assert(argbHex.length == 8);
    this.argb = cast(uint)reduce!("(a << 4) + b")(
      0, map!fromHexDigit(argbHex));
  }

  unittest {
    auto argbHex = "80000000";
    assert(Color("00000001").argb == 1);
    assert(Color("80000000").argb == (1u << 31));
    const uint exp = 10u * (1<<28) + 10u * (1<<24) + 11u * (1<<20) + 11u * (1<<16)
      + 12u * (1<<12) + 12u * (1<<8) + 13u * (1<<4) + 13u;
    assert(Color("AABBCCDD").argb == exp);
  }

  this(ubyte a, ubyte r, ubyte g, ubyte b) {
    this.a = a;
    this.r = r;
    this.g = g;
    this.b = b;
  }

  const Color opBinary(string op)(Color rhs) const
    if (op == "+") {
      return Color(this.argb + rhs.argb);
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


enum : Color
{
  Black     = Color(0xff000000),
  DarkGray  = Color(0xff444444),
  Gray      = Color(0xff888888),
  LightGray = Color(0xffcccccc),
  WarmGray  = Color(0xffaab2b7),
  ColdGray  = Color(0xff67748c),
  White     = Color(0xffffffff),
  Red       = Color(0xffff0000),
  Green     = Color(0xff00ff00),
  Blue      = Color(0xff0000ff),
  Yellow    = Color(0xffffff00),
  Cyan      = Color(0xff00ffff),
  Magenta   = Color(0xffff00ff),
  Orange    = Color(0xffffa500),
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
  assert(Black.a == 255 && Black.r == 0 && Black.g == 0 && Black.b == 0);
  assert(Red.r == 255);
  assert(Green.g == 255);
  assert(Blue.b == 255);
  assert(Magenta.g == 0);
}

private:

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
  assert(isxdigit(c));
  return c <= '9' ? (c & 0xF) : 9 + (c & 0xF);
}

char[2] toHexDigit(ubyte n) {
  return [hexLetters[(n >> 4) & 0xF], hexLetters[n & 0xF]];
}
