// Exercise 3: damping. A one-pole lowpass in each line of the network makes
// the high frequencies die faster than the low ones, as in a real room.
import("stdfaust.lib");

N = 8;
lengths = (1031, 1327, 1523, 1801, 2053, 2311, 2579, 2803);
len(i) = ba.take(i + 1, lengths);
gain(i) = pow(10, -3 * len(i) / (1 * ma.SR));
mixing = ro.hadamard(N) : par(i, N, /(sqrt(N)));

damped_fdn(damp) = (si.bus(2 * N) :> par(i, N, line(i))) ~ mixing
with {
    line(i) = @(len(i) - 1) : *(gain(i)) : *(1 - damp) : + ~ *(damp);
};

reverb(damp) = _ <: si.bus(N) : damped_fdn(damp) :> _;

// The difference between a high and a low partial is easier to see with a
// high-passed and a low-passed version of the tail.
tail(damp) = reverb(damp) <: fi.highpass(2, 4000), fi.lowpass(2, 500);

process = _ <: tail(0), tail(0.5);

// Half a second in, against the undamped tail, the damped one has lost 31
// dB in its high band (out2 against out0) and 0.3 dB in its low band (out3
// against out1).
// check: --double -n 26460 --skip 22050 --quiet
// expect: out0: .*rms=0\.00198\d*
// expect: out1: .*rms=0\.000395\d*
// expect: out2: .*rms=5\.41\d*e-5
// expect: out3: .*rms=0\.000381\d*
