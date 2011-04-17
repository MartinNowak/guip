module guip.event;

import std.bitmanip, std.conv, std.typetuple, std.variant;
import guip.point, guip.rect;

/**
   TypeTuple that contains all available events
 */
alias TypeTuple!(StateEvent, ButtonEvent, MouseEvent, KeyEvent, RedrawEvent, ResizeEvent) EventTypes;

/**
   Algebraic type that may contains any available event
 */
alias Algebraic!(EventTypes) Event;

/**
   dispatch helper for algebraic event
 */
auto visitEvent(Visitor, Args...)(Event e, Visitor visitor, Args args) {
  foreach(T; EventTypes) {
    static if(is(typeof(visitor.visit(e.get!(T), args)))) {
      if (auto v = e.peek!T)
        return visitor.visit(*v, args);
    }
  }
  static if (!is(typeof(return) == void)) {
    assert(0, "unhandled event with expected return " ~ to!string(e));
  }
}

/**
   mouse button event
 */
struct ButtonEvent {
  @property bool isPress() const {
    return this.isdown;
  }
  @property bool isRelease() const {
    return !this.isdown;
  }
  IPoint pos;
  bool isdown;
  Button button;
  Mod mod;
}

/**
   mouse move event
 */
struct MouseEvent {
  IPoint pos;
  Button button;
  Mod mod;
}

/**
   key press event
 */
struct KeyEvent {
  @property bool isPress() const {
    return this.isdown;
  }
  @property bool isRelease() const {
    return !this.isdown;
  }
  IPoint pos;
  bool isdown;
  Key key;
  Mod mod;
}

/**
   window state change event
 */
struct StateEvent {
  bool visible, focus;
}

/**
   window damage event
 */
struct RedrawEvent {
  IRect area;
}

/**
   window resize event
 */
struct ResizeEvent {
  IRect area;
}

/**
   a bitfield representing pressed buttons
 */
struct Button {
  @property bool any() const {
    return this.left || this.middle || this.right;
  }

  mixin(bitfields!(
          bool, "left", 1,
          bool, "middle", 1,
          bool, "right", 1,
          uint, "", 5));
}

/**
   a bitfield representing pressed modifiers
 */
struct Mod {
  mixin(bitfields!(
          bool, "shift", 1,
          bool, "ctrl", 1,
          bool, "alt", 1,
          bool, "numlock", 1,
          uint, "", 4));
}

/**
   translates a key to it's corresponding character
 */
struct Key {
  uint num;
  @property dchar character() const {
    return cast(dchar)this.num;
  }
}
