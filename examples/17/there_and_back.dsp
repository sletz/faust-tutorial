// A law that the compiler knows. Splitting a signal into four bands takes
// three filters and three subtractions, adding the bands back three sums.
// The bands add back to the input, and the compiler finds it out: no filter
// is left in the generated code, only a wire.
import("stdfaust.lib");

inDomain(T, fx, Tinv) = T : fx : Tinv;

split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));

process = multiband((250, 1000, 4000), si.bus(4));

// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(static_cast<float>\(input0\[i0\]\)\);
// cpp-absent: fRec
// An impulse comes back as it went in.
// check: --double -n 3 --in impulse
// expect: ^0,1\.0$
// expect: ^1,0\.0$
// expect: ^2,0\.0$
