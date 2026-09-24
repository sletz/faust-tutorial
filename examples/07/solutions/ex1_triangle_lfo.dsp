// Exercise 1: a triangle LFO in [-1, 1] with a frequency and a phase offset.
import("stdfaust.lib");

freq  = hslider("freq", 1, 0.01, 20, 0.01);
phase = hslider("phase", 0, 0, 1, 0.01);

triangle_lfo(f, ph) = 4 * abs(ma.frac(os.lf_sawpos(f) + ph) - 0.5) - 1;

process = triangle_lfo(freq, phase);

// A phase of 0.5 starts at the bottom instead of the top.
// check: --double --in zero -n 2 --set phase=0
// expect: ^0,1\.0$
// check: --double --in zero -n 2 --set phase=0.5
// expect: ^0,-1\.0$
