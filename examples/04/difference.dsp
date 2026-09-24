// The first difference: how much the signal changed since the last sample.
diff(x) = x - x';

process = diff;

// check: --double -n 3
// expect: ^0,1\.0$
// expect: ^1,-1\.0$
// expect: ^2,0\.0$
