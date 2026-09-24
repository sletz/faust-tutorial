// Definitions by cases: the rules are tried in order, the first that
// matches is used. The recursion runs in the compiler: the program outputs
// a constant (Albert Gräf, Faust term rewriting, 2009).
fact(0) = 1;
fact(n) = n * fact(n - 1);

process = fact(10);

// cpp-expect: static_cast<FAUSTFLOAT>\(3628800\)
// check: --double -n 1 --in zero
// expect: ^0,3628800\.0$
