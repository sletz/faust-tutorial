// letrec: the same states written as equations. Inside the equations a
// variable is its value at the previous sample; outside, the variable is
// its new value. 'c = c + 1 is the counter 1 : + ~ _.
counter = c letrec { 'c = c + 1; };

// The Fibonacci sequence of fibonacci.dsp, with a delayed by one sample.
fibonacci = a letrec {
    'a = b;
    'b = a + b + (1 - 1');
};

process = counter, fibonacci;

// check: --double -n 6 --in zero
// expect: ^0,1\.0,0\.0$
// expect: ^1,2\.0,1\.0$
// expect: ^5,6\.0,5\.0$
