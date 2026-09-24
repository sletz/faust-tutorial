// Merge A :> B: the outputs of A are summed into the inputs of B,
// cyclically: output i goes to input i modulo the number of inputs.
// Two stereo pairs mixed into one: (in0 + in2), (in1 + in3).
process = _, _, _, _ :> _, _;

// check: --double -n 1 --in impulse:2
// expect: ^0,1\.0,0\.0$
// check: --double -n 1 --in impulse:3
// expect: ^0,0\.0,1\.0$
