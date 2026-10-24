// The patterns are compared with the argument by the compiler. A slider is
// not a number the compiler knows, so no rule matches and the program is
// refused.
// expect-error
// expect: (pattern matching failed|no case rule matches)
import("stdfaust.lib");

wave(0) = os.osc(440);
wave(1) = os.sawtooth(440);

process = wave(hslider("mode", 1, 0, 1, 1));
