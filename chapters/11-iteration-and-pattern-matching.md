# 11. Iteration and pattern matching

## The idea

Faust has no loops that run while the program plays. It has two ways to
**build** a program by repetition, before it plays:

- **iterations**: `par`, `seq`, `sum` and `prod` repeat a block N times,
  with an index the block may use;
- **pattern matching**: a function defined by several rules, the compiler
  choosing the rule that matches the arguments, possibly recursively.

Both run in the compiler. Their arguments must be known at compile time
(chapter 9), and their result is an ordinary block diagram. Albert Gräf,
who added pattern matching to Faust, describes it as manipulating the
terms of the block-diagram algebra "at compile time".

## Iterations

([`iterations.dsp`](../examples/11/iterations.dsp))

```faust
gains   = par(i, 4, *(i + 1));          // x1, 2 x2, 3 x3, 4 x4
chain   = seq(i, 3, +(1));              // +(1) : +(1) : +(1)
total   = sum(i, 4, i * i);             // 0 + 1 + 4 + 9
product = prod(i, 3, i + 2);            // 2 * 3 * 4
```

| iteration | composition | example |
|---|---|---|
| `par(i, N, B(i))` | `B(0), B(1), ..., B(N-1)` | N channels side by side |
| `seq(i, N, B(i))` | `B(0) : B(1) : ... : B(N-1)` | a cascade of filters |
| `sum(i, N, B(i))` | `B(0) + B(1) + ... + B(N-1)` | a sum of partials |
| `prod(i, N, B(i))` | `B(0) * B(1) * ... * B(N-1)` | a product of gains |

The index goes from 0 to N − 1. `total` and `product` are constants, 14
and 24, and appear as such in the generated code.

The index may set anything in the body. Additive synthesis
([`additive.dsp`](../examples/11/additive.dsp)) sums sixteen harmonics
whose frequency and amplitude both depend on k:

```faust
additive_saw = sum(k, N, os.osc(f0 * (k + 1)) / (k + 1)) * 2 / ma.PI;
```

### The inputs of an iteration

`sum` and `prod` are parallel compositions followed by an operator: each
copy of the body brings its own inputs. An FIR filter written naively
therefore has as many inputs as taps
([`fir.dsp`](../examples/11/fir.dsp)):

```faust
c(0) = 0.25; c(1) = 0.5; c(2) = 0.25;

taps = sum(i, 3, @(i) * c(i));          // 3 inputs
fir  = _ <: taps;                        // 1 input
```

The signal must be split to all the copies first. The library's `fi.convN`
is written like `taps` and has N inputs; its documentation shows one.

## Definitions by cases

A function can be defined by several rules. The compiler tries them in the
order they are written and uses the first one whose patterns match the
arguments ([`factorial.dsp`](../examples/11/factorial.dsp)):

```faust
fact(0) = 1;
fact(n) = n * fact(n - 1);

process = fact(10);
```

`fact(10)` matches the second rule, which calls `fact(9)`, and so on until
`fact(0)` matches the first. All of this happens in the compiler: the
program outputs the constant 3628800. Gräf used this very example to
present pattern matching in Faust.

`case` writes the same rules as an expression
([`case.dsp`](../examples/11/case.dsp)):

```faust
fact = case {
    (0) => 1;
    (n) => n * fact(n - 1);
};
```

Because the first matching rule wins, special cases must come before the
general one. With the general rule first, the special ones are never
reached ([`rule_order.dsp`](../examples/11/rule_order.dsp)):

```faust
first_wins = case {
    (n) => 1;
    (0) => 2;          // never reached
};
```

The reference compiler outputs 1 for `first_wins(0)`. (faust-rs outputs 2
at the time of writing, a divergence reported to its developers; this
example is checked on the C++ output only.)

## Recursion on an integer

A recursive definition with an integer argument builds a structure whose
size is that integer. Cascading a block n times
(exercise 2) is

```faust
cascade(1, f) = f;
cascade(n, f) = f : cascade(n - 1, f);
```

which is `seq` without the index. The recursion must reach a base case
with the arguments given: chapter 9 showed what happens when n comes from a
slider.

## Patterns on lists

A parallel composition is also a list: `(a, b, c)` is `a, (b, c)`, because
the comma groups to the right. The pattern `(x, xs)` takes the first element
and the rest ([`lists.dsp`](../examples/11/lists.dsp)):

```faust
serial((x, xs)) = x : serial(xs);
serial(x) = x;

count((x, xs)) = 1 + count(xs);
count(x) = 1;

rev((x, xs)) = rev(xs), x;
rev(x) = x;
```

`serial((*(2), +(1), *(10)))` becomes `*(2) : +(1) : *(10)` (Gräf's
example, with `sin, cos, tan`); `count` gives 3 for a list of three; `rev`
reverses 1, 2, 3, 4. The elements can be numbers, signals or blocks: the
compiler matches the *terms* of the diagram, not values computed at run
time.

## Functions as data: a fold

Gräf also wrote a fold, which combines n values with a function
([`fold.dsp`](../examples/11/fold.dsp)):

```faust
fold(1, f, x) = x(0);
fold(n, f, x) = f(fold(n - 1, f, x), x(n - 1));
fsum(n) = fold(n, +);

h(i) = a(i) * os.osc((i + 1) * f0);
process = fsum(3, h);
```

