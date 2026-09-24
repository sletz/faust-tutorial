// Exercise 2: the minimum and the maximum of a signal since the start.
// The state starts at 0, which would be a wrong minimum for a positive
// signal: the first sample initialises both variables.
minmax(x) = tick ~ (_, _)
with {
    first = 1 - 1';
    tick(lo, hi) = select2(first, min(lo, x), x), select2(first, max(hi, x), x);
};

process = minmax;

// A constant 1: the minimum is 1, not the initial 0.
// check: --double -n 4 --in dc
// expect: ^3,1\.0,1\.0$
// On white noise the minimum is negative and the maximum positive.
// check: --double -n 1000 --in white:1 --quiet
// expect: out0: peak=\d
// expect: out1: peak=\d
