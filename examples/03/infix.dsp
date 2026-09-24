// The same function as in wires.dsp, written with the usual operators.
foo1(a, b, c) = (a + b) * c;

process = foo1;

// Same output as the wired version, sample for sample.
// check: --double -n 256 --in white:1 --quiet --compare wires.dsp
// expect: identical