Here `x` is a function, called with an index, and `f` is an operator.
`fsum(3, h)` is `h(0) + h(1) + h(2)`, exactly `sum(i, 3, h(i))`. Passing
functions as arguments is the subject of chapter 12.

## Example: the oscillator network

The idioms document ends with a program of five oscillator nodes, each
modulating the next, sent through a resonant filter
([`network_original.dsp`](../examples/11/network_original.dsp)). Each node
computes four oscillators and keeps one with `ba.selector`:

```faust
node_0 = os.osc(rfreq), os.sawtooth(rfreq), os.triangle(rfreq),
os.square(rfreq) with {
   freq = hslider("freq_node_0", 440, 1, 1000, 1);
   rfreq = freq + 10 * (node_3 : ba.selector(0, 4));
};
```

and the same text is repeated for every node. The document notes that it is
very slow to compile, and proposes a rewrite with `case`. That rewrite does
not reproduce the original: it chains three nodes instead of four, in
another order. A faithful rewrite
([`network_patterns.dsp`](../examples/11/network_patterns.dsp)):

```faust
wave(0, f) = os.osc(f);
wave(1, f) = os.sawtooth(f);
wave(2, f) = os.triangle(f);
wave(3, f) = os.square(f);

node(k, modulation, w) = wave(w, freq + 10 * modulation)
with {
    freq = hslider("freq_node_%k", 440, 1, 1000, 1);
};

filter(0, f, q) = fi.resonlp(f, q, 1.0);
filter(1, f, q) = fi.resonhp(f, q, 1.0);
filter(2, f, q) = fi.resonbp(f, q, 1.0);

node_6(w) = node(6, 0, w);
node_4(w) = node(4, node_6(0), w);
node_3(w) = node(3, node_4(0), w);
node_0(w) = node(0, node_3(0), w);
node_1(w) = node_0(3) : filter(w, freq, q)
with {
    freq = hslider("freq_node_1", 440, 50, 5000, 1);
    q = hslider("q_node_1", 0.5, 0.01, 1, 0.01);
};

process = node_1(0), node_1(0);
```

One definition, `node`, serves the five nodes; the label `"freq_node_%k"`
takes the value of `k`, so the sliders keep their names. faustprobe finds
the two programs **identical**, sample for sample, with the same six
sliders. The difference is in the compiler:

| version | C++ compilation | generated code |
|---|---|---|
| four oscillators per node, `ba.selector` | 0.72 s | 314 lines |
| pattern matching | 0.01 s | 303 lines |

The generated code is almost the same, because the unused oscillators were
already removed (chapter 9). What pattern matching saves is the work of
building, and then discarding, three oscillators per node at every use of
every node.

## The idiom in the libraries

- **Special cases first.** `si.bus` in signals.lib:
  ```faust
  bus(0) = 0:!;
  bus(1) = _;
  bus(2) = _,_;
  bus(N) = par(i, N, _);
  ```
- **Lists.** `ba.count` and `ba.take` in basics.lib are the list functions
  above:
  ```faust
  count((xs, xxs)) = 1 + count(xxs);
  count(xx) = 1;
  take(1, (xs, xxs))  = xs;
  take(1, xs)         = xs;
  take(N, (xs, xxs)) = take(N-1, xxs);
  ```
  `fi.fir` takes its coefficients as a list and walks it with a local
  recursive function:
  ```faust
  fir((b0,bv)) = _ <: *(b0), R(1,bv) :> _ with {
      R(n,(bn,bv)) = (@(n):*(bn)), R(n+1,bv);
      R(n, bn)     = (@(n):*(bn)); };
  fir(b0) = *(b0);
  ```
- **Growing structures.** `ho.encoder` in hoa.lib adds two outputs per
  order:
  ```faust
  encoder(0, x, a) = x;
  encoder(N, x, a) = encoder(N-1, x, a), x*sin(N*a), x*cos(N*a);
  ```
- **Divide and conquer.** `ro.hadamard` in routes.lib builds an N × N
  Hadamard matrix from two of size N/2:
  ```faust
  hadamard(2) = butterfly(2);
  hadamard(N) = butterfly(N) : (hadamard(N/2), hadamard(N/2));
  ```
- **Nested iterations.** `la.identity` in linearalgebra.lib:
  `identity(N) = par(i, N, par(j, N, i == j));`
- **A showcase.** `os.sawN` in oscillators.lib combines a factorial by
  pattern matching, polynomials chosen by rules and a `seq` of
  differentiators.

## Pitfalls

- **Special rules first**: the first matching rule wins.
- **An iteration multiplies inputs**: split the signal before `sum`.
- **Patterns need compile-time arguments**: a widget there makes the
  compiler loop forever (chapter 9).
- **`sum` and `prod` are keywords**: do not use them as names.

## Exercises

1. A "supersaw": N sawtooth oscillators spread around a frequency by a
   detune slider, summed and normalised, N being a constant. Solution:
   [`ex1_supersaw.dsp`](../examples/11/solutions/ex1_supersaw.dsp).
2. `cascade(n, f)`, which repeats a block n times in sequence, written with
   patterns; check that it equals `seq(i, n, f)`. Solution:
   [`ex2_cascade.dsp`](../examples/11/solutions/ex2_cascade.dsp).
3. `max_of`, the maximum of a list of signals of any length. Solution:
   [`ex3_max_of.dsp`](../examples/11/solutions/ex3_max_of.dsp).
