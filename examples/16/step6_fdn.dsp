// Step 6: a second design, the feedback delay network (Jot and Chaigne,
// 1991). Eight delay lines of prime lengths, mixed by a normalised Hadamard
// matrix (chapter 11), which keeps the energy; each line loses exactly the
// gain that makes the whole network decay by 60 dB in T60 seconds.
import("stdfaust.lib");

N = 8;
lengths = (1031, 1327, 1523, 1801, 2053, 2311, 2579, 2803);
len(i) = ba.take(i + 1, lengths);

T60 = hslider("T60 [unit:s]", 1, 0.1, 10, 0.01);
gain(i) = pow(10, -3 * len(i) / (T60 * ma.SR));

line(i) = @(len(i) - 1) : *(gain(i));           // ~ adds the last sample
mixing = ro.hadamard(N) : par(i, N, /(sqrt(N)));

fdn = (si.bus(2 * N) :> par(i, N, line(i))) ~ mixing;

process = _ <: si.bus(N) : fdn :> _, _;

// An impulse: the level between 0.2 and 0.3 s, and one second later, when
// it must be 60 dB (a factor 1000) lower.
// check: --double -n 13230 --skip 8820 --quiet
// expect: out0: peak=0\.12\d* rms=0\.0109\d*
// check: --double -n 57330 --skip 52920 --quiet
// The ratio of the two RMS levels is 972, or 59.7 dB.
// expect: out0: peak=\d\.\d+e-5 rms=1\.13\d*e-5
