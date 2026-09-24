// An FIR filter with sum: y = c0 x + c1 x' + c2 x'' + ...
// The body @(i) * c(i) has one input, so sum(i, N, ...) has N inputs:
// the signal must be split N times first.
c(0) = 0.25; c(1) = 0.5; c(2) = 0.25;

taps = sum(i, 3, @(i) * c(i));          // 3 inputs
fir  = _ <: taps;                        // 1 input

process = fir;

// check: --double -n 1 --in zero --eval "inputs(taps)" --eval "inputs(fir)"
// expect: ^0,3\.0,1\.0$
// check: --double -n 4
// expect: ^0,0\.25$
// expect: ^1,0\.5$
// expect: ^2,0\.25$
// expect: ^3,0\.0$
