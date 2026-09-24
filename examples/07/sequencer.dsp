// An eight-step sequencer: count the beats, take the count modulo 8, and
// read the note of the step in a table (tables are chapter 10's subject).
import("stdfaust.lib");

bpm = hslider("bpm", 120, 30, 300, 1);

beat = ba.beat(bpm);                           // 1 at frame 0, then every beat
step = beat : + ~ _ : -(1) : int : %(8);       // 0, 1, ..., 7, 0, ...
note = waveform{60, 62, 64, 65, 67, 69, 71, 72}, step : rdtable;

voice = os.osc(ba.midikey2hz(note)) * en.ar(0.002, 0.2, beat);

process = voice, note;

// At 1 kHz and 120 bpm the note changes every 500 samples, and wraps
// after eight steps.
// check: --double --sr 1000 --in zero -n 4001
// expect: ^0,[-0-9.e]+,60\.0$
// expect: ^500,[-0-9.e]+,62\.0$
// expect: ^3500,[-0-9.e]+,72\.0$
// expect: ^4000,[-0-9.e]+,60\.0$
