// Exercise 1: swap the two channels of a stereo signal.
// The two inputs are copied into four wires a, b, a, b; keep b and a.
process = _, _ <: !, _, _, !;

// check: --double -n 1 --in impulse:0
// expect: ^0,0\.0,1\.0$
