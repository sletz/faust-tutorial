// The feedback delay network of chapter 16, from two combinators: a matrix
// given by its coefficient function, and a loop closed through that matrix
// around any block.
import("stdfaust.lib");

matrix(n, m, c) = si.bus(n) <: par(o, m, par(i, n, *(c(i, o))) :> _);

hadamard(P) = \(i, o).((1 - 2 * (bits(i & o) % 2)) / sqrt(P))
with {
    bits(x) = sum(b, 16, (x >> b) & 1);
};

// fx on P channels, its outputs fed back through the matrix c with the gain g
feedbackNetwork(P, c, g, fx) = (ro.interleave(P, 2) : par(i, P, +) : fx) ~ (matrix(P, P, c) : par(i, P, *(g)));

N = 8;
lengths = (1031, 1327, 1523, 1801, 2053, 2311, 2579, 2803);
len(i) = ba.take(i + 1, lengths);

T60 = hslider("T60 [unit:s]", 1, 0.1, 10, 0.01);
gain(i) = pow(10, -3 * len(i) / (T60 * ma.SR));

line(i) = @(len(i) - 1) : *(gain(i));           // ~ adds the last sample

process = _ <: si.bus(N) : feedbackNetwork(N, hadamard(N), 1, par(i, N, line(i))) :> _, _;

// The samples of chapter 16's network, to within rounding: the additions
// are not made in the same order.
// check: --double -n 44100 --quiet --rel-tolerance 1e-12 --compare ../16/step6_fdn.dsp
// expect: compare out0: max_abs=\S+e-1[6-9]
// The comparison can fail: with another decay time on this side, it does.
// check-fails: --double -n 44100 --quiet --rel-tolerance 1e-12 --set-a T60=2 --compare ../16/step6_fdn.dsp
