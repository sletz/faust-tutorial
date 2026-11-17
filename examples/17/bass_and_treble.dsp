// What the bands are for. A loud bass and a quiet treble go through one
// compressor, then through a compressor per band, and the treble is measured
// after each. One compressor turns everything down when the bass is loud;
// with one compressor per band, the bass is turned down in its band and the
// treble is left alone in its own.
import("stdfaust.lib");

inDomain(T, fx, Tinv) = T : fx : Tinv;
each(B, mk) = par(b, B, mk(b, B));

split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));

freqs = (250, 1000, 4000);
comp(ratio) = \(b, B).(co.compressor_mono(ratio, -20, 0.02 / (b + 1), 0.2 / (b + 1)));

bass = os.osc(60) * 0.5;            // -6 dB, above the threshold
treble = os.osc(6000) * 0.01;       // -40 dB, below it

trebleOnly = fi.highpass(4, 3000);  // what is left of the treble

process = bass + treble <: (comp(4)(0, 1) : trebleOnly),                        // one compressor: band 0 among 1
                           (multiband(freqs, each(4, comp(4))) : trebleOnly),   // one compressor per band
                           trebleOnly;                                          // the treble as it went in

// Two seconds at 48 kHz, the second one measured. The treble went in at
// 0.00706 RMS. One compressor gives it back at 0.00233, 9.6 dB lower; a
// compressor per band at 0.00705, 0.01 dB lower.
// check: --double --sr 48000 -n 96000 --skip 48000 --in zero --quiet
// expect: out0: peak=\S+ rms=0\.00233
// expect: out1: peak=\S+ rms=0\.00705
// expect: out2: peak=\S+ rms=0\.00706
