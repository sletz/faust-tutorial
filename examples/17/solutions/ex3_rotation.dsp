// Exercise 3: the feedback network with a rotation instead of the Hadamard
// matrix. Each line feeds the next one, so an echo travels around the four
// outputs instead of spreading over them.
import("stdfaust.lib");

matrix(n, m, c) = si.bus(n) <: par(o, m, par(i, n, *(c(i, o))) :> _);
rotation(P) = \(i, o).(o == (i + 1) % P);
feedbackNetwork(P, c, g, fx) = (ro.interleave(P, 2) : par(i, P, +) : fx) ~ (matrix(P, P, c) : par(i, P, *(g)));

P = 4;

process = feedbackNetwork(P, rotation(P), 1, par(i, P, @(99)));     // ~ adds the last sample

// An impulse on input 0 comes out on output 0 after 99 samples, then on
// the next output every 100 samples, and is back on output 0 at 499.
// check: --double -n 500 --in impulse:0
// expect: ^99,1\.0,0\.0,0\.0,0\.0$
// expect: ^199,0\.0,1\.0,0\.0,0\.0$
// expect: ^299,0\.0,0\.0,1\.0,0\.0$
// expect: ^399,0\.0,0\.0,0\.0,1\.0$
// expect: ^499,1\.0,0\.0,0\.0,0\.0$
// expect: ^100,0\.0,0\.0,0\.0,0\.0$
