// Exercise 2: one input to four outputs, each half the previous one.
process = _ <: *(1), *(0.5), *(0.25), *(0.125);

// check: --double -n 1
// expect: ^0,1\.0,0\.5,0\.25,0\.125$
