// Forward-mode automatic differentiation (faust-rs only): fad(expr, seeds)
// outputs the value of expr followed by its derivative with respect to each
// seed. For x * y: the product, then y, then x.
// cpp: no
x = hslider("x", 3, 0, 10, 0.01);
y = hslider("y", 2, 0, 10, 0.01);

process = fad(x * y, (x, y));

// check: --double -n 1 --in zero
// expect: ^0,6\.0,2\.0,3\.0$
