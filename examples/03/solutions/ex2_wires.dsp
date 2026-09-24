// Exercise 2: foo2(a, b, c) = (c + b) * a, without any argument name.
// The three wires a, b, c are copied three times; keep c, b and a.
process = _, _, _ <: !, !, _, !, _, !, _, !, ! : +, _ : *;

// check: --double -n 256 --in white:1 --quiet --compare ../reference_foo2.dsp
// expect: identical
