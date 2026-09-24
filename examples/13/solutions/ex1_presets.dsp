// Exercise 1: presets by substitution. One synth environment, two presets
// that each replace some of its definitions.
import("stdfaust.lib");

synth = environment {
    freq = 220;
    cutoff = 2000;
    voice = os.sawtooth(freq) : fi.lowpass(2, cutoff);
};

dark   = synth[cutoff = 300;];
bright = synth[freq = 440; cutoff = 8000;];

process = dark.voice, bright.voice, dark.freq, bright.freq;

// check: --double --in zero -n 44100 --quiet
// expect: out2: peak=220\.0
// expect: out3: peak=440\.0
// expect: finite=yes
