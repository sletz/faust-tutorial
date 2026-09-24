// The rules are tried in the order they are written, and the first that
// matches is used: a general rule placed first hides the special ones.
// Both compilers give 1 for first_wins(0).
first_wins = case {
    (n) => 1;
    (0) => 2;          // never reached
};

process = first_wins(0);

// check: --double -n 1 --in zero
// expect: ^0,1\.0$

// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(1\);
