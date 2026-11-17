// A function that remembers. fir3 is the mean of its argument and of its
// two previous values: it has memory, and it is a function all the same,
// called in an expression (smooth) or composed with itself (fir3 : fir3).
fir3(x) = (x + x' + x'') / 3;

smooth(x) = fir3(fir3(x));

process = _ <: smooth, (fir3 : fir3);

// Both writings are the same signal: 1/9, 2/9, 3/9, 2/9, 1/9 on an impulse.
// check: --double -n 6
// expect: ^0,0\.1111111111111111,0\.1111111111111111$
// expect: ^2,0\.3333333333333333,0\.3333333333333333$
// expect: ^4,0\.1111111111111111,0\.1111111111111111$
// expect: ^5,0\.0,0\.0$
