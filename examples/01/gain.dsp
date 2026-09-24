// An operator is a block: *(0.5) has one input and one output.
process = *(0.5);

// faustprobe's default input is an impulse: 1, then 0.
// check: --double -n 3
// expect: ^0,0\.5$
// expect: ^1,0\.0$
