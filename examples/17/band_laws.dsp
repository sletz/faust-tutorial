// Four laws of the bands, each one an equality between two circuits.
import("stdfaust.lib");

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

inDomain(T, fx, Tinv) = T : fx : Tinv;
each(B, mk) = par(b, B, mk(b, B));

toMS = _, _ <: +, - : /(2), /(2);
fromMS = _, _ <: +, -;
inMS(fx) = inDomain(toMS, fx, fromMS);

split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));

freqs = (250, 1000, 4000);
comp(ratio) = \(b, B).(co.compressor_mono(ratio, -20, 0.02 / (b + 1), 0.2 / (b + 1)));

lp = fi.lowpass(2, 1000);

process = law(multiband(freqs, si.bus(4)), _),                          // there and back is the identity
          law(multiband(freqs, par(b, 4, lp)), lp),                     // one filter in every band is that filter
          law(multiband(freqs, each(4, comp(1))), _),                   // compressors of ratio 1 do nothing
          law(inMS((multiband(freqs, si.bus(4)), _)), si.bus(2));       // two domains nested, there and back

// Five differences; a sample above 1e-12 would fail the check.
// check: --double -n 20000 --in zero --quiet --fail-above 1e-12
// expect: out4: peak=
