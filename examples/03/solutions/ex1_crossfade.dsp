// Exercise 1: a crossfade between two inputs, set by a slider,
// written with named arguments.
amount = hslider("amount", 0.5, 0, 1, 0.01);

crossfade(i, x, y) = x * (1 - i) + y * i;

process = crossfade(amount);

// An impulse on input y comes out multiplied by the amount.
// check: --double -n 1 --in impulse:1 --set amount=0.25
// expect: ^0,0\.25$
