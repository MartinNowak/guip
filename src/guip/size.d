module guip.size;

import std.conv, std.string;

alias Size!(int) ISize;
alias Size!(float) FSize;

struct Size(T)
{
private:
    T _width, _height;

public:

    @property T width() const
    {
        return _width;
    }

    @property void width(T width)
    {
        _width = width;
    }

    @property T height() const
    {
        return _height;
    }

    @property void height(T height)
    {
        _height = height;
    }

    string toString() const
    {
        return std.string.format("S(%s, %s)", width, height);
    }

    string toString()
    {
        return std.string.format("S(%s, %s)", width, height);
    }

    @property bool empty() const
    {
        return _width <= 0 || _height <= 0;
    }

    /* Returns a new size whose width/height is multiplied/divided by
     * the scalar.
     */
    const Size opBinary(string op)(in T val) if (op == "*" || op == "/")
    {
        debug
            return Size(to!T(_width * val), to!T(_height * val));
        else
            return Size(cast(T)(_width * val), cast(T)(_height * val));
    }
}
