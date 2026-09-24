// A constant delayed by one sample is 0 at the first sample, then the
// constant: 1 - 1' is 1 at the first sample only. It is os.impulse.
process = 1 - 1';

// check: --double -n 3 --in zero
// expect: ^0,1\.0$
// expect: ^1,0\.0$
