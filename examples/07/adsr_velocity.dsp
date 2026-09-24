// en.adsr's gate is also its attack speed: its attack counter adds the gate
// value at every sample. A velocity of 0.5 used as the gate doubles the
// attack and decay times. Use a 0/1 gate, and multiply by the velocity.
import("stdfaust.lib");

velocity = hslider("velocity", 0, 0, 1, 0.01);

process = en.adsr(0.01, 0.1, 0.5, 0.1, velocity),
          en.adsr(0.01, 0.1, 0.5, 0.1, velocity > 0) * velocity;

// At 48 kHz, a 10 ms attack peaks at sample 479; with the velocity as gate
// it peaks at 959.
// check: --double --sr 48000 -n 48000 --in zero --at 0 velocity=0.5 --quiet
// expect: out0: peak=1\.0 .*peak_at=959
// expect: out1: peak=0\.5 .*peak_at=479
