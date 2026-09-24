// Bypass with a checkbox: ba.bypass1(bypass, effect) lets the input through
// when bypass is 1, and feeds silence to the effect so that it costs less.
import("stdfaust.lib");

bypass = checkbox("bypass");

process = ba.bypass1(bypass, fi.lowpass(2, 500));

// Bypassed, an impulse comes out unchanged; otherwise it is filtered.
// check: --double -n 2 --set bypass=1
// expect: ^0,1\.0$
// expect: ^1,0\.0$
// check: --double -n 2 --set bypass=0
// expect: ^0,0\.00\d*$
