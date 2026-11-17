// Three combinators nested: in mid/side, compress the bands of the mid
// signal and leave the side signal alone. multiband(...) is a mono block,
// so it can be the mid part of the block that inMS takes.
import("stdfaust.lib");

inDomain(T, fx, Tinv) = T : fx : Tinv;
each(B, mk) = par(b, B, mk(b, B));

toMS = _, _ <: +, - : /(2), /(2);       // left, right -> mid, side
fromMS = _, _ <: +, -;                  // mid, side -> left, right
inMS(fx) = inDomain(toMS, fx, fromMS);

split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));

freqs = (250, 1000, 4000);
comp(ratio) = \(b, B).(co.compressor_mono(ratio, -20, 0.02 / (b + 1), 0.2 / (b + 1)));

ratio = hslider("ratio", 4, 1, 20, 0.1);

process = inMS((multiband(freqs, each(4, comp(ratio))), _));

// A stereo block: two inputs, two outputs.
// check: --double -n 1 --in zero --eval "inputs(process), outputs(process)"
// expect: ^0,2\.0,2\.0$
// The same sine on both inputs is all mid: it is compressed, and stays in
// the centre, the two outputs being the same sample.
// check: --double --sr 48000 -n 2001 --skip 2000 --in sine:440
// expect: ^2000,(\S+),\1$
// An impulse on the left input alone: whatever the compressors do to the
// mid, the difference of the outputs is the difference of the inputs.
// check: --double -n 2 --in impulse:0 --eval "process : -"
// expect: ^0,1\.0$
// expect: ^1,0\.0$
