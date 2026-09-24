// Only what reaches an output is computed. The first oscillator and its
// slider are cut: no code, no widget.
import("stdfaust.lib");

a = os.osc(hslider("a", 440, 20, 2000, 1));
b = os.sawtooth(hslider("b", 220, 20, 2000, 1));

process = a, b : !, _;

// check: --list-params
// expect: /dead_code/b
// cpp-absent: "a"
// cpp-expect: "b"
