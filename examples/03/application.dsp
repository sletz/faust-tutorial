// Applying a function to signals is sending them to it:
// f(x, y) is the same block as  x, y : f.
import("stdfaust.lib");

f(a, b) = a - b;

process = f(os.osc(440), os.osc(440)), (os.osc(440), os.osc(440) : f);

// check: --double --in zero -n 1000 --quiet
// expect: out0: peak=0\.0 
// expect: out1: peak=0\.0 
