// How many filters? Nobody declares them: the compiler counts the signals.
// Here both outputs are lp of the same input, one signal, so one memory
// serves both.
lowpass1(a) = *(1 - a) : + ~ *(a);
lp = lowpass1(0.5);

process = _ <: lp, lp;

// One recursion in the generated code, read by the two outputs.
// cpp-expect: float fRec0\[2\];
// cpp-absent: fRec1
// check: --double -n 3
// expect: ^0,0\.5,0\.5$
// expect: ^2,0\.125,0\.125$
