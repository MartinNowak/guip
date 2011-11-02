module guip.color;

import std.algorithm, std.array, std.ascii, std.exception, std.string, std.traits, std.conv;

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

    @property string toString() const
    {
        version (VERBOSE) {
            return "Color a: " ~ to!string(this.a) ~
                " r: " ~ to!string(this.r) ~
                " g: " ~ to!string(this.g) ~
                " b: " ~ to!string(this.b);
        }
        else
        {
            auto ret = "0x" ~ toHexDigit(this.a) ~ toHexDigit(this.r)
                ~ toHexDigit(this.g) ~ toHexDigit(this.b);
            return ret.idup;
        }
    }

    @property bool opaque() const
    {
        return this.a == 255;
    }

    @property Color complement() const
    {
        return color(a, cast(ubyte)(255 - r), cast(ubyte)(255 - g), cast(ubyte)(255 - b));
    }

    const Color opBinary(string op)(Color rhs) const if (op == "+")
    {
        return color(this.argb + rhs.argb);
    }

    private @property ref Color set(char m)(ubyte val)
    {
        static const KShift = Shift!(m);
        this.argb = this.argb & ~(0xff << KShift) | (val << KShift);
        return this;
    }

    private @property const(ubyte) get(char m)() const
    {
        static const KShift = Shift!(m);
        return this.argb >> KShift & 0xff;
    }

    alias get!'a' a;
    alias set!'a' a;
    alias get!'r' r;
    alias set!'r' r;
    alias get!'g' g;
    alias set!'g' g;
    alias get!'b' b;
    alias set!'b' b;
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

Color color(uint argb)
{
    Color res;
    res.argb = argb;
    return res;
}

Color color(ubyte a, ubyte r, ubyte g, ubyte b)
{
    Color res;
    res.a = a;
    res.r = r;
    res.g = g;
    res.b = b;
    return res;
}

/*
 * Construct a color given a valid CSS color string.
 */
Color color(string colorCode)
{
    auto cclow = strip(colorCode).toLower();
    bool ishex;
    if (cclow.startsWith("0x"))
    {
        ishex = true;
        cclow = cclow[2 .. $];
    }
    else if (colorCode.startsWith("#"))
    {
        ishex = true;
        cclow = cclow[1 .. $];
    }

    enforce(cclow.length &&
            !ishex || std.ascii.isHexDigit(cclow[0]));

    if (ishex)
    {
    LHexAgain:
        uint argb;
        switch (cclow.length)
        {
        case 8:
            argb = cast(uint)reduce!("(a << 4) | b")(0, map!fromHexDigit(cclow));
            break;
        case 6:
            argb = cast(uint)(
                (0xFF << 24) | reduce!("(a << 4) | b")(0, map!fromHexDigit(cclow)));
            break;
        case 4:
            argb = cast(uint)(
                reduce!("(a << 8) | (b << 4 | b)")(0, map!fromHexDigit(cclow)));
            break;
        case 3:
            argb = cast(uint)(
                (0xFF << 24) | reduce!("(a << 8) | (b << 4 | b)")(0, map!fromHexDigit(cclow)));
            break;

        default:
            goto Lerr;
        }
        return Color(argb);
    }
    else if (cclow.startsWith("rgb("))
    {
        enforce(cclow.endsWith(")"));
        auto triple = cclow[4 .. $-1].split(",");
        enforce(triple.length == 3);

        ubyte r, g, b;
        if (strip(triple[0]).endsWith("%"))
        {
            r = to!ubyte(to!uint(strip(triple[0])[0 .. $-1]) * 255 / 100);
            g = to!ubyte(to!uint(strip(triple[1])[0 .. $-1]) * 255 / 100);
            b = to!ubyte(to!uint(strip(triple[2])[0 .. $-1]) * 255 / 100);
        }
        else
        {
            r = to!ubyte(strip(triple[0]));
            g = to!ubyte(strip(triple[1]));
            b = to!ubyte(strip(triple[2]));
            return color(0xFF, r, g, b);
        }
        return color(0xFF, r, g, b);
    }
    else
    {
        switch (cclow)
        {
            foreach(c; __traits(allMembers, Color))
            {
                static if (is(typeof(mixin("Color."~c)) : immutable(Color))
                           && !isCallable!(mixin("Color."~c)))
                {
                case c.toLower():
                    return mixin("Color."~c);
                }
            }

        default:
            // probably hex without prefix
            if (isHexDigit(cclow.front))
            {
                goto LHexAgain;
            }
        }
    }
 Lerr:
    assert(0, std.string.format("Failed to parse color spec %s.", colorCode));
}

unittest
{
    assert(color("0x000") == Color.Black);
    assert(color("0x000000") == Color.Black);
    assert(color("#000") == Color.Black);
    assert(color("#000000") == Color.Black);
    assert(color("000000") == Color.Black);
    assert(color("black") == Color.Black);
    assert(color("Black") == Color.Black);
    assert(color("BLACK") == Color.Black);
    assert(color("orange") == Color.Orange);
    assert(color("#f00") == Color.Red);
    assert(color("#0F0") == Color.Green);
    assert(color("0000FF") == Color.Blue);
    assert(color("0xFF00FF") == Color.Magenta);

    assert(color("00000001").argb == 1);
    assert(color("80000000").argb == (1u << 31));
    const uint exp = 10u * (1<<28) + 10u * (1<<24) + 11u * (1<<20) + 11u * (1<<16)
        + 12u * (1<<12) + 12u * (1<<8) + 13u * (1<<4) + 13u;
    assert(color("AABBCCDD").argb == exp);
}

package:

template ColorMask(string s)
{
    static assert(s.length <=4 && s.length > 0);
    enum ColorMask = StringToMask!(s);
}

template StringToMask(string s)
{
    static if (s.length)
        enum StringToMask = (0xFF << Shift!(s[0])) | StringToMask!(s[1..$]);
    else
    enum StringToMask = 0;
}

template Shift(char m)
{
    static if (m == 'a')
        enum Shift = 24;
    else static if (m == 'r')
        enum Shift = 16;
    else static if (m == 'g')
        enum Shift = 8;
    else static if (m == 'b')
        enum Shift = 0;
}

unittest
{
    static assert(ColorMask!("rb") == 0x00ff00ff);
    static assert(ColorMask!("ab") == 0xff0000ff);
    static assert(ColorMask!("ag") == 0xff00ff00);
}

enum hexLetters = "0123456789abcdef";

public uint fromHexDigit(dchar c)
{
    assert(isHexDigit(c));
    return c <= '9' ? (c & 0xF) : 9 + (c & 0xF);
}

char[2] toHexDigit(ubyte n)
{
    char[2] res = void;
    res[0] = hexLetters[(n >> 4) & 0xF];
    res[1] = hexLetters[n & 0xF];
    return res;
}
