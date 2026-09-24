// The three writings of impulse in the idioms document are the same block:
// the completed wiring from faust_tutorial.pdf and its two simplifications.
impulse_wired = _ <: _, mem : - : >(0.0);
impulse_diff(x) = x - x' > 0.0;
impulse_edge(x) = x > x';

process = _ <: impulse_wired - impulse_edge, impulse_diff - impulse_edge;

// On white noise the differences are zero at every sample.
// check: --double -n 10000 --in white:3 --quiet
// expect: out0: peak=0\.0 
// expect: out1: peak=0\.0 
