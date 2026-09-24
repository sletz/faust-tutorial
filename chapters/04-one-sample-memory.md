# 4. One-sample memory

## The idea

So far every output sample depended only on the input samples of the same
instant. Most of signal processing needs more: an echo needs the input of
half a second ago, a filter needs its own previous outputs, a counter needs
the value it had one sample earlier.

Faust gives exactly two ways to reach the past, and no way to reach the
future:

- **delays**, which read the past of a signal: `mem`, the prime `'`, `@`;
- **recursion** `~`, which feeds the past of an output back into the
  computation.

Every state in a Faust program, every counter, envelope, oscillator or
filter, is built from these two. The idioms document puts it this way: a
change of state is "how to compute the next sample as a function of the
previous samples and a set of intermediate values".

## Delays

([`delays.dsp`](../examples/04/delays.dsp))

```faust
delays(x) = x, mem(x), x'', x@3;
process = delays;
```

`mem` is a block that delays its input by one sample. `x'` is the same thing
written after a signal, `x''` delays by two, and `x@n` by n samples. An
impulse sent into `delays` walks along the four outputs, one sample at a
time. Before the signal has arrived, a delay outputs 0: every delay line
starts empty.

Two classics follow immediately. The first difference tells how much the
signal changed since the last sample
([`difference.dsp`](../examples/04/difference.dsp)):

```faust
diff(x) = x - x';
```

and a constant minus the same constant delayed is 1 at the very first
sample and 0 afterwards: an impulse, which the library calls `os.impulse`
([`impulse.dsp`](../examples/04/impulse.dsp)):

```faust
process = 1 - 1';
```

## Recursion

`A ~ B` connects the outputs of A back to its inputs, through B. Two rules
make it work:

1. the outputs of A go through B and arrive on the **first** inputs of A;
   the remaining inputs of A stay free and become the inputs of the whole
   block;
2. the feedback path always contains **one sample of delay**: what comes
   back is the output of the *previous* sample. Without it the output would
   depend on itself at the same instant, which cannot be computed.

The smallest recursion is the integrator
([`integrator.dsp`](../examples/04/integrator.dsp)):

```faust
process = + ~ _;
```

`+` has two inputs. The feedback `_` takes its output and brings it back,
one sample later, to the first input; the second input is the input of the
program. In equations: y[n] = x[n] + y[n-1], with y[-1] = 0. An impulse
becomes a step (1, 1, 1...), a constant becomes a ramp (1, 2, 3...).

Feeding the constant 1 to the integrator gives a counter
([`counter.dsp`](../examples/04/counter.dsp)):

```faust
count = 1 : + ~ _;              // 1, 2, 3, ...
process = count, ba.time;       // ba.time is 0, 1, 2, ...
```

The counter starts at 1: the state starts at 0, and the first sample already
adds 1. The library's `ba.time` is the same counter delayed by one sample,
so that it starts at 0.

## Delay and recursion together

The idioms document gives the sum of the last n samples
([`moving_sum.dsp`](../examples/04/moving_sum.dsp)):

```faust
moving_sum(n, x) = +(x - x@n) ~ _;
```

At each sample, the new input enters the sum and the one that is n samples
old leaves it. With a constant 1, the sum climbs to n and stays there. The
cost is one addition and one subtraction per sample, whatever n.

A recursion with a gain in the feedback path is a filter. The one-pole
lowpass ([`one_pole.dsp`](../examples/04/one_pole.dsp)):

```faust
lowpass1(a) = *(1 - a) : + ~ *(a);
```

computes y[n] = (1 − a) x[n] + a y[n−1]. Its impulse response is 0.5, 0.25,
0.125... for a = 0.5: each sample keeps half of the previous one. The input
gain 1 − a makes the output of a constant equal to that constant.

## The implicit delay in a loop

Because the feedback path already holds one sample, a delay of d samples in
the loop is written `@(d - 1)`
([`delay_in_loop.dsp`](../examples/04/delay_in_loop.dsp)):

```faust
echo(d, g) = + ~ (@(d - 1) : *(g));
process = echo(4, 0.5);
```

The echoes come at samples 0, 4, 8..., halving each time. Writing `@(d)`
would place them at 0, 5, 10: a classic off-by-one.

## The idiom in the libraries

The blocks of this chapter are, almost literally, library functions.

| library function | definition | file |
|---|---|---|
| `os.impulse` | `impulse = 1-1';` | oscillators.lib |
| `fi.integrator` | `integrator = + ~ _;` | filters.lib |
| `fi.pole` | `pole(p) = + ~ *(p);` | filters.lib |
| `fi.zero` | `zero(z) = _ <: _,mem : _,*(z) : -;` | filters.lib |
| `ba.time` | `time = +(1)~_ : mem;` | basics.lib |
| `ma.diffn` | `diffn(x) = x' - x;` (the difference, negated) | maths.lib |

With them the one-pole lowpass is `*(1 - a) : fi.pole(a)`, and faustprobe
confirms that it is identical to the hand-written version
([`pole_library.dsp`](../examples/04/pole_library.dsp)). `si.smooth(s)`,
the smoother that every library uses to remove the clicks of a moving
slider, is the same one-pole filter. The pseudo-random generator behind
`no.noise` is a recursion too:

```faust
random = +(seed) ~ *(1103515245);
```

It multiplies the previous value by a large integer and adds a seed; the
integer overflow does the scrambling. Chapter 7 comes back to it.

## Pitfalls

- **The off-by-one in a loop.** `~` adds one sample of delay; count it.
- **The first sample.** Every delay and every recursion starts from 0. A
  counter written `1 : + ~ _` starts at 1, not 0.
- **Recursive sums drift.** `moving_sum` adds and subtracts forever, and the
  rounding errors never cancel exactly. On white noise, the difference
  between `moving_sum(4)` and the direct sum `x + x' + x'' + x@3`:

  | duration | single precision | double precision |
  |---|---|---|
  | 1 s | 5.7e-6 | 1.4e-14 |
  | 10 s | 2.2e-5 | 3.2e-14 |
  | 100 s | 1.3e-4 | 1.1e-13 |

  The error is a random walk: it grows without bound. For a small window,
  write the direct sum (chapter 11 shows how with `sum`); for a large one,
  compute in double precision or reset the sum from time to time. The
  library's `ba.slidingSum` documents the same drift.
- **The name `sum` is taken**: it is a keyword of the language (chapter 11),
  which is why the moving sum above is not called `sum`.

## Exercises

1. A DC blocker: the first difference followed by a leaky integrator
   `+ ~ *(p)` with p = 0.995. Check that a constant input dies out.
   Solution: [`ex1_dcblocker.dsp`](../examples/04/solutions/ex1_dcblocker.dsp).
2. A counter that goes 0, 1, ..., n−1, 0, 1, ... without its state ever
   growing. Solution: [`ex2_wrap_counter.dsp`](../examples/04/solutions/ex2_wrap_counter.dsp).
3. The moving average of the last n samples. Solution:
   [`ex3_average.dsp`](../examples/04/solutions/ex3_average.dsp).
