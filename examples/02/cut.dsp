// The wire _ lets a signal through, the cut ! removes it.
// Keep the second input only.
process = _, _ : !, _;

// check: --double -n 1 --in impulse:1
// expect: ^0,1\.0$
