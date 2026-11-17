// no.noise is not a call that draws a number: it is one signal, and
// subtracted from itself it is silence. Two noises that differ are two
// different signals, which no.multinoise(2) provides.
import("stdfaust.lib");

process = 0.1 * (no.noise - no.noise), 0.1 * (no.multinoise(2) : -);

// The first output is the constant 0, the second is noise.
// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(0\.0f\);
// check: --double -n 4096 --in zero --quiet
// expect: out0: peak=0\.0 rms=0\.0 dc=0\.0 finite
// expect: out1: peak=0\.19\d* rms=0\.08
