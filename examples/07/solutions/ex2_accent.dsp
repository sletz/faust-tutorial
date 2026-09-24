// Exercise 2: a metronome whose first beat of every four is louder.
// The beat count modulo 4 tells where we are in the bar.
import("stdfaust.lib");

bpm = hslider("bpm", 120, 30, 300, 1);

beat = ba.beat(bpm);
position = beat : + ~ _ : -(1) : int : %(4);      // 0, 1, 2, 3, 0, ...
accent = ba.if(position == 0, 1.0, 0.5);

process = beat * accent;

// At 1 kHz and 120 bpm: 1 at frame 0, 0.5 at 500, 1000, 1500, 1 at 2000.
// check: --double --sr 1000 --in zero -n 2001
// expect: ^0,1\.0$
// expect: ^500,0\.5$
// expect: ^1500,0\.5$
// expect: ^2000,1\.0$
