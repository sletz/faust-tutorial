// Exercise 4: an equalizer is multiband with a gain per band, the gains in
// decibels in a list, from the lowest band to the highest.
import("stdfaust.lib");

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

inDomain(T, fx, Tinv) = T : fx : Tinv;
each(B, mk) = par(b, B, mk(b, B));

split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));

freqs = (250, 1000, 4000);

eq(gains) = multiband(freqs, each(4, \(b, B).(*(ba.db2linear(ba.take(b + 1, gains))))));

process = law(eq((-6, -6, -6, -6)), *(ba.db2linear(-6))),       // four equal gains are that gain
          (1 : eq((6, 0, 0, -6)));                              // a constant only passes through the lowest band

// The law holds, and the constant 1 comes out with the first gain, +6 dB.
// check: --double --sr 48000 -n 48000 --skip 24000 --in zero --quiet
// expect: out0: peak=(0\.0|\S+e-1[5-9])
// expect: out1: peak=1\.9952\d* rms=1\.9952
