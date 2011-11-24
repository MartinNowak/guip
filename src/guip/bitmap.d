module guip.bitmap;

import core.atomic;
import std.conv, std.exception, std.string, std.range;
import guip.color, guip.rect, guip.size;
import freeimage.freeimage;

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
        auto bpp = 8 * BytesPerPixel(_config);
        if (bpp != 0)
        {
            synchronized(freeImage)
            {
                FIBITMAP* fibmp;
                // TODO: check if color masks needed
                if (_config == Bitmap.Config.ARGB_8888)
                {
                    fibmp = FreeImage_Allocate(_width, _height, bpp,
                                               ColorMask!("r"), ColorMask!("g"), ColorMask!("b"));
                }
                else
                {
                    fibmp = FreeImage_Allocate(_width, _height, bpp);
                }
                enforce(fibmp, "error while allocating write image");
                ubyte* deviceBits = FreeImage_GetBits(fibmp);
                deviceBits[0 .. _buffer.length] = _buffer[];
                // TODO: possible to avoid flipping
                FreeImage_FlipVertical(fibmp);
                FreeImage_Save(FREE_IMAGE_FORMAT.PNG, fibmp, toStringz(path));

                FreeImage_Unload(fibmp);
            }
        }
    }

    static Bitmap load(string path)
    {
        Bitmap result;
        synchronized(freeImage)
        {
            immutable cpath = toStringz(path);
            FREE_IMAGE_FORMAT fmt = FreeImage_GetFileType(cpath);

            if (fmt == FREE_IMAGE_FORMAT.UNKNOWN)
                fmt = FreeImage_GetFIFFromFilename(cpath);

            enforce(fmt != FREE_IMAGE_FORMAT.UNKNOWN && FreeImage_FIFSupportsReading(fmt),
                    format("Unsupported image format %s.", path));

            FIBITMAP* fibmp = enforce(FreeImage_Load(fmt, cpath),
                                      format("Error while decoding %s.", path));
            // TODO: possible to avoid flipping
            FreeImage_FlipVertical(fibmp);

            Config config;
            auto bpp = FreeImage_GetBPP(fibmp);
            switch (bpp)
            {
            case 8:
                // TODO: check for palettized color images
                config = Config.A8;
                break;

            case 48: // for now
            case 64: // for now
            case 24:
                auto cpy = FreeImage_ConvertTo32Bits(fibmp);
                FreeImage_Unload(fibmp);
                fibmp = cpy;
                bpp = 32;
                goto case;

            case 32:
                config = Config.ARGB_8888;
                break;

            default:
                assert(0, format("Unsupported bit depth %s for image %s.", bpp, path));
            }

            immutable w = FreeImage_GetWidth(fibmp);
            immutable h = FreeImage_GetHeight(fibmp);
            result.setConfig(config, w, h);
            immutable nbytes =  (w * h * bpp) >> 3;
            ubyte* bits = FreeImage_GetBits(fibmp);
            result._buffer[] = bits[0 .. nbytes];

            FreeImage_Unload(fibmp);
        }
        return result;
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

// TODO: move freeimage functions into class so they are protected by a lock
synchronized class FreeImage
{
    void init()
    {
    }
};

shared FreeImage _freeImage;
@property shared(FreeImage) freeImage()
{
    if (_freeImage is null)
    {
        auto inst = new shared(FreeImage)();
        synchronized(inst)
        {
            if (cas(&_freeImage, cast(shared FreeImage)null, inst))
                inst.init();
        }
    }
    return _freeImage;
}
