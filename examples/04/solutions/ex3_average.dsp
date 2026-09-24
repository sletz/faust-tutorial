// Exercise 3: the moving average of the last n samples.
moving_sum(n, x) = +(x - x@n) ~ _;
moving_average(n) = moving_sum(n) : /(n);

process = moving_average(8);

// check: --double -n 16 --in dc
// expect: ^15,1\.0$
