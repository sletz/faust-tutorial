// A delay line written by hand with a read-write table (Den Haag, 2006):
// the write index goes round a table of n = 2^k cells, and the read index
// is d cells behind. & (n - 1) wraps the index and stays positive.
import("stdfaust.lib");

index(n) = &(n - 1) ~ +(1);
delay(n, d, x) = rwtable(n, 0.0, index(n), x, (index(n) - int(d)) & (n - 1));

process = _ <: delay(1024, 100), @(100);

// The same samples as @(100).
// check: --double --in white:1 -n 4000 --quiet
// expect: out0: peak=
// check: --double -n 101
// expect: ^100,1\.0,1\.0$
// expect: ^99,0\.0,0\.0$
