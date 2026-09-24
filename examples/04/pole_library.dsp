// The same filter with the library: fi.pole(p) = + ~ *(p) is the recursive
// part, the gain (1 - p) keeps the level of a constant at 1.
import("stdfaust.lib");

lowpass1(a) = *(1 - a) : + ~ *(a);

process = *(0.5) : fi.pole(0.5);

// Identical to lowpass1(0.5), sample for sample.
// check: --double -n 256 --in white:1 --quiet --compare one_pole.dsp
// expect: identical
