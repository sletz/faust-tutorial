// Exercise 1: remove the constant part of a signal: the first difference,
// followed by a leaky integrator that brings the level back.
dcblock(p) = _ <: _, mem : - : + ~ *(p);

process = dcblock(0.995);

// A constant input dies out: after one second almost nothing is left.
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=\d\.\d+e-(\d\d|[5-9])
