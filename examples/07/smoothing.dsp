// Smoothing a control: a slider that jumps makes a click. si.smoo is the
// one-pole lowpass of chapter 4 with a time constant of about 23 ms
// (pole 1 - 44.1/SR): after 1000 samples at 44.1 kHz, 63 % of the jump.
import("stdfaust.lib");

gain = hslider("gain", 0, 0, 1, 0.01);

// The parentheses matter: "gain, gain : si.smoo" would read
// "(gain, gain) : si.smoo" (chapter 2).
process = gain, (gain : si.smoo);

// check: --double --in zero -n 1001 --at 1 gain=1
// expect: ^1,1\.0,0\.001
// expect: ^1000,1\.0,0\.632
