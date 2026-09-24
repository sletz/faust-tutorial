# 6. Logical signals and events

## The idea

A large part of Faust programming is not signal processing in the textbook
sense: it is building the signals that *drive* the processing. A button
press must start an envelope, a clock must advance a sequencer, a level
above a threshold must open a gate. These signals are made of **events**
(something happens at one sample) and **conditions** (something is true
during a stretch of samples).

Faust has no special type for them. A condition is a signal that is 1 when
it holds and 0 otherwise; an event is a condition that holds for one
sample. Everything in this chapter is built from comparisons, arithmetic,
`mem` and `~`.

## Booleans are numbers

Comparisons (`<`, `<=`, `>`, `>=`, `==`, `!=`) return 0 or 1, and logic
operators combine them ([`booleans.dsp`](../examples/06/booleans.dsp)):

```faust
process = a & b, a | b, xor(a, b), min(a, b), max(a, b), 1 - a, (a > 0.5) + (b > 0.5);
```

For signals that are 0 or 1, `min` is an AND, `max` is an OR and `1 - a` is
a NOT. And because they are numbers, conditions can be added (how many
hold?), multiplied by a signal (let it through or not) or integrated (for
how long has it held?).

## Edges

An event is detected by comparing a signal with itself one sample earlier.
The idioms document lists the detectors
([`edges.dsp`](../examples/06/edges.dsp)):

```faust
upfront(x)   = x > x';     // 1 on a rising edge
downfront(x) = x < x';     // 1 on a falling edge
front(x)     = x != x';    // 1 on any change
```

and their negations (`x <= x'`, `x >= x'`, `x == x'`), which are 1 everywhere
except on an edge. A button pressed at frame 3 and released at frame 6 gives
a rising edge at 3 and a falling edge at 6, each one sample long.

`line~` in chapter 5 used `value != value'` to restart its ramp: a change of
target is an event.

## From event to duration: `release` and `trigger`

The idioms document quotes three definitions from "A Faust Tutorial"
(Gaudrain and Orlarey, 2003) that turn an event into a gate of a given
length. In the idioms document the first one looks truncated, because the
underscores were lost when the text was copied out of the PDF. The
original reads

```faust
impulse = _ <: _, mem : - : (_ > 0.0);
```

and the 2003 tutorial explains it: "The difference between the original and
the dephased signal produces a signal with two pulses large of one sample at
the pulse edges. The greater-than box just let the first positive pulse."
The idioms document simplifies it to `impulse(x) = x - x' > 0.0` and then
`impulse(x) = x > x'`, the rising edge; the three are the same block
([`impulse_forms.dsp`](../examples/06/impulse_forms.dsp)). Then:

```faust
release(n) = + ~ (_ <: _, (_ > 0) / n : -);
trigger(n) = impulse : release(n) : >(0);
```

(the original writes the last step `_>0`, the same block as `>(0)`).

`release(n)` integrates its input but subtracts 1/n at every sample while
the value is positive: an impulse of 1 becomes a ramp down to 0 in n
samples. `trigger(n)` is 1 while that ramp is positive: in the words of
the 2003 tutorial, "a Heaviside unit step which duration is controlled by
the formal parameter n".

This is where measuring pays. After three steps of 1/3 the value should be
exactly 0, but floating-point rounding leaves 1.1e-16
([`release.dsp`](../examples/06/release.dsp)):

```text
frame 3    1.1102230246251565e-16
frame 4   -0.3333333333333332       <- one more step, then stuck below 0
```

The value is still "positive", so `release` subtracts 1/3 once more and
stays at −1/3 forever. The idioms document rewrites `release` with
`max(0, x - 1/n)`, which stops at 0: the two versions are **not**
equivalent, and only the second one is safe. But both keep the 1.1e-16 for
one sample, so `trigger(3)` lasts 4 samples instead of 3
([`trigger.dsp`](../examples/06/trigger.dsp)).

The robust way is to count whole samples, which floating point represents
exactly up to 2^24 in single precision:

```faust
countdown(n) = *(n) : + ~ (-(1) : max(0));
trigger_exact(n) = impulse : countdown(n) : >(0);
```

The event sets the count to n, and each sample subtracts 1 until 0.
`trigger_exact(3)` lasts exactly 3 samples. The lesson generalises: **never
rely on a sum of fractions landing exactly on a value**; count integers, or
compare with a margin.

A second event during the gate raises another question: should it extend
the gate or restart it? `release` and `countdown` *add* the new count to
what is left: with n = 100 and presses at frames 1000 and 1050, the gate
lasts until frame 1199. A countdown that sets its state to n on each event
restarts instead, and ends at 1149
([`retrigger.dsp`](../examples/06/retrigger.dsp)):

```faust
restart(n) = loop ~ _ with { loop(left, t) = ba.if(t, n, max(0, left - 1)); };
```

Both are useful; the point is to choose, and to check which one a library
function implements.

## Resetting by multiplication

