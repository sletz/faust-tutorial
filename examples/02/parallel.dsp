// Parallel composition A, B: the two blocks side by side.
// Two inputs, two outputs.
process = *(2), *(3);

// check: --double -n 1 --in dc
// expect: ^0,2\.0,3\.0$
