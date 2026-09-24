// release(n) from faust_tutorial.pdf, quoted in the idioms document: a
// value that falls by 1/n per sample while it is positive.
release(n) = + ~ (_ <: _, (_ > 0) / n : -);

// The rewrite with max never goes below 0.
release_max(n) = + ~ g with { g(x) = max(0, x - 1 / n); };

process = _ <: release(3), release_max(3);

// After three steps of 1/3 the value should be 0; rounding leaves 1.1e-16,
// which is still > 0, so release subtracts 1/3 once more and stays at -1/3.
// check: --double -n 6
// expect: ^3,1\.1102230246251565e-16,1\.1102230246251565e-16$
// expect: ^4,-0\.333333333333333\d*,0\.0$
