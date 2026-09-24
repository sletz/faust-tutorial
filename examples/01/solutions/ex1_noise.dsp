// Exercise 1: white noise whose level is set by a slider.
import("stdfaust.lib");

level = hslider("level", 0.1, 0, 1, 0.01);

process = no.noise * level;

// check: --double --in zero -n 44100 --quiet --set level=1
// expect: out0: peak=0\.99
