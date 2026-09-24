// A metronome: one click per wrap of a phasor. The phase drops when it
// wraps, so p < p' is 1 on the first sample of each period. ba.beat counts
// samples instead, and clicks at frame 0 too.
import("stdfaust.lib");

bpm = hslider("bpm", 120, 30, 300, 1);

wraps(p) = p < p';
beat = os.lf_sawpos(bpm / 60) : wraps;

process = beat, ba.beat(bpm);

// At 1 kHz and 120 beats per minute, a beat every 500 samples.
// check: --double --sr 1000 --in zero -n 1501
// expect: ^0,0\.0,1\.0$
// expect: ^499,0\.0,0\.0$
// expect: ^500,1\.0,1\.0$
// expect: ^1000,1\.0,1\.0$
