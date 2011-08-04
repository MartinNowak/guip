module guip.event;

import std.bitmanip, std.conv, std.typetuple, std.variant;
import guip.point, guip.rect;

/**
   TypeTuple that contains all available events
 */
alias TypeTuple!(StateEvent, ButtonEvent, MouseEvent, KeyEvent,
                 RedrawEvent, ResizeEvent, DragEvent, DropEvent) EventTypes;

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
    return this.isdown && !this.isdouble;
  }
  @property bool isRelease() const {
    return !this.isdown && !this.isdouble;
  }
  @property bool isDoublePress() const {
    return this.isdown && this.isdouble;
  }
  @property bool isDoubleRelease() const {
    return !this.isdown && this.isdouble;
  }
  IPoint pos;
  Button button;
  Mod mod;
  mixin(bitfields!(
            bool, "isdown", 1,
            bool, "isdouble", 1,
            uint, "", 6));
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
  Key key;
  Mod mod;
  bool isdown;
}

/**
   visibility change event
 */
struct VisibilityEvent {
  bool visible;
}

/**
   focus change event
*/
struct FocusEvent {
  bool focus;
}

/**
   attribute change event
 */
struct AttributeEvent {
  string key, value;
}

alias Algebraic!(VisibilityEvent, FocusEvent, AttributeEvent) StateEvent;

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
  files drag event
*/
struct DragEvent {
  IPoint pos;
  string[] files;
}

/**
  files drop event
*/
struct DropEvent {
  IPoint pos;
  string[] files;
}

/**
   a bitfield representing pressed buttons
 */
struct Button {
  @property bool any() const {
    return this.left || this.middle || this.right || this.wheelup || this.wheeldown;
  }

  mixin(bitfields!(
          bool, "left", 1,
          bool, "middle", 1,
          bool, "right", 1,
          bool, "wheelup", 1,
          bool, "wheeldown", 1,
          uint, "", 3));
}

/**
   a bitfield representing pressed modifiers
 */
struct Mod {
  @property bool any() const {
    return this.shift || this.ctrl || this.alt;
  }

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
