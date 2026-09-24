// Exercise 3: tabulate an expensive function. tanh over [-4, 4] in a table
// of 256 values, read with linear interpolation, against the exact tanh.
import("stdfaust.lib");

fast_tanh(x) = ba.tabulate(1, ma.tanh, 256, -4, 4, x).lin;

process = os.osc(100) * 4 <: fast_tanh - ma.tanh;

// The error stays below 1e-3.
// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=\d\.\d+e-(4|5) 
