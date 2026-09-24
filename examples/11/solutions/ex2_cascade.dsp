// Exercise 2: repeat a block n times in sequence, written with patterns.
// It is seq(i, n, f) without the index.
import("stdfaust.lib");

cascade(1, f) = f;
cascade(n, f) = f : cascade(n - 1, f);

process = _ <: cascade(4, fi.pole(0.5)) - seq(i, 4, fi.pole(0.5));

// check: --double -n 1000 --in white:1 --quiet
// expect: note: every output is exactly zero
