// The rules are tried in the order they are written, and the first that
// matches is used: a general rule placed first hides the special ones.
// The reference compiler gives 1 for first_wins(0).
// (faust-rs gives 2 at the time of writing, a divergence being fixed, so
// this example is checked on the C++ code only.)
first_wins = case {
    (n) => 1;
    (0) => 2;          // never reached
};

process = first_wins(0);

// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(1\);
