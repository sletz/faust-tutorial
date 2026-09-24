// Split A <: B: each output of A is copied to the inputs of B.
// Here one input becomes two identical outputs: mono to stereo.
process = _ <: _, _;

// check: --double -n 1
// expect: ^0,1\.0,1\.0$
