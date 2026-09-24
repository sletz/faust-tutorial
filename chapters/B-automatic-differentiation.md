# Appendix B. Automatic differentiation

faust-rs, the Rust implementation of the Faust compiler, adds two
primitives that the C++ compiler does not have: `fad` and `rad`. They
compute derivatives of a Faust expression, exactly, at compile time, so
that a program can learn its own parameters by gradient descent. The
examples of this appendix are marked `// cpp: no` and checked with
faustprobe only.

## Forward mode: `fad`

`fad(expr, seeds)` outputs the value of `expr`, followed by its derivative
with respect to each seed ([`fad_basics.dsp`](../examples/appendix_b/fad_basics.dsp)):

```faust
x = hslider("x", 3, 0, 10, 0.01);
y = hslider("y", 2, 0, 10, 0.01);

process = fad(x * y, (x, y));      // 6, then y = 2, then x = 3
```

The derivatives go through everything: delays, recursions (chapter 4),
tables (chapter 10). `fad` suits a few parameters and a derivative used
inside the program.

## Reverse mode: `rad`

`rad(loss, seeds)` outputs a scalar loss followed by its gradient with
respect to each seed ([`rad_basics.dsp`](../examples/appendix_b/rad_basics.dsp)):

```faust
loss(x, target) = (a * x + b - target) ^ 2;
process = rad(loss(2, 5), (a, b));   // 9, then -12 and -6
```

`rad` suits one loss and many parameters. Through delays and recursions it
differentiates over each block of samples, and its gradient outputs are
contributions to be summed over the block.

## Learning a coefficient

A one-pole filter with an unknown pole, learned from a target
([`train_pole.dsp`](../examples/appendix_b/train_pole.dsp)):

```faust
a = hslider("a", 0.5, 0, 0.99, 0.0001);

model  = fi.pole(a);
target = fi.pole(0.9);

process = _ <: model, target : - : ^(2) : rad(_, a);
```

The program outputs the squared error and its gradient; a host, here
faustprobe, runs the descent:

```bash
faustprobe --double --in white:1 --block 256 --train a --fd-check --blocks 0 train_pole.dsp
faustprobe --double --in white:1 --block 256 --train a --lr 0.01 --blocks 800 train_pole.dsp
```

The first command compares the gradient with finite differences: they
agree to 1e-12. The second finds `a = 0.9`.

## A program that learns inside itself

The learned value can also be recursive state, updated at every sample by
the program itself ([`fad_self_training.dsp`](../examples/appendix_b/fad_self_training.dsp)):

```faust
learned_gain = step ~ _
with {
    step(previous) = previous - rate * gradient
    with {
        rate = 0.01;
        loss = (true_value - input * previous) ^ 2;
        gradient = fad(loss, previous) : !, _;
    };
};
```

This is the `tick ~ _` pattern of chapter 5 with a gradient step as the
update. The learned gain reaches its target within 2000 samples.

## Further reading

The faust-rs repository documents both primitives in
`docs/fad-rad-synthesis-en.md`, and the faust-diff projects apply them to
real calibrations: an amplifier model, a feedback delay network reverb
fitted to measured rooms.
