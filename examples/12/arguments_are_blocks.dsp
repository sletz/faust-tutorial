// "Arguments are blocks" (Gaudrain and Orlarey, 2003): A looks like a swap,
// but its arguments are blocks, and (x, y) : (y, x) composes them.
A(x, y) = (x, y) : (y, x);

process = 1, 2 : A(*(10), *(100));

// (1, 2) : (*(10), *(100)) : (*(100), *(10)) gives 1000 and 2000.
// check: --double -n 1 --in zero
// expect: ^0,1000\.0,2000\.0$
