module guip.bitmap;

import core.atomic;
import std.conv, std.exception, std.string, std.range;
import gamut;
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
        assert(_config == Bitmap.Config.ARGB_8888);
        if (_width == 0 || _height == 0)
            throw new Exception("Cannot save an empty Bitmap.");

        Image image;
        image.createView(cast(void*)_buffer.ptr, to!int(_width), to!int(_height),
                         PixelType.rgba8, to!int(_width) * 4);
        image.setLayout(LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT);
        auto tmp = cast(uint[])_buffer;
        argbToRgba(tmp);
        if (!image.saveToFile(path))
            throw new Exception("Failed to save image to `" ~ path
                                 ~ "`: " ~ image.errorMessage().idup);
        rgbaToArgb(tmp);
    }

    static Bitmap load(string path)
    {
        Image image;
        if (!image.loadFromFile(path, LOAD_RGB | LOAD_ALPHA | LOAD_8BIT | LOAD_NO_PREMUL
                                 | LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT))
            throw new Exception("Failed to load image from `" ~ path
                                 ~ "`: " ~ image.errorMessage().idup);

        Bitmap bmp;
        bmp.setConfig(Config.ARGB_8888, to!uint(image.width()), to!uint(image.height()), image.allPixelsAtOnce());
        auto tmp = cast(uint[])bmp._buffer;
        rgbaToArgb(tmp);
        return bmp;
    }

private:

    enum Flags
    {
        opaque = 1 << 0,
    }
}

private void argbToRgba(ref uint[] buffer)
{
    import core.bitop : bswap;
    foreach (ref e; buffer) {
        // 0xAARRGGBB → 0xRRGGBBAA → byte-order swap
        e = (e >> 24) | (e << 8);
        version (LittleEndian)
            e = bswap(e);
    }
}

private void rgbaToArgb(ref uint[] buffer)
{
    import core.bitop : bswap;
    foreach (ref e; buffer) {
        version (LittleEndian)
            e = bswap(e);
        // 0xRRGGBBAA → 0xAARRGGBB
        e = (e << 24) | (e >> 8);
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
