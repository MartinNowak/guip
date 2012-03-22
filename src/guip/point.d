module guip.point;

import std.conv, std.math, std.string, std.traits;
import guip.size;

alias Point!(int) IPoint;
alias Point!(float) FPoint;

alias Point Vector;
alias Vector!float FVector;
alias Vector!double DVector;

/*
 * Template deducing function.
 */
Point!T point(T)(T x, T y)
{
    return Point!T(x, y);
}

deprecated FPoint fPoint()()
{
    return FPoint();
}

FPoint fPoint(T)(Point!T pt)
{
    return FPoint(pt.x, pt.y);
}

struct Point (T)
{
    T _x=0, _y=0;

    string toString()
    {
        return (cast(const)this).toString();
    }

    string toString() const
    {
        return std.string.format("P(%s, %s)", x, y);
    }

    alias _x x;
    alias _y y;

    /* Set the point's X and Y coordinates
     */
    deprecated void set(T x, T y)
    {
        this = Point(x, y);
    }

    /* Return the euclidian distance from (0,0) to the point
     */
    @property double length() const
    {
        return sqrt(cast(double)(_x ^^2 + _y ^^ 2));
    }

    /* Set the point (vector) to be unit-length in the same direction
     * as it currently is, and return its old length. If the old
     * length is degenerately small (nearly zero), do nothing and
     * return false, otherwise return true.
     */
    deprecated void normalize()
    {
        this = normalized();
    }

    @property Point normalized()
    {
        return scaledTo(1);
    }

    /* Set the point (vector) to be unit-length in the same direction as the
     * x,y parameters.
     */
    deprecated void setNormalize(Point pt)
    {
        this = pt.normalized();
    }

    deprecated void setNormalize(T x, T y)
    {
        setNormalize(Point(x, y));
    }

    /* Scale the point (vector) to have the specified length, and return that
     * length.
     */
    deprecated void setLength(T nlength)
    {
        scale(nlength / length);
    }

    /* Set the point (vector) to have the specified length in the same
     * direction as (x,y).
     */
    deprecated void setLength(T x, T y, T nlength)
    {
        set(x, y);
        setLength(nlength);
    }

    /* Scale the point's coordinates by scale, writing the answer into dst.
     */
    deprecated void scale(T2)(T2 by, ref Point dst) const
    {
        dst = scaledBy(by);
    }

    /* Scale the point's coordinates by scale, writing the answer back into
     * the point.
     */
    deprecated void scale(T2)(T2 by)
    {
        this = scaledBy(by);
    }

    Point scaledBy(T2)(T2 by) const
    {
        debug
            return Point(to!T(_x * by), to!T(_y * by));
        else
            return Point(cast(T)(_x * by), cast(T)(_y * by));
    }

    /*
     * Returns a point with the same direction but a length of $(D_Param nlength).
     */
    Point scaledTo(T2)(T2 nlength) const
    {
        return scaledBy(nlength / length);
    }

    static if (isSigned!T)
    {

        /* Rotate the point clockwise by 90 degrees, writing the answer into dst.
         */
        deprecated void rotateCW(ref Point dst) const
        {
            dst = rotatedCW();
        }

        /* Rotate the point clockwise by 90 degrees, writing the answer back into
         * the point.
         */
        deprecated void rotateCW()
        {
            this = rotatedCW();
        }

        Point rotatedCW() const
        {
            return Point(-_y, _x);
        }

        /* Returns a point rotated counter-clockwise by 90 degrees.
         */
        Point rotatedCCW() const
        {
            return Point(_y, -_x);
        }

        deprecated void rotateCCW(out Point dst) const
        {
            dst = rotatedCCW();
        }

        /* Rotate the point counter-clockwise by 90 degrees, writing the answer
         * back into the point.
         */
        deprecated void rotateCCW()
        {
            this = rotatedCCW();
        }

        /* Negate the point's coordinates
         */
        Point opUnary(string op)() const if (op == "-")
        {
            return Point(-_x, -_y);
        }

        deprecated void negate()
        {
            this = -this;
        }
    }

    static if (isFloatingPoint!T)
    {
        /* Round to integer point using nearbyint.
         */
        deprecated alias rounded round;

        IPoint rounded() const
        {
            debug
                return IPoint(to!int(nearbyint(_x)), to!int(nearbyint(_y)));
            else
                return IPoint(cast(int)(nearbyint(_x)), cast(int)(nearbyint(_y)));
        }
    }


    /* Returns a new point whose coordinates are the difference/sum
     * between a's and b's (a -/+ b).
     */
    Point opBinary(string op)(in Point rhs) const
    {
        debug
            return Point(to!T(mixin(`_x `~op~`rhs._x`)), to!T(mixin(`_y `~op~`rhs._y`)));
        else
            return Point(cast(T)mixin(`_x `~op~`rhs._x`), cast(T)mixin(`_y `~op~`rhs._y`));
    }

    /* Returns a new point whose coordinates is multiplied/divided by
     * the scalar.
     */
    Point opBinary(string op)(in T val) const
    {
        debug
            return Point(to!T(mixin(`_x `~op~`val`)), to!T(mixin(`_y `~op~`val`)));
        else
            return Point(cast(T)mixin(`_x `~op~`val`), cast(T)mixin(`_y `~op~`val`));
    }

    Point opBinaryRight(string op)(in T val) const if(op != "/")
    {
        return opBinary!(op)(val);
    }

    Point opBinary(string op)(in Size!T size) const if (op == "-" || op == "+")
    {
        debug
            return Point(to!T(mixin(`_x `~op~`size.width`)), to!T(mixin(`_y `~op~`size.height`)));
        else
            return Point(cast(T)mixin(`_x `~op~`size.width`), cast(T)mixin(`_y `~op~`size.height`));
    }

