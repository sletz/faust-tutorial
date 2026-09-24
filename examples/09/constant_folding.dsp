// Everything that can be computed before the program runs, is: the three
// outputs are constants in the generated code.
process = (1 + 2) * 3, sin(0.5), 1/3 + 1/3;

// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(9\);
// cpp-expect: output1\[i0\] = static_cast<FAUSTFLOAT>\(0\.47942555f\);
// cpp-absent: std::sin
// check: --double -n 1 --in zero
// expect: ^0,9\.0,0\.479425538604203,0\.6666666666666666$
