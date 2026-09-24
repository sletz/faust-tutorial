// case is the same thing as an expression: a function defined by rules.
// fact above is shorthand for this.
fact = case {
    (0) => 1;
    (n) => n * fact(n - 1);
};

process = fact(5);

// check: --double -n 1 --in zero
// expect: ^0,120\.0$