    ref Point opOpAssign(string op)(in Point rhs)
    {
        mixin(`_x`~op~`=rhs._x;`);
        mixin(`_y`~op~`=rhs._y;`);
        return this;
    }

    ref Point opOpAssign(string op)(in T val)
    {
        mixin("_x" ~ op ~ "=val;");
        mixin("_y" ~ op ~ "=val;");
        return this;
    }

    static if (isFloatingPoint!T)
    {
        bool approxEqual(T x, T y) const
        {
            return .approxEqual(_x, x)
                && .approxEqual(_y, y);
        }

        bool approxEqual(in Point rhs) const
        {
            return approxEqual(rhs._x, rhs._y);
        }
    }

    static if (isFloatingPoint!T)
    {
        invariant()
        {
            assert(isFinite(_x) && !isSubnormal(_x) &&
                   isFinite(_y) && !isSubnormal(_y));
        }
    }
};

/* Returns the euclidian distance between a and b
 */
double distance(T)(Point!T a, Point!T b) if (isFloatingPoint!T)
{
    return sqrt(cast(double)((a._x - b._x) ^^ 2 + (a._y - b._y) ^^ 2));
}

double distance(T)(Point!T a, Point!T b) if (isIntegral!T)
{
    return sqrt(cast(double)((a._x - b._x) ^^ 2 + (a._y - b._y) ^^ 2));
}

/* Returns the dot product of a and b, treating them as 2D column vectors
 */
T dotProduct(T)(Point!T a, Point!T b)
{
    debug
        return to!T(a.x * b.x + a.y * b.y);
    else
        return cast(T)(a.x * b.x + a.y * b.y);
}

/* Returns the cross product of a and b, treating them as 2D column vectors
 */
T determinant(T)(in Point!T a, in Point!T b) // TODO: benchmark ref const vs. in
{
    debug
        return to!T(a.x * b.y - a.y * b.x);
    else
        return cast(T)(a.x * b.y - a.y * b.x);
}

unittest
{
    import std.typetuple;

    alias TypeTuple!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real) Types;

    foreach(T; Types)
    {
        testPointCoordinates!T();
        testVectorLength!T();

        static if (isSigned!T)
        {
            testVectorDirection!T();
            testVectorOps!T();
        }
    }
}

void testPointCoordinates(T)()
{
    auto p1 = Point!T(10, 20);
    assert(p1.x == 10);
    assert(p1.y == 20);
    p1 = Point!T(5, 5);
    assert(p1.x == 5);
    assert(p1.y == 5);
    p1 = Point!T(4, 3);
    assert(p1.x == 4);
    assert(p1.y == 3);
    p1 = Point!T(3, 4);
    assert(p1.x == 3);
    assert(p1.y == 4);

    auto p2 = Point!T(5, 5);
    p1 = p2;
    assert(p1.x == 5);
    assert(p1.y == 5);

    auto p3 = p1 + p2;
    assert(p3.x == 10);
    assert(p3.y == 10);
    p3 += p1;
    assert(p3.x == 15);
    assert(p3.y == 15);
}

void testVectorLength(T)()
{
    auto p1 = Point!T(3, 4);
    auto p2 = p1;
    assert(p1.length() == 5);
    assert(p1.length() == p2.length());

    p1 = Point!T(5, 5);
    p1 = p1.normalized;
    assert(approxEqual(p1.x, to!T(std.math.sqrt(0.5))));
    assert(approxEqual(p1.y, to!T(std.math.sqrt(0.5))));

    p1 = Point!T(1, 1);
    p1 = p1.scaledTo(4);
    assert(approxEqual(p1.x, to!T(2 * SQRT2)));
    assert(approxEqual(p1.y, to!T(2 * SQRT2)));

    p2 = p1.scaledBy(SQRT2);
    assert(approxEqual(p2.x, to!T(p1.x * SQRT2)));
    assert(approxEqual(p2.y, to!T(p1.y * SQRT2)));

    p1 = p2.scaledBy(0.5);
    assert(approxEqual(p1.x, to!T(p2.x * 0.5)));
    assert(approxEqual(p1.y, to!T(p2.y * 0.5)));

    p1 = Point!T(3, 3);
    p2 = Point!T(6, 7);
    assert(distance(p1, p2) == 5);
    assert(distance(p2, p1) == 5);
}

void testVectorDirection(T)()
{
    // Rotation works on an y-axis inverted space
    auto p1 = Point!T(2, 1);
    auto p2 = p1;
    p2 = p2.rotatedCW();
    assert(p2.x == -1);
    assert(p2.y == 2);

    p2 = p1;
    p2 = p2.rotatedCCW();
    assert(p2.x == 1);
    assert(p2.y == -2);

    // TODO: add random test p.rotateCCW().rotateCW() == p

    assert(-p1.x == -2);
    assert(-p1.y == -1);
    assert(p1.x == 2);
    assert(p1.y == 1);
    p1 = -p1;
    assert(p1.x == -2);
    assert(p1.y == -1);
}

void testVectorOps(T)()
{
    auto p1 = Point!T(2, 1);
    auto p2 = -p1;
    assert(dotProduct(p1, p2) == -5);

    assert(determinant(p1, p2) == 0);
    auto pCW = p1;
    pCW = pCW.rotatedCW();
    auto pCCW = p1;
    pCCW = pCCW.rotatedCCW();
    assert(determinant(p1, pCW) == -(determinant(p1, pCCW)));
    assert(dotProduct(p1, pCW) == 0);
}
