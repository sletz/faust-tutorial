// A name is an abbreviation. This is chained.dsp with lp and lowpass1
// replaced by their definitions, as the compiler does before anything else:
// the same program.
process = (*(1 - 0.5) : + ~ *(0.5)) : (*(1 - 0.5) : + ~ *(0.5));

// The same samples as chained.dsp, bit for bit, and the same two lines in
// the generated code.
// check: --double -n 4096 --in white:1 --quiet --compare chained.dsp
// expect: compare out0: identical
// cpp-expect: fRec1\[0\] = 0\.5f \* \(static_cast<float>\(input0\[i0\]\) \+ fRec1\[1\]\);
// cpp-expect: fRec0\[0\] = 0\.5f \* \(fRec0\[1\] \+ fRec1\[0\]\);
// cpp-absent: fRec2
