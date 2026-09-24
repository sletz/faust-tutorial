// The integrator: the output comes back to the first input of +, one sample
// later. y[n] = x[n] + y[n-1].
process = + ~ _;

// An impulse becomes a step: 1, 1, 1, ...
// check: --double -n 3
// expect: ^0,1\.0$
// expect: ^2,1\.0$
// A constant becomes a ramp: 1, 2, 3, ...
// check: --double -n 3 --in dc
// expect: ^2,3\.0$
