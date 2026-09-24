// inputs(x) and outputs(x) give the arity of a block, known at compile time.
foo1(a, b, c) = (a + b) * c;

// The mean of all the outputs of a block, whatever their number.
mean(x) = x :> /(outputs(x));

process = inputs(foo1), outputs(foo1), mean((1, 2, 3)), mean((1, 2, 3, 4, 5));

// check: --double -n 1 --in zero
// expect: ^0,3\.0,1\.0,2\.0,3\.0$
