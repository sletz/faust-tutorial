// The sample-and-hold of "Faust Tutorial 2" (Tiziano Bole, 2008), derived
// from y[n] = y[n-1] (1 - trig) + x trig by replacing y[n-1] with a cable.
import("stdfaust.lib");

SH(trig, x) = (*(1 - trig) + x * trig) ~ _;

// With trig = 1 - s it is the one-pole smoother si.smooth(s).
process = _ <: SH(1 - 0.9), si.smooth(0.9);

// Impulse response of both: 0.1, 0.09, 0.081, ...
// check: --double -n 3
// expect: ^0,0\.0999\d*,0\.0999\d*$
// expect: ^1,0\.0899\d*,0\.0899\d*$
// expect: ^2,0\.0809\d*,0\.0809\d*$
