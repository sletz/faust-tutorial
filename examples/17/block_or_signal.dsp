// A name stands for a block, and a block is not always a signal. In d, the
// two x are the same block. As a block on its own, d has one input, x is
// that signal and the output is zero. Applied to the wire _, a block with
// an input, d(_) is _ - _: each occurrence takes its own input.
d(x) = x - x;

process = d, d(_);

// Three inputs: one for d, two for d(_).
// check: --double -n 1 --in zero --eval "inputs(d), inputs(d(_))"
// expect: ^0,1\.0,2\.0$
// An impulse on the second input: d is zero, d(_) is its first input minus
// its second.
// check: --double -n 1 --in impulse:1
// expect: ^0,0\.0,1\.0$
// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(0\);
