// The three functions of the idioms document: arguments name the inputs.
foo1(in_a, in_b, in_c) = (in_a, in_b : +), in_c : *;   // (a + b) * c
foo2(in_a, in_b, in_c) = (in_c, in_b : +), in_a : *;   // (c + b) * a
foo3(in_a, in_b, in_c) = (in_c, in_c : +), in_c : *;   // (c + c) * c

process = foo1;

// check: --double -n 1 --in zero --eval "foo1(2, 3, 4)" --eval "foo2(2, 3, 4)" --eval "foo3(2, 3, 4)"
// expect: ^0,20\.0,14\.0,32\.0$
// foo3 ignores two of its arguments, but still has three inputs.
// check: --double -n 1 --in zero --eval "inputs(foo3)"
// expect: ^0,3\.0$
