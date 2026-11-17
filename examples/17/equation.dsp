// The one-pole lowpass of chapter 4, as Faust writes it: one definition.
// The output is the signal y such that y = (1 - a) x + a y', where y' is y
// one sample earlier. Nothing is assigned: the memory is the delay that ~
// puts on the way back.
lowpass1(a) = *(1 - a) : + ~ *(a);

process = lowpass1(0.5);

// The samples of cmajor/one_pole.cmajor on an impulse.
// check: --double -n 4
// expect: ^0,0\.5$
// expect: ^1,0\.25$
// expect: ^2,0\.125$
// expect: ^3,0\.0625$
