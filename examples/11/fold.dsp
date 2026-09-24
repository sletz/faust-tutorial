// A fold written with patterns (Gräf, 2009): combine x(0), ..., x(n-1)
// with f. fsum(3, h) is h(0) + h(1) + h(2), the same as sum(i, 3, h(i)).
import("stdfaust.lib");

fold(1, f, x) = x(0);
fold(n, f, x) = f(fold(n - 1, f, x), x(n - 1));
fsum(n) = fold(n, +);

f0 = 440;
a(0) = 1; a(1) = 0.5; a(2) = 0.3;
h(i) = a(i) * os.osc((i + 1) * f0);

process = fsum(3, h) - sum(i, 3, h(i));

// check: --double --in zero -n 1000 --quiet
// expect: note: every output is exactly zero
