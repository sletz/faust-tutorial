// The sum of the last n samples, from the idioms document: add the new
// sample, subtract the one that leaves the window.
moving_sum(n, x) = +(x - x@n) ~ _;

process = moving_sum(4);

// A constant 1: the sum grows to 4 and stays there.
// check: --double -n 6 --in dc
// expect: ^0,1\.0$
// expect: ^3,4\.0$
// expect: ^5,4\.0$
