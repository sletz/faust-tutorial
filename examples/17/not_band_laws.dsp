// The controls of band_laws.dsp: three equalities that do not hold. The same
// check must fail on each of them, or it proves nothing in band_laws.dsp.
import("stdfaust.lib");

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

inDomain(T, fx, Tinv) = T : fx : Tinv;
each(B, mk) = par(b, B, mk(b, B));

split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));

freqs = (250, 1000, 4000);
comp(ratio) = \(b, B).(co.compressor_mono(ratio, -20, 0.02 / (b + 1), 0.2 / (b + 1)));

process = law(multiband(freqs, each(4, comp(4))), comp(4)(0, 1)),       // a compressor per band is not one compressor
          law(multiband(freqs, each(4, \(b, B).(*(b + 1)))), _),        // a gain per band is an equalizer, not a wire
          law((fi.filterbank(3, freqs) : unsplit(freqs)), _);           // the library's bands add back to an all-pass filter

// check-fails: --double -n 20000 --in zero --quiet --fail-above 1e-12
// Each difference is as large as the signals.
// check: --double -n 20000 --in zero --quiet
// expect: out0: peak=0\.57
// expect: out1: peak=3\.78
// expect: out2: peak=2\.18
