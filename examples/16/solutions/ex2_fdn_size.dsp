// Exercise 2: the size of the network as a compile-time parameter. The
// lengths are taken from the table of primes of maths.lib, spread with the
// index; ro.hadamard needs a power of two.
import("stdfaust.lib");

fdn(N, T60) = (si.bus(2 * N) :> par(i, N, line(i))) ~ mixing
with {
    len(i) = ma.primes(160 + 23 * i);
    gain(i) = pow(10, -3 * len(i) / (T60 * ma.SR));
    line(i) = @(len(i) - 1) : *(gain(i));
    mixing = ro.hadamard(N) : par(i, N, /(sqrt(N)));
};

reverb(N) = _ <: si.bus(N) : fdn(N, 1) :> _ : /(N);

process = _ <: reverb(4), reverb(16);

// Both decay by about 60 dB in one second: the RMS level between 0.2 and
// 0.3 s, then one second later (ratios 988 and 893, 59.9 and 59.0 dB).
// check: --double -n 13230 --skip 8820 --quiet
// expect: out0: .*rms=0\.00350\d*
// expect: out1: .*rms=0\.00140\d*
// check: --double -n 57330 --skip 52920 --quiet
// expect: out0: .*rms=3\.54\d*e-6
// expect: out1: .*rms=1\.57\d*e-6
