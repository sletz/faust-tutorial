// The same name twice, in series this time: the second lp filters another
// signal than the first, so there are two signals and two memories.
lowpass1(a) = *(1 - a) : + ~ *(a);
lp = lowpass1(0.5);

process = lp : lp;

// Two recursions in the generated code.
// cpp-expect: fRec1\[0\] = 0\.5f \* \(static_cast<float>\(input0\[i0\]\) \+ fRec1\[1\]\);
// cpp-expect: fRec0\[0\] = 0\.5f \* \(fRec0\[1\] \+ fRec1\[0\]\);
// cpp-absent: fRec2
// check: --double -n 3
// expect: ^0,0\.25$
// expect: ^1,0\.25$
// expect: ^2,0\.1875$
