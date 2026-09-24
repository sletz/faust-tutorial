// Exercise 2: a counter that goes 0, 1, ..., n-1, 0, 1, ...
// The modulo is taken inside the loop, so the state never grows.
wrap_counter(n) = (+(1) : %(n)) ~ _ : mem;

process = wrap_counter(3);

// check: --double -n 7 --in zero
// expect: ^0,0\.0$
// expect: ^2,2\.0$
// expect: ^3,0\.0$
// expect: ^6,0\.0$
