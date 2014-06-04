module guip.bitmap;

import core.atomic;
import std.conv, std.exception, std.string, std.range;
import guip.color, guip.rect, guip.size;

/*
 * Bitmap
 */
struct Bitmap
{
    enum Config
    {
        NoConfig,   //!< Empty default
        A8,         //!< 8-bits per pixel, with only alpha specified (0 is transparent, 0xFF is opaque)
        ARGB_8888,  //!< 32-bits per pixel
    };

private:
    uint _width;
    uint _height;
    Config _config;
    ubyte _flags;
    ubyte[] _buffer;

public:

    this(Config config, uint width, uint height)
    {
        setConfig(config, width, height);
    }

    void setConfig(Bitmap.Config config, uint width, uint height, ubyte[] buf=null)
    {
        _width  = width;
        _height = height;
        _config = config;
        if (buf !is null)
            buffer = buf;
        else
            _buffer.length = width * height * BytesPerPixel(config);
    }

    @property uint width() const
    {
        return _width;
    }

    @property uint height() const
    {
        return _height;
    }

    @property ISize size() const
    {
        return ISize(_width, _height);
    }

    @property IRect bounds() const
    {
        return IRect(size);
    }

    @property Config config() const
    {
        return _config;
    }

    @property inout(ubyte)[] buffer() inout
    {
        return _buffer[];
    }

    @property void buffer(ubyte[] buffer)
    in
    {
        assert(buffer.length >= width * height * BytesPerPixel(config));
    }
    body
    {
        _buffer = buffer;
    }

    inout(T)[] getBuffer(T=Color)() inout
    {
        return cast(inout(T)[])_buffer;
    }

    inout(T)[] getLine(T=Color)(uint y) inout
    {
        immutable off = y * _width;
        return getBuffer!T()[off .. off + _width];
    }

    inout(T)[] getRange(T=Color)(uint xstart, uint xend, uint y) inout
    in
    {
        assert(xend <= _width);
    }
    body
    {
        immutable off = y * _width;
        return getBuffer!T()[off + xstart .. off + xend];
    }


    @property void opaque(bool isOpaque)
    {
        if (isOpaque)
        {
            _flags |= Flags.opaque;
        }
        else
        {
            _flags &= ~Flags.opaque;
        }
    }

    @property bool opaque() const
    {
        return !!(_flags & Flags.opaque);
    }

    void eraseColor(Color c)
    {
        assert(_config == Bitmap.Config.ARGB_8888);
        getBuffer!Color()[] = c;
    }

    void save(string path) const
    {
        assert(0, "unimplemented");
    }

    static Bitmap load(string path)
    {
        assert(0, "unimplemented");
    }

private:

    enum Flags
    {
        opaque = 1 << 0,
    }
}

uint BytesPerPixel(Bitmap.Config c)
{
    final switch (c)
    {
    case Bitmap.Config.NoConfig:
        return 0;
    case Bitmap.Config.A8:
        return 1;
    case Bitmap.Config.ARGB_8888:
        return 4;
    }
}
