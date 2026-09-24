// Sequential composition A : B: the outputs of A feed the inputs of B.
process = *(2) : +(1);

// With an impulse in: 1*2+1 = 3, then 0*2+1 = 1.
// check: --double -n 2
// expect: ^0,3\.0$
// expect: ^1,1\.0$
