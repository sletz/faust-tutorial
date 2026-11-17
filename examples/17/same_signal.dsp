// One name, one signal. lp is a function: applied twice to the same signal
// it gives the same signal twice. Their difference is zero and their
// comparison is true, at every sample. The same lines in
// cmajor/stepped_twice.cmajor step one filter twice, and the difference
// is -0.25, 0.1875, 0.046875...
lowpass1(a) = *(1 - a) : + ~ *(a);
lp = lowpass1(0.5);

process = _ <: (lp, lp : -), (lp, lp : ==);

// The compiler knows it: the outputs are the constants 0 and 1, and no
// filter is left in the generated code.
// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(0\);
// cpp-expect: output1\[i0\] = static_cast<FAUSTFLOAT>\(1\);
// cpp-absent: fRec
// check: --double -n 4096 --in white:1 --quiet
// expect: out0: peak=0\.0 rms=0\.0 dc=0\.0 finite
// expect: out1: peak=1\.0 rms=1\.0 dc=1\.0 finite
