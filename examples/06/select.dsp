// select2(c, a, b) is a if c is 0, b if c is 1. ba.if(c, then, else) is the
// same with the branches in the usual order. Both compute both branches, but
// only the chosen one reaches the output, even if the other is infinite.
// Selecting by arithmetic, c * a + (1 - c) * b, does not: 0 * inf is NaN.
import("stdfaust.lib");

x = hslider("x", 1, 0, 1, 1);

safe_inverse = ba.if(x == 0, 0, 1 / x);
arithmetic_inverse = (x == 0) * 0 + (x != 0) * (1 / x);

process = safe_inverse, arithmetic_inverse;

// check-fails: --double -n 1 --in zero --set x=0
// expect: ^0,0\.0,NaN$
// check: --double -n 1 --in zero --set x=1
// expect: ^0,1\.0,1\.0$
