// Exercise 1: a sixteen-step rhythm stored in a table of 0s and 1s, played
// in sixteenth notes: a trigger comes out on the steps marked 1.
import("stdfaust.lib");

bpm = hslider("bpm", 120, 30, 300, 1);

pattern = waveform{1,0,0,0, 1,0,0,1, 0,0,1,0, 1,0,0,0};
tick = ba.beat(bpm * 4);                               // sixteenth notes
step = tick : + ~ _ : -(1) : int : %(16);
hit = tick * (pattern, step : rdtable);

process = hit;

// At 1 kHz and 120 bpm a sixteenth lasts 125 samples: hits at steps 0, 4,
// 7, 10 and 12, that is frames 0, 500, 875, 1250 and 1500.
// check: --double --sr 1000 --in zero -n 2001
// expect: ^0,1\.0$
// expect: ^125,0\.0$
// expect: ^500,1\.0$
// expect: ^875,1\.0$
// expect: ^1250,1\.0$
// expect: ^1500,1\.0$
// expect: ^2000,1\.0$
