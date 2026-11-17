// Circuits as arguments, and three ways to put four filters in series:
// twice applied to its own result, a recursion on an integer (chapter 11),
// an iteration.
lowpass1(a) = *(1 - a) : + ~ *(a);

twice(f) = f : f;

chain(1, f) = f;
chain(n, f) = f : chain(n - 1, f);

process = _ <: twice(twice(lowpass1(0.5))), chain(4, lowpass1(0.5)), seq(i, 4, lowpass1(0.5));

// The samples of cmajor/twice.cmajor on an impulse, three times.
// check: --double -n 6
// expect: ^0,0\.0625,0\.0625,0\.0625$
// expect: ^2,0\.15625,0\.15625,0\.15625$
// expect: ^5,0\.109375,0\.109375,0\.109375$
// The three outputs are one signal: four memories, not twelve.
// cpp-expect: float fRec3\[2\];
// cpp-absent: fRec4
