// The feedback path of ~ already holds one sample of delay.
// A feedback echo of d samples therefore needs @(d - 1) in the loop.
echo(d, g) = + ~ (@(d - 1) : *(g));

process = echo(4, 0.5);

// Echoes at samples 0, 4, 8, halving each time.
// check: --double -n 9
// expect: ^0,1\.0$
// expect: ^3,0\.0$
// expect: ^4,0\.5$
// expect: ^8,0\.25$
