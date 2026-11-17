// A law that the compiler does not know. One filter in every band is that
// filter (band_laws.dsp), but the generated code keeps the three filters of
// the crossover and the four copies of lp: eleven recursions, where lp alone
// takes two. Replacing them with one lp is left to the programmer, and the
// law is what allows it.
import("stdfaust.lib");

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

inDomain(T, fx, Tinv) = T : fx : Tinv;

split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));

lp = fi.lowpass(2, 1000);

process = multiband((250, 1000, 4000), par(b, 4, lp));

// cpp-expect: fRec10\[0\] =
// cpp-absent: fRec11
// The law holds all the same: the difference with lp alone stays at the
// rounding error.
// check: --double -n 20000 --in zero --quiet --fail-above 1e-12 --eval "law(process, lp)"
// expect: out0: peak=
