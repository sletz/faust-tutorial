// Exercise 3: specialise a filter by partial application and constants: a
// resonant lowpass with Q and gain fixed, and its frequency as the only
// control. The fixed part costs nothing at run time.
import("stdfaust.lib");

resonant(f) = fi.resonlp(f, 5, 0.5);

process = resonant(hslider("freq", 500, 50, 5000, 1) : si.smoo);

// check: --double --in white:1 -n 44100 --quiet
// expect: finite=yes
// cpp-expect: fConst
