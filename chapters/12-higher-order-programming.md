# 12. Higher-order programming

## The idea

The idioms document describes Faust as a natural fit for higher-order
programming, because the language already has three orders:

- **signals** are functions of time;
- **signal processors** are functions of signals;
- **the block-diagram algebra** combines signal processors into new ones.

Higher-order programming uses functions as values: functions that take
blocks as arguments, functions that return blocks, blocks built on the fly
with no name. Faust programs written this way are shorter, and the
libraries are full of them.

## Blocks as arguments

A function can take a block and do something with it
([`blocks_as_arguments.dsp`](../examples/12/blocks_as_arguments.dsp)):

```faust
twice(f) = f : f;
stereo(f) = f, f;

process = twice(*(3)), stereo(fi.pole(0.5));
```

`twice(*(3))` multiplies by 9, and `stereo(fi.pole(0.5))` is a stereo
filter made from a mono one. Chapter 3's `mean(x) = x :> /(outputs(x))`
already took a block as argument.

Arguments *are* blocks, and the 2003 tutorial warns that this can surprise
([`arguments_are_blocks.dsp`](../examples/12/arguments_are_blocks.dsp)):

```faust
A(x, y) = (x, y) : (y, x);
process = 1, 2 : A(*(10), *(100));
```

`A` looks like a swap, but `(x, y) : (y, x)` with blocks for `x` and `y` is
`(*(10), *(100)) : (*(100), *(10))`: the two values are multiplied by 1000
and 2000, not exchanged. A name in Faust stands for a block, wherever it
appears.

## Functions without names

`\(x).(expression)` is a **lambda abstraction**, a function that has no
name ([`lambda.dsp`](../examples/12/lambda.dsp)):

```faust
square = \(x).(x * x);
add = \(x, y).(x + y);
adder(n) = \(x).(x + n);
add3 = adder(3);
```

`adder(n)` returns a function, and `add3` is that function for n = 3:
`add3(4)` is 7. Every named definition with arguments is in fact a lambda:
`square(x) = x * x` means `square = \(x).(x * x)`.

Lambdas are most useful where a small function is needed once, typically
as the body of a recursion. The library's countdown of chapter 6 is one:

```faust
countdown(n, trig) = \(c).(if(trig>0, n, max(0, c-1))) ~ _;
```

The lambda names the state `c`, which `~ _` feeds back, and the body reads
like the equation of the next state.

## Partial application

Giving a function fewer arguments than it takes gives a block that expects
the missing ones on its inputs (chapter 3). This turns general functions
into specific blocks ([`partial_application.dsp`](../examples/12/partial_application.dsp)):

```faust
db2linear = pow(10, /(20.0));          // Den Haag, 2006: 10^(x/20)
clip(lo, hi, x) = max(lo, min(hi, x));
soft = clip(-0.5, 0.5);                // a block with one input
kilo = *(1e3);                         // units, as in tonestacks.lib
```

`pow(10, /(20.0))` is a nice case: its second argument is itself a block,
`/(20.0)`, whose input becomes the input of the whole.

## The parameter-order convention

Partial application only fills arguments from the left. The contribution
guide of faustlibraries therefore asks that functions put their most
constant parameters first and the audio signal last, and gives the example
`clip(low, high, x)`: `clip(-1, 1)` is then a block usable anywhere
([`parameter_order.dsp`](../examples/12/parameter_order.dsp)):

```faust
gain_last(g, x) = x * g;        // gain_last(0.5) is a block
gain_first(x, g) = x * g;       // gain_first(_, 0.5) is needed instead
```

Most library functions follow it: `fi.lowpass(N, fc)`, `de.delay(N, d)`,
`si.smooth(s)`, `ba.bypass1(bpc, e)` all take their signal last. The few
that do not are harder to combine: maxmsp.lib's `mm.LPF(x, f0, gain, Q)`
takes the signal first, to match Max/MSP.

## Closures

A block built inside a function keeps the values it was built with
([`closure.dsp`](../examples/12/closure.dsp)):

```faust
voice(i) = os.sawtooth(base * ratio) * level
with {
    ratio = 1 + 0.01 * i;
    level = hslider("level %i", 0.25, 0, 1, 0.01);
};

process = sum(i, 4, voice(i));
```

Each voice has its own detune and its own slider, named after `i`: the
definitions of the `with` block are evaluated for each `i`, and each voice
carries its own. This is how the `*_demo` functions of chapter 8 attach an
interface to a library function.

## The idiom in the libraries

**Operators as arguments.** `fi.fb_comb_common` in filters.lib takes the
delay operator itself as argument, and `fi.fb_comb` passes a partial
application of `de.delay` ([`library_hof.dsp`](../examples/12/library_hof.dsp)):

```faust
fb_comb_common(dop,N,b0,aN) = + ~ aN * dop(N-1) : *(b0);
fb_comb(maxdel,del,b0,aN) = fb_comb_common(de.delay(maxdel),del,b0,-aN) : mem;
```

The same comb works with `@`, with `de.delay(maxdel)` or with a
fractional delay. Note `dop(N-1)`: the library handles the implicit sample
of `~` (chapter 4).

**Repeating a block.** `si.repeat(n, FX)` chains n copies of FX and sums the
output of every stage; it sizes its buses with `outputs(FX)`:

```faust
repeat(1, FX) = FX;
repeat(n, FX) = FX <: si.bus(N), repeat(n-1, FX) :> si.bus(N)
with {
    N = outputs(FX);
};
```

With `*(2)`, three stages give 2x + 4x + 8x = 14x.

**Reducing with an operator.** `ba.parallelOp(op, n)` combines n signals with
any binary operator:

```faust
parallelOp(op,1) = _;
parallelOp(op,2) = op;
parallelOp(op,n) = op(parallelOp(op,n-1));
```

`ba.parallelOp(max, 4)` is the maximum of four signals, `ba.parallelOp(+, 4)`
their sum. reducemaps.lib's `rm.parReduce` does the same as a balanced tree.

**Specialising by partial application.** Many library functions are one
line:

```faust
fdelay1 = fdelayltv(1);                       // delays.lib
low_shelf  = lowshelf(3);                     // filters.lib
compressor_mono = compressor_lad_mono(0);     // compressors.lib
```

Chapter 14 builds on this.

**Functions as parameters.** `ba.bypass_fade(n, b, e)` crossfades around
any effect `e`, sizing itself with `inputs(e)` and `outputs(e)`; the
compressors of compressors.lib take a `meter` function to display their
gain reduction; `pm.formantFilterbank` takes the function that builds one
formant filter.

## Pitfalls

- **Arguments are blocks**, not values: a "swap" of blocks composes them.
- **Partial application fills from the left**: put the signal last in your
  own functions.
- **Argument order varies in the libraries**: `ba.take(P, l)` takes the
  position first, `ba.pick(l, n)` the list first; `ba.selector(i, n)` the
  index first, `ba.selectn(N, i)` the count first. Check the usage line.

## Exercises

1. `dry_wet(mix, fx)`, a dry/wet mix around any mono effect given as
   argument. Check it with an effect that inverts the signal. Solution:
   [`ex1_dry_wet.dsp`](../examples/12/solutions/ex1_dry_wet.dsp).
2. `feedback(g, fx)`, a feedback loop of gain g around any block; with a
   delay it is an echo, with a lowpass filter a resonance. Solution:
   [`ex2_feedback.dsp`](../examples/12/solutions/ex2_feedback.dsp).
3. `map(f, list)`, which applies a function to every element of a list.
   Solution: [`ex3_map.dsp`](../examples/12/solutions/ex3_map.dsp).
