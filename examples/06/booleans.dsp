// Comparisons return 0 or 1. Logic operators combine them, and so do
// arithmetic, min and max.
import("stdfaust.lib");

a = hslider("a", 0, 0, 1, 1);
b = hslider("b", 0, 0, 1, 1);

process = a & b, a | b, xor(a, b), min(a, b), max(a, b), 1 - a, (a > 0.5) + (b > 0.5);

// check: --double -n 1 --in zero --set a=1 --set b=0
// expect: ^0,0\.0,1\.0,1\.0,0\.0,1\.0,0\.0,1\.0$
// check: --double -n 1 --in zero --set a=1 --set b=1
// expect: ^0,1\.0,1\.0,0\.0,1\.0,1\.0,0\.0,2\.0$
