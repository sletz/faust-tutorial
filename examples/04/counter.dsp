// A counter: the integrator of the constant 1. It starts at 1, because the
// state starts at 0 and the first sample already adds 1.
count = 1 : + ~ _;

// ba.time delays it by one sample, so that it starts at 0.
import("stdfaust.lib");

process = count, ba.time;

// check: --double -n 3 --in zero
// expect: ^0,1\.0,0\.0$
// expect: ^2,3\.0,2\.0$
