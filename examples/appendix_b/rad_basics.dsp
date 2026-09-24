// Reverse mode (faust-rs only): rad(loss, seeds) outputs the loss followed by
// its gradient with respect to each seed. For a squared error between a
// model a * x + b and a target:
// cpp: no
a = hslider("a", 1, -4, 4, 0.001);
b = hslider("b", 0, -4, 4, 0.001);

loss(x, target) = (a * x + b - target) ^ 2;

process = rad(loss(2, 5), (a, b));

// With a = 1, b = 0: error 2 - 5 = -3, loss 9, gradients 2 * -3 * 2 = -12
// and 2 * -3 = -6.
// check: --double -n 1 --in zero
// expect: ^0,9\.0,-12\.0,-6\.0$
