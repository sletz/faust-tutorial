// Exercise 2: a chord of three notes (A, C sharp, E) summed on one output.
import("stdfaust.lib");

process = (os.osc(440) + os.osc(554.37) + os.osc(659.26)) * 0.1;

// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=0\.2
