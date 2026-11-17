// What is left of a combinator in the generated code. The matrix of a
// rotation is sixteen products by 0 or 1 and four sums; the compiler
// evaluates the coefficient function, removes the products and the sums,
// and keeps four wires.
import("stdfaust.lib");

matrix(n, m, c) = si.bus(n) <: par(o, m, par(i, n, *(c(i, o))) :> _);
rotation(P) = \(i, o).(o == (i + 1) % P);

process = matrix(4, 4, rotation(4));

// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(static_cast<float>\(input3\[i0\]\)\);
// cpp-expect: output1\[i0\] = static_cast<FAUSTFLOAT>\(static_cast<float>\(input0\[i0\]\)\);
// cpp-expect: output2\[i0\] = static_cast<FAUSTFLOAT>\(static_cast<float>\(input1\[i0\]\)\);
// cpp-expect: output3\[i0\] = static_cast<FAUSTFLOAT>\(static_cast<float>\(input2\[i0\]\)\);
// cpp-absent: fTemp
// An impulse on input 0 comes out on output 1.
// check: --double -n 1 --in impulse:0
// expect: ^0,0\.0,1\.0,0\.0,0\.0$
