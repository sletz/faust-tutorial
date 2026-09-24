// A filter's frequency response, measured by faustprobe from its impulse
// response: a second-order Butterworth lowpass is 3 dB down at its cutoff.
import("stdfaust.lib");

process = fi.lowpass(2, 1000);

// check: --double -n 44100 --freqresp 1:1000:1000
// expect: ^1000\.0,-3\.010\d*,
// expect: linear and time-invariant
