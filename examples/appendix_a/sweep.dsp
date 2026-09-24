// A sweep renders a program once per value of a control and reduces each
// render to one number: here the RMS output of a lowpass fed with a 1 kHz
// sine, for three cutoffs.
import("stdfaust.lib");

cutoff = hslider("cutoff", 1000, 100, 10000, 1);

process = fi.lowpass(2, cutoff);

// check: --double --in sine:1000 -n 44100 --skip 4410 --sweep cutoff=100,1000,10000 --reduce rms
// A sine of amplitude 1 has an RMS value of 0.7071: a cutoff at 10 kHz lets
// it through, a cutoff at 1 kHz multiplies it by 0.707 (-3 dB, the
// Butterworth point, giving 0.5), a cutoff at 100 Hz divides it by 100
// (-40 dB).
// expect: ^100,0\.00704\d*$
// expect: ^1000,0\.49999\d*$
// expect: ^10000,0\.70709\d*$
