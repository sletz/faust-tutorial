// Two numeric types. int() truncates towards zero; % on integers is the
// integer remainder, on floats the floating remainder; integer arithmetic
// wraps around on 32 bits.
process = int(2.7), int(-2.7), 7 % 2, 7.5 % 2, 2147483647 + 1;

// check: --double -n 1 --in zero
// expect: ^0,2\.0,-2\.0,1\.0,1\.5,-2147483648\.0$
