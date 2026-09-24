// The comma binds tighter than the colon:
// *(2), *(3) : +   reads   (*(2), *(3)) : +
process = *(2), *(3) : +;

// Two inputs, one output: 2*in0 + 3*in1.
// check: --double -n 1 --in dc
// expect: ^0,5\.0$
