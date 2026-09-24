// Exercise 1: a pre-delay before the reverb, up to 100 ms, bounded by the
// slider's range (chapter 9). The reverb is linear and time-invariant, so
// delaying its input is the same as delaying its output.
import("stdfaust.lib");

predelay = hslider("predelay [unit:ms]", 10, 0, 100, 1) * ma.SR / 1000 : int;

process = de.delay(ma.SR / 10, predelay) : re.mono_freeverb(0.84, 0.5, 0.2, 0);

// check: --double -n 20000 --in white:1 --quiet --compare ex1_reference.dsp
// expect: out0: identical
