// Step 1: the feedback comb of chapter 4. Echoes every d samples, each g
// times the previous one: a metallic, regular tail.
comb(d, g) = + ~ (@(d - 1) : *(g));

process = comb(100, 0.7);

// check: --double -n 301
// expect: ^0,1\.0$
// expect: ^100,0\.7$
// expect: ^200,0\.48999\d*$
