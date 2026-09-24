// --check all verifies properties any audio program should have: the same
// samples whatever the block size, the same samples again after a reset,
// and the same code from two compilations.
import("stdfaust.lib");

process = fi.resonlp(800, 4, 0.5);

// check: --double -n 8192 --quiet --check all
// expect: check block
// expect: check reset
