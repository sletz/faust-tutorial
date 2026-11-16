// A delay length scaled to the sampling rate, two ways. naive divides
// floats: the compiler folds n/44100 into one rounded constant, its product
// with the rate can come out just under the whole number, and int truncates
// it. exact works on integers: m is an exact product, m - m % 44100 an exact
// multiple of 44100, and the quotient is rounded to the nearest integer.
import("stdfaust.lib");

naive(n) = int(n * ma.SR / 44100);
exact(n) = int((m - m % 44100) / 44100 + 0.5) with { m = n * int(ma.SR); };

process = naive(225), exact(225), naive(1617), exact(1617);

// At 44.1 kHz the lengths should stay 225 and 1617. In double precision 225
// loses a sample; in single precision 1617 does.
// check: --double --sr 44100 -n 1 --in zero
// expect: ^0,224\.0,225\.0,1617\.0,1617\.0$
// check: --sr 44100 -n 1 --in zero
// expect: ^0,225\.0,225\.0,1616\.0,1617\.0$
// At 96 kHz, 1617 samples become 3520, and 3519 in single precision.
// check: --sr 96000 -n 1 --in zero
// expect: ^0,489\.0,489\.0,3519\.0,3520\.0$
