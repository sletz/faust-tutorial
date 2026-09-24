// -(x) is not the opposite of x: an operator with one argument is a partial
// application, so -(2) is the block _ - 2, with one input.
minus_two = -(2);
negated = 0 - 2;

process = 10 : minus_two, negated;

// check: --double -n 1 --in zero
// expect: ^0,8\.0,-2\.0$
