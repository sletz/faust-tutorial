// Two different block diagrams, one computation: both are x(t - 10) / 2.
// The compiler reduces them to the same normal form and computes it once
// (Orlarey, Fober and Letz, SMC 2009).
process = _ <: (/(2) : @(10)), (*(2) : @(7) : /(4) : @(3));

// One delay line of 11 samples, one multiplication, shared by both outputs.
// cpp-expect: float fVec0\[11\];
// cpp-expect: float fTemp0 = 0\.5f \* fVec0\[10\];
// cpp-absent: fVec1
// check: --double -n 256 --in white:1 --quiet
// expect: out0: peak=
// check: --double -n 11
// expect: ^10,0\.5,0\.5$
