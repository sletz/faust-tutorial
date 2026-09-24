// The value of en.adsr's gate does not scale it: a velocity of 0.5 used as
// the gate gives the whole envelope, up to 1. Use a 0/1 gate, and multiply
// by the velocity. (Until faustlibraries 2.74.3, the attack counter added
// the value of the gate at every sample, and a velocity of 0.5 also doubled
// the attack and decay times.)
import("stdfaust.lib");

velocity = hslider("velocity", 0, 0, 1, 0.01);

process = en.adsr(0.01, 0.1, 0.5, 0.1, velocity),
          en.adsr(0.01, 0.1, 0.5, 0.1, velocity > 0) * velocity;

// At 48 kHz, a 10 ms attack peaks at sample 479, whatever the gate's value.
// check: --double --sr 48000 -n 48000 --in zero --at 0 velocity=0.5 --quiet
// expect: out0: peak=1\.0 .*peak_at=479
// expect: out1: peak=0\.5 .*peak_at=479
