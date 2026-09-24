// Exercise 3: the linear congruential generator of no.noise, written with
// integers. The multiplication wraps around on 32 bits, which is what
// scrambles the sequence; dividing by 2^31 - 1 brings it to [-1, 1].
import("stdfaust.lib");

random = +(12345) ~ *(1103515245);
noise = random / 2147483647.0;

process = noise - no.noise;

// The same sequence as the library's noise, sample for sample.
// check: --double --in zero -n 10000 --quiet
// expect: note: every output is exactly zero
