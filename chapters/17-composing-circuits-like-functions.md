# 17. Composing circuits like functions

## The idea

Faust is a functional language, of the family of Haskell and OCaml: a
program is a set of definitions, and a definition gives a name to a value.
What makes it a language for audio is the kind of value it handles: a
**circuit**, a block that turns signals into signals. Chapter 12 counted
three orders, signals, signal processors and the algebra that combines
them. This chapter draws the consequence. A circuit is a function, so
everything a functional language offers to build functions out of functions
builds circuits out of circuits: circuits are composed the way functions
are, higher-order functions included.

Most other audio languages are languages of **steps**. In
[Cmajor](https://cmajor.dev) and [Onda](https://onda-lang.org), two recent
and carefully designed ones, a program says what to do at each sample: read
the input, update some variables, write the output. The difference with
Faust is not a matter of syntax. It lies in where the memory of a program
is kept: in variables that the program modifies, or nowhere that the
program can modify. This chapter writes the same small circuits on both
sides, to show how much follows from that single difference. What is kept
on one side and lost on the other has a name, **referential transparency**.

The Cmajor programs are in `examples/17/cmajor/`. They were compiled by
`cmaj` 1.0.3209 and run on an impulse by
[`scripts/check_cmajor.py`](../scripts/check_cmajor.py) (`make cmajor`),
and the messages quoted are that compiler's. Onda is described from its
[language guide](https://onda-lang.org/docs/language/) as read in November
2026: its fragments follow the guide and were not run, and neither were the
lines of Haskell and OCaml.

## A step or a definition

The one-pole lowpass of chapter 4 in Cmajor
([`one_pole.cmajor`](../examples/17/cmajor/one_pole.cmajor)):

```cpp
processor OnePole (float a)
{
    input stream float in;
    output stream float out;

    float y;

    void main()
    {
        loop
        {
            y = (1.0f - a) * in + a * y;
            out <- y;
            advance();
        }
    }
}
```

and in Onda:

```text
proc OnePole:
  ins 1
  outs 1

  params:
    a = 0.5

  init:
    y = 0.0

  sample:
    y = (1.0 - a) * in1 + a * y
    out1 = y
```

Both say the same thing: there is a variable `y`, and at every sample its
content is replaced. In `y = ... + a * y`, the `y` on the right is the old
content and the `y` on the left the new one. `=` is an order given to the
machine, not an equation: read as one, the line would say that y is the
input. The program is a recipe, carried out in time.

In Faust ([`equation.dsp`](../examples/17/equation.dsp)):

```faust
lowpass1(a) = *(1 - a) : + ~ *(a);
```

There is no variable and no instant. The definition describes the output
as a whole signal: the y such that y = (1 − a) x + a y', where y' is y
delayed by one sample, the delay that `~` puts on the way back. Here `=` is
an equality between signals, true at every sample. A Haskell programmer
would write the same definition on lazy lists, `0 : y` being y delayed:

```haskell
y = zipWith (+) (map (* (1 - a)) x) (map (* a) (0 : y))
```

The Cmajor and Faust programs compute the same samples, 0.5, 0.25,
0.125... on an impulse, and the code that Faust generates holds the same
variable as the Cmajor source. Faust programs do have state, and chapter 5
is about it. What they do not have is **assignment**: the state is the past
of a signal, which a program can read (`'`, `@`, `~`) and can never modify.
Everything below follows from this.

## One name, one signal

In a language of steps a name such as `lp` designates an **instance**, a
filter with its variable, and using it is an event: the filter moves. With
a node `lp = OnePole (0.5f)`, the loop of this Cmajor processor feeds one
input to one filter twice in a frame, and subtracts the two results
([`stepped_twice.cmajor`](../examples/17/cmajor/stepped_twice.cmajor)):

```cpp
lp.in <- in;
lp.advance();
let a = lp.out;

lp.in <- in;
lp.advance();
let b = lp.out;

out <- a - b;
advance();
```

It compiles, and an impulse gives −0.25, 0.1875, 0.046875...: `a` and `b`
are the same filter applied to the same input, and they differ, because the
filter advanced between them. Cmajor's guide warns that a node which is not
advanced as it should gives surprising results. Onda's notation tells the
two acts apart, `lp(in1)` stepping a processor and `lp.out1` reading its
last output without stepping it. Inside the body of a processor, in both
languages, stepping every instance exactly once per sample is the
programmer's job; their graphs, below, do it for them.

In Faust a name designates a function, and a function applied to a signal
gives a signal, always the same one
([`same_signal.dsp`](../examples/17/same_signal.dsp)):

```faust
lp = lowpass1(0.5);

process = _ <: (lp, lp : -), (lp, lp : ==);
```

The difference is zero and the comparison is true, and the compiler knows
it: the generated code writes the constants 0 and 1 to the two outputs
(`output0[i0] = static_cast<FAUSTFLOAT>(0);` for the first), with no filter
left. The same holds for a generator ([`same_noise.dsp`](../examples/17/same_noise.dsp)):
`no.noise - no.noise` is silence, because `no.noise` is not a call that
draws a number, it is one signal. Two noises that differ are two different
signals, which `no.multinoise(2)` provides.

So nobody declares the filters of a Faust program. Their number is not
written in the text: the compiler deduces it from the signals.

| program | memories in the generated code | why |
|---|---|---|
| `_ <: lp, lp` | 1 | one function, one input: one signal, read twice |
| `lp : lp` | 2 | the second `lp` filters another signal than the first |
| `_ <: (lp : lp), lp` | ? | exercise 1 |

The generated code shows it ([`shared.dsp`](../examples/17/shared.dsp),
[`chained.dsp`](../examples/17/chained.dsp)). In Cmajor the number of
filters is the number of `node` declarations, in Onda the number of
constructions in `init`: an instance is something the programmer creates,
names and keeps track of.

## Referential transparency

The property that `same_signal.dsp` has and `stepped_twice.cmajor` lacks
has a name: **referential transparency**. Christopher Strachey brought the
term into programming in his lecture notes of 1967, *Fundamental Concepts
in Programming Languages*, taking it from the philosopher Quine (*Word and
Object*, 1960). To find the value of an expression that contains a
sub-expression, he writes, "the only thing we need to know about the
sub-expression is its value": not the way it is written, nor the order in
which its parts are evaluated. He draws two consequences, which are the two
sides of this chapter. A name stands for the same thing each time it
occurs, and local definitions and λ-expressions, Faust's `with` and
`\(x).(...)`, can be used only because of that. And assignment destroys
the property: once variables vary, he remarks, one can no longer be sure
that `x = x` is true. `stepped_twice.cmajor` is that remark turned into a
program.

What can "its value" be for a signal, which changes at every sample? In a
language of steps, the value of `lp.out` is one number, that of the current
sample, and it depends on what was executed before: on how many times `lp`
has been advanced. In Faust the value of an expression is a block: a whole
signal, from the first sample on, when the expression has no input, and a
function from signals to signals otherwise. Time is inside the value, not
around its evaluation. This is how a language whose programs have memory
can be referentially transparent. Lustre, a synchronous dataflow language
designed for control systems, made the same choice, its variables denoting
sequences, and calls the result its *substitution principle* (Halbwachs,
Caspi, Raymond and Pilaud, 1991): in a definition `X = E`, X may replace E
anywhere in the program and conversely, so that the definitions can come in
any order, and any sub-expression can be given a name, without changing the
program. The definitions of a Faust program obey it as well.

Søndergaard and Sestoft (1990) noticed that three properties go under this
one name, and that a language may have one without the others as soon as an
expression can have several values (think of a call that draws a random
number):

| property | what it says | where in this chapter |
|---|---|---|
| definiteness | a name stands for one value at each of its occurrences: `x - x` is 0 | the previous section |
| unfoldability | a call can be replaced by the body of the function, with the arguments in place of the parameters | the next section |
| referential transparency proper | a sub-expression can be replaced by another one that has the same value | "Laws" |

Faust has the three. None of its expressions has several values: its
noise itself is a signal, fixed once and for all.

## Functions that remember

Since using a filter changes it, a filter cannot be a function in a
language of steps, and both languages say so. Cmajor's guide requires the
functions used in a graph to be pure, and gives the FIR filter as what such
a function cannot be, since it would depend on earlier inputs. Onda's guide
states that top-level functions do not capture run-time state, and presents
`proc` as its reusable stateful unit. Each language therefore has two kinds
of reusable pieces, and two ways to combine them:

| | has memory of its own | used by | combined by |
|---|---|---|---|
| a function | no | calling it | expressions |
| a processor (`processor`, `proc`) | yes | declaring an instance of it | wiring instances in a graph, or stepping them in a body |

Faust has one kind. The FIR filter is a function
([`fir_function.dsp`](../examples/17/fir_function.dsp)):

```faust
fir3(x) = (x + x' + x'') / 3;

smooth(x) = fir3(fir3(x));

process = _ <: smooth, (fir3 : fir3);
```

`fir3` has memory, and it is called inside an expression as `sin` or `max`
would be. Both outputs are the same signal, 1/9, 2/9, 3/9, 2/9, 1/9 on an
impulse. Chapter 3 gave the reason: for a signal `x`, `f(x)` and `x : f`
are the same block. Applying a function *is* connecting a circuit. Any part of a program, with
or without memory, can therefore be given a name and parameters, and be
used as many times as needed, with no instance to create and no decision
about who owns its state.

This is the unfoldability of the table above: a call can be replaced by the
body of the function, and a name by its definition, without changing the
program. The compiler's first step does it to the whole text (chapter 9).
Done by hand on `chained.dsp`, it gives
([`unfolded.dsp`](../examples/17/unfolded.dsp)):

```faust
process = (*(1 - 0.5) : + ~ *(0.5)) : (*(1 - 0.5) : + ~ *(0.5));
```

The samples are the same, bit for bit, and so are the lines of generated
code. A name in Faust is an abbreviation: it creates no object, and it can
always be removed.

## A list of wires or an expression

To put processors together, Cmajor and Onda have a second, declarative
notation: the graph. In Cmajor
([`twice.cmajor`](../examples/17/cmajor/twice.cmajor)):

```cpp
graph Twice (processor P)
{
    input stream float in;
    output stream float out;

    node first = P, second = P;

    connection in -> first -> second -> out;
}
```

and two filters in series in Onda, where the instances are made in `init`:

```text
init:
  first = OnePole()
  second = OnePole()

graph:
  in1 >> first.in1
  first.out1 >> second.in1
  second.out1 >> out1
```

A graph is a list: instances with names, then wires between their named
ports. It steps every node once, in the right order, and asks for a delay
in a loop between nodes, so the hazard of the previous section is gone. The
Faust text is `lp : lp`: no instance, no port name, and above all an
**expression**, whose value is a block like its two halves and can go
wherever a block can.

Cmajor's `Twice` goes further than a fixed list: its parameter `P` is a
processor, in the manner of a C++ template. `Twice (Twice (OnePole (0.5f)))`
is accepted and gives 0.0625, 0.125, 0.15625, 0.15625..., the samples of
the Faust version ([`twice.dsp`](../examples/17/twice.dsp)):

```faust
twice(f) = f : f;

chain(1, f) = f;
chain(n, f) = f : chain(n - 1, f);

process = _ <: twice(twice(lowpass1(0.5))), chain(4, lowpass1(0.5)), seq(i, 4, lowpass1(0.5));
```

This is higher-order composition, and it is worth knowing that Cmajor has
it. The next steps show where it stops (answers of `cmaj` 1.0.3209):

| to write | Faust | Cmajor |
|---|---|---|
| n stages by recursion | `chain(n, f)` above | a graph `Chain (processor P, int n)` that holds a node `Chain (P, n - 1)`: `Exceeded the maximum number of specialised namespace instances (100) - possible namespace recursion` |
| n stages by iteration | `seq(i, n, f(i))` | a `for` among the connections: `Expected a processor name or endpoint`; a node array `P[n]` exists, and its n − 1 wires are written one by one |
| a function as argument | `matrix(n, m, c)`, below | `twice (half, x)`, where `half` is a function: `Cannot find symbol 'half'` |
| a circuit written in place | `twice(*(0.5) : mem)` | a processor is always a declaration with a name |

Onda's guide lets a function receive a processor, but what it receives is
an instance that already exists, to be stepped; functions may not be
recursive, and processors are constructed in `init`. None of this is an
oversight. In both languages a processor is declared in one notation and
used in another, and the notation in which one computes, with its loops,
tests and functions, works on numbers, not on processors. In Faust the
block is the value the language computes with. `twice(f)` gets two filters
out of one argument because `f` is the description of a circuit, not a
circuit that already exists somewhere; `twice`, `chain` and `seq` are
ordinary definitions, and a program can add as many as it needs.

## The vocabulary of functional languages

What chapters 3, 11, 12 and 13 introduced one piece at a time is the usual
equipment of a functional language, applied to circuits:

| | Haskell | OCaml | Faust |
|---|---|---|---|
| composition | `g . f` | `fun x -> g (f x)` | `f : g` |
| a function without a name | `\x -> x * x` | `fun x -> x *. x` | `\(x).(x * x)` |
| partial application | `(* 2)` | `( *. ) 2.` | `*(2)` |
| a function as argument | `twice f = f . f` | `let twice f x = f (f x)` | `twice(f) = f : f;` |
| over a list | `map f xs`, `foldr` | `List.map f xs`, `List.fold_left` | `par(i, n, f(i))`, `seq`, `sum`, `prod` |
| definition by cases | equations with patterns | `match ... with` | rules with patterns (chapter 11) |
| local definitions | `where` | `let ... in` | `with { ... }` |
| modules | modules | modules and functors | environments, `lib[N = v;]` (chapter 13) |

The five compositions of chapter 2 have their Haskell counterparts too, in
the combinators of arrows: `>>>` for `:`, `***` for `,`, `f &&& g` for
`_ <: f, g`, and `loop`, with a delay, for `~`. What Faust adds is that the
compiler evaluates all of it (chapter 9): no function is left when the
program runs.

## Circuits that take circuits

A function that takes circuits and returns a circuit is a **combinator**.
The five compositions of chapter 2 are the ones that the language provides;
a program defines its own, and three kinds cover a great deal of audio:

- one that **instantiates**: the same construction on every channel, each
  channel knowing its rank;
- one that **changes the representation**: go where the process is simple,
  apply it, come back;
- ones that **assemble**: processes side by side, a matrix, a loop.

Five definitions, with `fx` for the process:

```faust
// one block per channel: channel b among B gets the block mk(b, B)
each(B, mk) = par(b, B, mk(b, B));

// go to another representation with T, process there with fx, come back with Tinv
inDomain(T, fx, Tinv) = T : fx : Tinv;

// the m blocks mk(0) ... mk(m-1) on the same P channels, their outputs averaged
parallel(P, m, mk) = si.bus(P) <: par(k, m, mk(k)) :> par(h, P, /(m));

// a matrix from n inputs to m outputs: output o is the sum over i of c(i, o) times input i
matrix(n, m, c) = si.bus(n) <: par(o, m, par(i, n, *(c(i, o))) :> _);

// fx on P channels in a loop: its outputs come back to its inputs through
// the matrix c, then the gain g
feedbackNetwork(P, c, g, fx) = (ro.interleave(P, 2) : par(i, P, +) : fx)
                             ~ (matrix(P, P, c) : par(i, P, *(g)));
```

Each is one line, because its arguments already are what it needs:
circuits (`T`, `fx`), a function that makes circuits (`mk`, called with a
rank), a function that makes numbers (`c`, the coefficient of a matrix).
Line by line:

- **`each(B, mk)`** is the iteration `par` of chapter 11, with a body that
  depends on the rank. `b` and `B` are numbers when the compiler expands
  it, so `mk` can compute a frequency or a delay from them, choose one
  block among several, or ignore them. With blocks of one input and one
  output, the result has B inputs and B outputs.
- **`inDomain(T, fx, Tinv)`** is three blocks in sequence: `fx` must have
  as many inputs as `T` has outputs, and as many outputs as `Tinv` has
  inputs. The result has the inputs of `T` and the outputs of `Tinv`.
  Nothing in the definition says that `Tinv` undoes `T`: that is a law, to
  be checked like the others (see "Laws").
- **`parallel(P, m, mk)`** has P inputs and P outputs, like each of its m
  blocks. `si.bus(P)` is P wires, which give it its inputs. `<:` copies
  them to the m blocks, each one receiving the P channels in their order.
  `:>` adds the outputs that have the same rank in every block, and `/(m)`
  turns each sum into an average (exercise 2).
- **`matrix(n, m, c)`** has n inputs and m outputs. For one output `o`,
  the row `par(i, n, *(c(i, o))) :> _` multiplies input `i` by `c(i, o)`
  and adds the n products. `par(o, m, ...)` puts the m rows side by side,
  and `<:` gives the n inputs to each of them. `c` is called with numbers,
  n × m times, while the program is compiled.
- **`feedbackNetwork(P, c, g, fx)`** has P inputs and P outputs. In
  `A ~ B` the outputs of `A` go through `B` and come back to the first
  inputs of `A`, one sample later (chapter 4), and the other inputs of `A`
  remain those of the whole. `B` is the matrix followed by the gain. `A`
  receives the P signals that come back, then the P inputs of the network:
  `ro.interleave(P, 2)` puts them in pairs, the signal that comes back to
  line i next to input i, `par(i, P, +)` adds each pair, and `fx`
  processes the P sums.

One discipline turns them into an algebra: what a combinator returns has
the shape of what it replaces, a stereo block for a stereo block, a block
on P channels for a block on P channels. Its result can then be the
argument of the next one, and combinators nest without limit.

## Laws

A circuit has no other effect than its outputs. One can therefore say that
two circuits are **equal**, and such an equality is a licence to rewrite:
wherever one side appears, in any program, the other may replace it. This
is referential transparency in the strict sense, the substitution of equals
for equals, with circuits as the values. The laws of a combinator say what
it guarantees before any use is made of it, and `law` is the combinator
that checks one
([`law.dsp`](../examples/17/law.dsp)):

```faust
law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);
```

It feeds the same noises to `a` and to `b` and outputs their differences,
which faustprobe requires to stay under 1e-12 (`--fail-above`).

The smallest change of domain shows what to ask of the others. It has one
component, and its transform is a gain: the signal `g` times as loud, and
back.

```faust
atLevel(g, fx) = inDomain(*(g), fx, /(g));
```

With `lp = fi.lowpass(2, 1000)`:

| law | largest difference |
|---|---|
| `atLevel(4, _)` is `_`: there and back is the identity | 0 |
| `atLevel(4, lp)` is `lp`: a filter does the same at any level | 0 |

A check that cannot fail proves nothing, so each law comes with an equality
that does not hold, on which the same check must fail. Here it is a
saturation: `atLevel(4, ma.tanh)` is not `ma.tanh`
([`not_a_law.dsp`](../examples/17/not_a_law.dsp), difference 0.51). This
failure is the drive of a distortion: going to another level is worth it
because the process is not linear.

The same three questions are asked of every change of domain, and each of
the use cases that follow answers them with its own table:

- **Is there and back the identity**, when nothing is done in the other
  representation? It says that `Tinv` undoes `T`.
- **Is a linear process, the same on every component, that process**
  applied to the signals themselves? Then the detour buys nothing.
- **What is not a law?** It is what the detour is for: a process that is
  not linear, or one that differs from one component to the next.

In a language of steps a rewriting must also preserve how many times each
instance is stepped, and in which order: `f(x) + f(x)` and `2 * f(x)` are
not the same program when `f` moves.

## Three use cases

Two changes of domain and an assembly, each one with its laws and with what
is not one.

### Transform, process, transform back

`inDomain` is the commonest shape of an effect: go to a representation
where the process is simple, apply it, come back. With the mid/side
transform ([`in_domain.dsp`](../examples/17/in_domain.dsp)):

```faust
toMS = _, _ <: +, - : /(2), /(2);       // left, right -> mid, side
fromMS = _, _ <: +, -;                  // mid, side -> left, right
inMS(fx) = inDomain(toMS, fx, fromMS);

process = inMS((_, *(width)));
```

a gain on the side signal alone is a stereo width control. `inMS` is a
combinator made from another one, and `inMS(fx)` is a stereo block like any
other: it can be the `fx` of the next `inDomain`.

Its laws ([`ms_laws.dsp`](../examples/17/ms_laws.dsp)):

| law | largest difference |
|---|---|
| `inMS(si.bus(2))` is `si.bus(2)`: there and back is the identity | 0 |
| `inMS((lp, lp))` is `(lp, lp)`: the same filter on both signals | 2.2e-16 |

And what is not one: a filter on the mid signal alone is not a filter on
the left signal alone
([`not_ms_laws.dsp`](../examples/17/not_ms_laws.dsp), difference 1.16). A
process that differs from one component to the other is what mid/side is
for, and the width control is one: a gain on the side alone.

### Any effect, multiband

The bands of a signal are another representation of it, and the change of
domain that audio uses most: a compressor, a saturation or a delay applied
band by band is another effect than the same one applied to the whole
signal. The transform is a crossover, written by pattern matching on the
list of its frequencies (chapter 11)
([`multiband.dsp`](../examples/17/multiband.dsp)):

```faust
// several frequencies: lo is what is below the first one, and what is left,
// the input minus lo, is split at the others
split((f, fs)) = _ <: lo, (_ - lo) : _, split(fs) with { lo = fi.lowpass(1, f); };
// one frequency: what is below it, and what is left
split(f) = _ <: lo, (_ - lo) with { lo = fi.lowpass(1, f); };

// the way back: the bands added together
unsplit(freqs) = si.bus(ba.count(freqs) + 1) :> _;

// fx applied to the bands of a signal
multiband(freqs, fx) = inDomain(split(freqs), fx, unsplit(freqs));
```

Line by line:

- **`split`** has two rules (chapter 11). The first one takes a list of at
  least two frequencies, `f` the first and `fs` the others; the second one
  a single frequency. The compiler tries them in this order, and the order
  matters, since the second pattern would accept a list as well.
- **`_ <: lo, (_ - lo)`** makes two signals out of one. `lo` is the input
  through a low-pass filter, what is below `f`; `_ - lo` is the input
  minus that, what is left. Together they have three inputs, which `<:`
  feeds with the same signal. `lo` is written twice and filters the same
  signal both times, so it is one signal (see "One name, one signal"): the
  generated code holds one filter per frequency.
- **`: _, split(fs)`**, in the first rule, sends the low band to a wire,
  where it is finished, and what is left to `split(fs)`, which splits it
  at the other frequencies. `<:` is the weakest operator (chapter 2), so
  the rule reads `_ <: ((lo, (_ - lo)) : (_, split(fs)))`.
- **The filter is of order 1** because what such a filter leaves is the
  high-pass filter of the same order: `_ - fi.lowpass(1, f)` is
  `fi.highpass(1, f)`, to within 2.2e-16. At order 2 it is not, and the
  difference is as large as the signal.
- **`unsplit(freqs)`** adds the bands. A list of n frequencies makes n + 1
  bands, hence `ba.count(freqs) + 1`; `si.bus` is that many wires, and
  `:> _` merges them into one, which adds them.
- **`multiband(freqs, fx)`** is `inDomain` with `split` to go and `unsplit`
  to come back. It has one input and one output, and `fx` between them
  must have as many inputs and as many outputs as there are bands.

For the three frequencies of the example, the recursion unfolds into three
steps, each one giving a band and what is left:

| step | band | what is left |
|---|---|---|
| 250 Hz | band 0 is `lo` of the input | rest 1 is the input minus band 0 |
| 1000 Hz | band 1 is `lo` of rest 1 | rest 2 is rest 1 minus band 1 |
| 4000 Hz | band 2 is `lo` of rest 2 | band 3 is rest 2 minus band 2 |

At each step the band and what is left add back to what came in, so the
four bands add back to the input: this is why `unsplit` is the way back.
The bands come out from the lowest to the highest: a sine of 100 Hz is
mostly in band 0, a sine of 10 kHz in band 3.

`each` builds the block `fx` from a function of the rank:

```faust
freqs = (250, 1000, 4000);          // three frequencies, four bands

comp(ratio) = \(b, B).(co.compressor_mono(ratio, -20, 0.02 / (b + 1), 0.2 / (b + 1)));

process = multiband(freqs, each(4, comp(ratio)));
```

`comp(ratio)` is a function that returns a function (chapter 12): for a
ratio, the rule that makes the compressor of band b among B, whose attack
and release shorten as the band rises. `b` and `B` are known when the
program is compiled, so each band receives its own compressor, with its
own constants, and no table of parameters is read while the program runs.

What the bands are for can be measured
([`bass_and_treble.dsp`](../examples/17/bass_and_treble.dsp)). A bass at
−6 dB and a treble at −40 dB go through one compressor, then through a
compressor per band. One compressor turns everything down when the bass is
loud, and the treble comes out 9.6 dB lower. With a compressor per band the
bass is turned down in its own band, and the treble comes out 0.01 dB
lower. The single compressor of that program is written `comp(4)(0, 1)`,
band 0 among 1: the same rule, asked for another number of bands.

`multiband(freqs, fx)` is a mono block like any other, whatever `fx` does
to the bands. It can therefore take the place of the mid signal in the
block that `inMS` takes
([`mid_bands.dsp`](../examples/17/mid_bands.dsp)):

```faust
process = inMS((multiband(freqs, each(4, comp(ratio))), _));
```

In mid/side, compress the bands of the mid and leave the side alone: three
combinators are nested, and the text reads like the sentence that describes
it. The diagram that the compiler draws follows the same tree: `toMS`,
`multiband(...)` and `fromMS` at the top, and inside the second box the
three filters of the crossover followed by one box, `each(4)(...)`. A
source in the centre stays in the centre, and the difference between the
two outputs is the difference between the two inputs, whatever the
compressors do.

The laws of the bands, with the four bands of `freqs`
([`band_laws.dsp`](../examples/17/band_laws.dsp)):

| law | largest difference |
|---|---|
| `multiband(freqs, si.bus(4))` is `_`: there and back is the identity | 0 |
| `multiband(freqs, par(b, 4, lp))` is `lp`: one filter in every band | 2.2e-16 |
| `multiband(freqs, each(4, comp(1)))` is `_`: a ratio of 1 does nothing | 1.1e-16 |
| `inMS((multiband(freqs, si.bus(4)), _))` is `si.bus(2)`: two domains nested | 0 |

And three equalities that do not hold
([`not_band_laws.dsp`](../examples/17/not_band_laws.dsp)):

| not a law | difference |
|---|---|
| a compressor per band is one compressor | 0.58 |
| a gain per band is a wire | 3.79 |
| the bands of `fi.filterbank(3, freqs)` add back to the input | 2.19 |

The first two failures are the two reasons to go to the bands: a process
that is not linear, like a compressor, and one that differs from one band
to the next, like the gains of an equalizer. The third one is a condition
on the transform. The bands of the library's filter bank add back to an
all-pass filter: the level of every frequency is kept (0 dB to within
2e-13 at seven frequencies from 60 Hz to 12 kHz), its phase is not, and
with such bands a ratio of 1 would no longer be a neutral setting.

### A matrix given by a function

`matrix(n, m, c)` does not take a table of coefficients but the rule that
gives them: output o is the sum over i of `c(i, o)` times input i
([`matrix.dsp`](../examples/17/matrix.dsp)):

```faust
hadamard(P) = \(i, o).((1 - 2 * (bits(i & o) % 2)) / sqrt(P))
with {
    bits(x) = sum(b, 16, (x >> b) & 1);
};

rotation(P) = \(i, o).(o == (i + 1) % P);
```

`hadamard(8)` is a function of two integers, returned by a function
(chapter 12). Its coefficient is +1 or −1 by the parity of the bits that i
and o share, which gives the matrix that `ro.hadamard` builds by divide and
conquer (chapter 11). With it, the feedback delay network of chapter 16 is
one call ([`fdn.dsp`](../examples/17/fdn.dsp)):

```faust
process = _ <: si.bus(N) : feedbackNetwork(N, hadamard(N), 1, par(i, N, line(i))) :> _, _;
```

faustprobe finds its samples equal to those of chapter 16 to within 3e-17:
the additions are not made in the same order. Replacing `hadamard(N)` by
`rotation(N)` gives another network, where each line feeds the next one and
an echo travels around the outputs instead of spreading over them
(exercise 3). The structure of the network has become an argument.

The laws of these matrices are checked in `matrix.dsp`:

| law | largest difference |
|---|---|
| `matrix(8, 8, hadamard(8))` is `ro.hadamard(8)` divided by √8 | 0 |
| `matrix(8, 8, hadamard(8))` twice is `si.bus(8)`: it is its own inverse | 2.2e-16 |
| `matrix(4, 4, rotation(4))` four times is `si.bus(4)` | 0 |

A rotation is not its own inverse: two quarter turns are not the identity,
and the same check fails on them (difference 1.99).

## How new is this?

In programming, it is not. John Backus proposed in his Turing lecture of
1977 (*Can Programming Be Liberated from the von Neumann Style? A
Functional Style and Its Algebra of Programs*, 1978) to build programs with
*combining forms*, and to reason on them with an algebra in which programs
are the variables and combining forms the operations, its laws serving to
transform one program into another. Libraries of combinators have been a
habit of functional programmers ever since, and the arrows of "The
vocabulary of functional languages" (Hughes, 2000) come with their laws.
Checking a law on random inputs is QuickCheck (Claessen and Hughes, 2000):
`law` does it with noise.

Among audio languages it is rare. Most of them are languages of steps, as
Csound, ChucK, Cmajor and Onda are; others connect boxes, as Max and Pure
Data do, or build a graph of unit generators from a general-purpose
language, as SuperCollider does. Faust took the other way in 2002
(Orlarey, Fober and Letz, *An Algebra for Block Diagram Languages*), with
an algebra of block diagrams proposed as an alternative to the graph: the
five compositions are the language itself, with a semantics in which two
circuits can be said to be equal, and a compiler that relies on it. Few
audio languages have followed. Kronos is one, whose author credits Faust
with pioneering the functional audio language; libraries embedded in
Haskell are another case, such as Euterpea, where signal functions are
arrows. What this chapter adds is a practice, not a feature of the
language: writing the combinators of one's own domain, and stating their
laws with checks that can fail.

## What the compiler does with it

Combinators, lambdas and coefficient functions are all evaluated by the
compiler (chapter 9): what reaches the generated code is the circuit they
describe, and nothing of them. The matrix of a rotation is sixteen products
by 0 or 1 and four sums on paper; compiled, it is four wires
([`rotation_wiring.dsp`](../examples/17/rotation_wiring.dsp)):

```cpp
output0[i0] = static_cast<FAUSTFLOAT>(static_cast<float>(input3[i0]));
output1[i0] = static_cast<FAUSTFLOAT>(static_cast<float>(input0[i0]));
```

The compiler also finds the first law of the bands by itself. Splitting a
signal into four bands and adding them back is three filters, three
subtractions and three sums on paper; compiled, it is one wire
([`there_and_back.dsp`](../examples/17/there_and_back.dsp)). It does not
know the second one: with the same filter in every band, the three filters
of the crossover and the four copies of the filter all remain, eleven
recursions where the filter alone takes two
([`law_unknown.dsp`](../examples/17/law_unknown.dsp)). Writing the filter
once is then left to the programmer, and the law is what allows it.

Referential transparency serves the compiler as much as the programmer.
The order of evaluation is no part of the value of an expression, so a
program without steps states no order, and every optimisation of chapter 9
is a substitution of equals for equals: computing once what is written
several times (the three outputs of `twice.dsp` cost four memories, not
twelve), folding a constant, moving a computation out of the sample loop,
splitting the loop for vectorisation and threads. Cmajor and Onda also
specialise their generic processors when they compile; this chapter
compares what a programmer can write and rely on, and measures no speed.

## Where steps are the better tool

- **Algorithms that are sequences of decisions**: a search in a table, an
  iteration that stops when it has converged, a state machine with many
  cases, the handling of events as they arrive. Faust has no loop at run
  time (chapter 11), and `select2` computes both its branches (chapter 9).
- **Events, voices, objects that come and go.** Cmajor has event endpoints
  and handlers; Onda has events, tasks, and arrays of processors among
  which a run-time index chooses the one to step. In Faust an event is a
  signal (chapter 6), and the structure of a program is fixed when it is
  compiled.
- **Rates.** Running one node at four times the sampling rate is a
  declaration in Cmajor (`node n = P * 4;`), and Onda has an oversampled
  form of its `sample` section.
- **Habit.** A loop that updates variables is how most programmers think of
  a computation, and how most textbooks print an algorithm.

## The idiom in the libraries

**A composition of one's own.** `pm.chain` in physmodels.lib assembles the
bidirectional blocks of a waveguide model. It is defined by pattern
matching on the composition itself:

```faust
chain(A:As) = ((ro.crossnn(1),_',_ : _,A : ro.crossnn(1),_,_ : _,chain(As) : ro.crossnn(1),_,_)) ~ _ : !,_,_,_;
chain(A) = A;
```

`pm.chain(A : B : C)` takes the term `A : B : C` apart and connects each
block to its two neighbours, in both directions.

**A circuit from a tree.** `wd.buildtree` in wdmodels.lib builds a wave
digital filter from the tree of its adaptors, written as an expression such
as `vsrc : (branch : (res_leaf, probe))`.

**A function and its antiderivative.** `aa.ADAA1(EPS, f, F1, x)` in
aanl.lib reduces the aliasing of any nonlinearity `f`, given as a function
together with its antiderivative `F1`.

**Bands.** `fi.filterbank(O, freqs)` in filters.lib splits a signal at the
frequencies of a list, with Butterworth filters of order `O`. At order 3
its bands are steeper than those of the first-order crossover of this
chapter, and they add back to an all-pass filter instead of the input (see
"Any effect, multiband").

## Pitfalls

- **One expression, one signal.** `no.noise, no.noise` is the same noise
  twice. Two voices that must differ have to differ in their text: another
  seed, another parameter, `no.multinoise`.
- **A name stands for a block, and a block is not always a signal.** With
  `d(x) = x - x`, the block `d` is zero, but `d(_)` is `_ - _`, the
  difference of two inputs: each occurrence of a block takes its own inputs
  ([`block_or_signal.dsp`](../examples/17/block_or_signal.dsp)). In the
  same way `lo, (_ - lo)` in `split` has three inputs, and it is the `<:`
  in front of it that gives the same signal to the three.
- **What reaches no output does not exist.** A circuit has no effect other
  than its outputs, so the compiler removes whatever none of them uses
  (chapter 9), a bargraph included: `attach` is there to keep one alive
  (chapter 8).
- **Arity is the only type.** Nothing says that the `fx` of
  `feedbackNetwork` must have P inputs and P outputs: a wrong block is
  refused where it is composed, sometimes far from the mistake. `inputs`
  and `outputs` (chapter 3) help.
- **Equal on paper, equal to within rounding.** Two writings of one law may
  add in another order. Compare with a tolerance, and make every comparison
  fail once.
- **A law of filters is not a law of every circuit.**
  `multiband(freqs, par(b, 4, fx))` is `fx` when `fx` is linear and does
  not change with time; a compressor is neither. Check a law with the
  circuits it will be used with.
- **All of it happens in the compiler.** A structure cannot change while
  the program runs (chapter 9).

## Exercises

1. `_ <: (lp : lp), lp` uses `lp` three times. How many memories does the
   generated code hold, and what does the second output read? Solution:
   [`ex1_how_many.dsp`](../examples/17/solutions/ex1_how_many.dsp).
2. Use `parallel(P, m, mk)` and `law` to check that four copies of one
   stereo process, averaged, are that process, and that four different
   processes are not. Solution:
   [`ex2_parallel.dsp`](../examples/17/solutions/ex2_parallel.dsp).
3. A feedback network of four lines of 100 samples whose matrix is
   `rotation(4)`. Check that an impulse on the first input comes out on
   each output in turn. Solution:
   [`ex3_rotation.dsp`](../examples/17/solutions/ex3_rotation.dsp).
4. An equalizer is `multiband` with a gain per band. Write `eq(gains)`,
   the gains in decibels in a list read with `ba.take`. Check that four
   equal gains are that gain, and that a constant input, which only the
   lowest band lets through, comes out with the first gain. Solution:
   [`ex4_equalizer.dsp`](../examples/17/solutions/ex4_equalizer.dsp).
