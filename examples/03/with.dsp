// Local definitions with "with": visible only inside the function.
mix(a, b, c) = total * c
with {
    total = a + b;
};

process = mix;

// check: --double -n 1 --in zero --eval "mix(2, 3, 4)"
// expect: ^0,20\.0$
