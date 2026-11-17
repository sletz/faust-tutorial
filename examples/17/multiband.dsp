// Any effect, multiband. The bands of a signal are another representation
// of it: split goes there, unsplit comes back, and multiband is the
// combinator that applies a block to the bands. each puts one block on
// every band, made by a function of its rank. Here, a compressor per band,
// quicker in the high bands.
import("stdfaust.lib");

inDomain(T, fx, Tinv) = T : fx : Tinv;

// block b among B is mk(b, B)
each(B, mk) = par(b, B, mk(b, B));

// The bands of a list of frequencies, from the lowest to the highest. Each
// step gives lo and input - lo, which add back to what came in, so that the
// bands add back to the input.
// several frequencies: lo is what is below the first one, and what is left,
// the input minus lo, is split at the others
split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
// one frequency: what is below it, and what is left
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

// the way back: the bands added together, one band more than there are frequencies
unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

// fx applied to the bands of a signal
multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));

freqs = (250, 1000, 4000);          // three frequencies, four bands

// the compressor of band b among B: threshold -20 dB, attack and release
// shorter in the high bands
comp(ratio) = \(b, B).(co.compressor_mono(ratio, -20, 0.02 / (b + 1), 0.2 / (b + 1)));

ratio = hslider("ratio", 4, 1, 20, 0.1);

process = multiband(freqs, each(4, comp(ratio)));

// One input, one output: a mono effect like any other.
// check: --double -n 1 --in zero --eval "inputs(process), outputs(process)"
// expect: ^0,1\.0,1\.0$
// A sine of 100 Hz at full scale, one second, the last half measured. With a
// ratio of 1 the compressors do nothing and the sine comes back; with a
// ratio of 4 it comes out 12.7 dB lower.
// check: --double --sr 48000 -n 48000 --skip 24000 --in sine:100 --quiet --set ratio=1
// expect: out0: peak=1\.0 rms=0\.7071
// check: --double --sr 48000 -n 48000 --skip 24000 --in sine:100 --quiet
// expect: out0: peak=0\.231\d* rms=0\.1639
// split has one input and four outputs, unsplit four inputs and one output.
// check: --double -n 1 --in zero --eval "inputs(split(freqs)), outputs(split(freqs)), inputs(unsplit(freqs)), outputs(unsplit(freqs))"
// expect: ^0,1\.0,4\.0,4\.0,1\.0$
// The bands come out from the lowest to the highest: a sine of 100 Hz is
// mostly in the first one, a sine of 10 kHz in the last one.
// check: --double --sr 48000 -n 48000 --skip 24000 --in sine:100 --quiet --eval "split(freqs)"
// expect: out0: peak=\S+ rms=0\.656
// expect: out3: peak=\S+ rms=0\.00063
// check: --double --sr 48000 -n 48000 --skip 24000 --in sine:10000 --quiet --eval "split(freqs)"
// expect: out0: peak=\S+ rms=0\.0150
// expect: out3: peak=\S+ rms=0\.665
// What a low-pass filter of order 1 leaves is the high-pass filter of order
// 1 at the same frequency. At order 2 it is not, and the same check fails.
// check: --double -n 20000 --in zero --quiet --fail-above 1e-12 --eval "no.noise <: (_, fi.lowpass(1, 1000) : -), fi.highpass(1, 1000) : -"
// expect: out0: peak=
// check-fails: --double -n 20000 --in zero --quiet --fail-above 1e-12 --eval "no.noise <: (_, fi.lowpass(2, 1000) : -), fi.highpass(2, 1000) : -"
