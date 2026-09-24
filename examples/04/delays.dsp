// Three ways to look into the past: mem, the prime ' and @.
// mem and x' delay by one sample, x'' by two, x@3 by three.
delays(x) = x, mem(x), x'', x@3;

process = delays;

// An impulse walks along the outputs, one sample at a time.
// check: --double -n 4
// expect: ^0,1\.0,0\.0,0\.0,0\.0$
// expect: ^1,0\.0,1\.0,0\.0,0\.0$
// expect: ^2,0\.0,0\.0,1\.0,0\.0$
// expect: ^3,0\.0,0\.0,0\.0,1\.0$
