// Explicit substitution: env[name = value;] is the environment with one
// definition replaced; everything that used it is recomputed.
import("stdfaust.lib");

synth = environment {
    freq = 440;
    gain = 0.5;
    tone = os.osc(freq) * gain;
};

process = synth.tone, synth[freq = 880;].tone, synth[gain = 0.25;].freq;

// The second voice is an octave higher; the substitution of gain does not
// change freq.
// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=0\.4999
// expect: out1: peak=0\.4999
// expect: out2: peak=440\.0
