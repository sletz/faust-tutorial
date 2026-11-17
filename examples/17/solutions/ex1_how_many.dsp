// Exercise 1: three uses of lp, two memories. The lp alone filters the
// input, as the first lp of the chain does: they are the same signal.
lowpass1(a) = *(1 - a) : + ~ *(a);
lp = lowpass1(0.5);

process = _ <: (lp : lp), lp;

// Two recursions; the second output reads the first stage of the chain.
// cpp-expect: float fRec0\[2\];
// cpp-expect: float fRec1\[2\];
// cpp-absent: fRec2
// cpp-expect: output1\[i0\] = static_cast<FAUSTFLOAT>\(fRec1\[0\]\);
// check: --double -n 3
// expect: ^0,0\.25,0\.5$
// expect: ^2,0\.1875,0\.125$