Multiplying a state by `(1 - reset)` inside its loop sends it back to 0
while `reset` is 1 ([`reset.dsp`](../examples/06/reset.dsp)):

```faust
counter = (+(1) : *(1 - reset)) ~ _;
```

The counter runs, drops to 0 on the reset, and starts again from 1. The
same trick with `*(gate == 0)` gives a counter that runs only while a gate
is released: this is how the envelopes of envelopes.lib measure the time
since the key was released.

## Holding a value

`select2(c, a, b)` outputs `a` when `c` is 0 and `b` when `c` is 1. Put in a
recursion, it chooses between the previous output and the input
([`sample_and_hold.dsp`](../examples/06/sample_and_hold.dsp)):

```faust
hold(t) = select2(t) ~ _;
```

While `t` is 0 the output keeps its value; while `t` is 1 it follows the
input. With a one-sample trigger this is a sample-and-hold; the library
calls it `ba.sAndH`. Holding the phase of a ramp at the instant of a button
press gives the value of the ramp at that frame, forever after.

## Choosing: `select2` and `ba.if`

`ba.if(cond, then, else)` is `select2(cond, else, then)` with the branches
in the usual order. Both **compute both branches** at every sample; only the
choice is conditional. That is harmless as long as the choice is made by
`select2`, which never looks at the discarded value, even an infinite one.
It is not harmless when the choice is made by arithmetic
([`select.dsp`](../examples/06/select.dsp)):

```faust
safe_inverse = ba.if(x == 0, 0, 1 / x);
arithmetic_inverse = (x == 0) * 0 + (x != 0) * (1 / x);
```

At x = 0, the first gives 0; the second gives 0 × ∞, which is NaN, and
faustprobe refuses the render. Choose with `select2`, not with a product,
when a branch can be infinite.

## Counting events

The idioms document counts the changes of a MIDI clock over the last second
([`clock_counter.dsp`](../examples/06/clock_counter.dsp)):

```faust
front(x) = (x - x') != 0.0;
per_second(x) = (x - x@ma.SR) : + ~ _;      // moving sum over one second

process = os.lf_squarewave(12) : front : per_second;
```

`per_second` is the moving sum of chapter 4 with a window of one second. A
square wave at 12 Hz changes 24 times per second, the rate of a MIDI clock
at 60 beats per minute, and the count settles at 24. In the idioms document
the clock comes from a checkbox labelled `[midi:clock]`, which a MIDI
architecture flips at every clock message; chapter 8 covers such labels.

## The idiom in the libraries

| library function | definition | what it shows |
|---|---|---|
| `ba.counter` | `counter(trig) = upfront(trig) : + ~ _ with { upfront(x) = x > x'; };` | counting rising edges |
| `ba.sAndH` | `sAndH(trig) = select2(trig) ~ _;` | holding |
| `ba.toggle` | `toggle = trig : loop with { trig(x) = (x-x') == 1; loop = != ~ _; };` | a flip-flop |
| `ba.peakhold` | `peakhold = (*,_ : max) ~ _;` | `max` as a memory |
| `ba.countdown` | `countdown(n, trig) = \(c).(if(trig>0, n, max(0, c-1))) ~ _;` | exact countdown |
| `ba.impulsify` | `impulsify = _ <: _,mem : - <: >(0)*_;` | positive part of the difference |

A detail about `ba.impulsify`: it outputs the size of the rise, not the
value of the signal ([`impulsify.dsp`](../examples/06/impulsify.dsp)). A
signal that climbs to 0.3 then 0.5 gives spikes of 0.3 and 0.2, not 0.3 and
0.5.

In envelopes.lib, `en.adsr` counts the samples since the release with
`(+(1) : *(gate == 0)) ~ _`, and `en.adsre` counts the samples since the
key was pressed with `ugate : +~(*(ugate))`: the gate itself is both the
increment and the reset.

## Pitfalls

- **Floating-point landings.** A value built by adding fractions is almost
  never exactly 0 or 1. Count integers, or compare with a margin.
- **Selecting by arithmetic** propagates NaN and infinity from the
  discarded branch. Use `select2` or `ba.if`.
- **Both branches are computed.** `ba.if` does not save work; chapter 9
  shows how to choose at compile time instead.
- **Negative zero.** `>(0) * x` on a negative `x` gives −0.0, which prints
  with its sign but compares equal to 0.

## Exercises

1. A toggle: each press of a button flips the output between 0 and 1.
   Solution: [`ex1_toggle.dsp`](../examples/06/solutions/ex1_toggle.dsp).
2. Count the presses of a button, with a second button that resets the
   count. Solution: [`ex2_press_counter.dsp`](../examples/06/solutions/ex2_press_counter.dsp).
3. A retriggerable gate of exactly 100 ms after each press: 4800 samples at
   48 kHz, not one more. Solution:
   [`ex3_monostable.dsp`](../examples/06/solutions/ex3_monostable.dsp).
