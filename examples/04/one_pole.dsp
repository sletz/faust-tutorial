// A one-pole lowpass filter: y[n] = (1 - a) x[n] + a y[n-1].
// The feedback path multiplies by a.
lowpass1(a) = *(1 - a) : + ~ *(a);

process = lowpass1(0.5);

// Impulse response: 0.5, 0.25, 0.125, ...
// check: --double -n 3
// expect: ^0,0\.5$
// expect: ^1,0\.25$
// expect: ^2,0\.125$
