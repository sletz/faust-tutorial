// Lambda abstractions: \(x).(expression) is a function without a name.
// A function can also return one: adder(n) builds a block that adds n.
square = \(x).(x * x);
add = \(x, y).(x + y);
adder(n) = \(x).(x + n);
add3 = adder(3);

process = square(3), add(2, 5), add3(4), (10 : adder(0.5));

// check: --double -n 1 --in zero
// expect: ^0,9\.0,7\.0,7\.0,10\.5$
