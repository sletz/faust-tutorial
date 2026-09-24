// State with two variables: tick receives the current state (a, b) and
// returns the next one. Two feedback wires, one per variable; the output
// keeps b and cuts a.
fibonacci = tick ~ (_, _) : !, _
with {
    kick = 1 - 1';                   // 1 at the first sample only
    tick(a, b) = b, a + b + kick;
};

process = fibonacci;

// check: --double -n 6 --in zero
// expect: ^0,1\.0$
// expect: ^1,1\.0$
// expect: ^2,2\.0$
// expect: ^5,8\.0$
