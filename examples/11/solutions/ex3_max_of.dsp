// Exercise 3: the maximum of a list of signals, whatever its length.
max_of((x, xs)) = max(x, max_of(xs));
max_of(x) = x;

process = max_of((1, 5, 3, 2)), max_of((_, _, _));

// The constant list gives 5; the three inputs give their maximum.
// check: --double -n 1 --in impulse:1
// expect: ^0,5\.0,1\.0$
