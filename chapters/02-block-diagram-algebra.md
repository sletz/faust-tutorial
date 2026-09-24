# 2. Block-diagram algebra

## The idea

Every Faust program is an assembly of blocks. A block has a fixed number of
inputs and outputs, its **arity**. Five operators assemble two blocks into a
bigger one, and they are the only ones: there are no variables to assign,
no loops, no wires drawn by hand. The compiler checks that the arities
match, and that is where most beginner errors come from.

Two elementary blocks serve as cables:

- `_` is a **wire**: one input, one output, the signal goes through;
- `!` is a **cut**: one input, no output, the signal disappears.

## The five compositions

| written | name | what it does | arity condition |
|---|---|---|---|
| `A : B` | sequential | the outputs of A feed the inputs of B | outputs(A) = inputs(B) |
| `A , B` | parallel | A and B side by side | none |
| `A <: B` | split | the outputs of A are copied to the inputs of B | inputs(B) is a multiple of outputs(A) |
| `A :> B` | merge | the outputs of A are summed into the inputs of B | outputs(A) is a multiple of inputs(B) |
| `A ~ B` | recursive | the outputs of A come back, through B, to the inputs of A | inputs(B) ≤ outputs(A), outputs(B) ≤ inputs(A) |

Recursion is the subject of chapter 4; this chapter presents the other four.

### Sequence

([`sequence.dsp`](../examples/02/sequence.dsp))

```faust
process = *(2) : +(1);
```

Each input sample is doubled, then increased by 1. With the impulse
1, 0, 0... as input, the output is 3, 1, 1...

### Parallel

([`parallel.dsp`](../examples/02/parallel.dsp))

```faust
process = *(2), *(3);
```

Two inputs, two outputs: the first input is doubled, the second tripled.
The two blocks ignore each other.

### Split

([`split.dsp`](../examples/02/split.dsp))

```faust
process = _ <: _, _;
```

One input, two identical outputs: mono to stereo. When A has several
outputs, they are distributed **cyclically** over the inputs of B
([`split_cyclic.dsp`](../examples/02/split_cyclic.dsp)):

```faust
process = _, _ <: *(1), *(1), *(10), *(10);
```

The four inputs on the right receive a, b, a, b. An impulse on the first
input therefore comes out on outputs 0 and 2.

### Merge

([`merge.dsp`](../examples/02/merge.dsp))

```faust
process = _, _, _, _ :> _, _;
```

Merge is the mirror of split: output i of A is added to input (i modulo the
number of inputs) of B. Here inputs 0 and 2 are summed on the left output,
1 and 3 on the right: two stereo pairs mixed into one. `_, _ :> _` is simply
a sum.

### Cutting and keeping

([`cut.dsp`](../examples/02/cut.dsp))

```faust
process = _, _ : !, _;
```

Two inputs, one output: the second one. The cut is used wherever a block
produces more outputs than wanted; chapter 5 uses it systematically.

## Priorities

The operators do not have the same priority. From strongest to weakest:
`~`, then `,`, then `:`, then `<:` and `:>`. So
([`priorities.dsp`](../examples/02/priorities.dsp)):

```faust
process = *(2), *(3) : +;
```

reads `(*(2), *(3)) : +`: two inputs, one output equal to 2 × in0 + 3 × in1.
When in doubt, add parentheses: they cost nothing.

## Arity errors

When the arities do not match, the compiler rejects the program and says why
([`arity_error.dsp`](../examples/02/arity_error.dsp)):

```faust
process = _, _ : _;
```

The C++ compiler answers:

```text
ERROR : sequential composition A:B
The number of outputs [2] of A must be equal to the number of inputs [1] of B
```

and faust-rs adds the location, the rule and a hint:

```text
arity_error.dsp:4:16: error [FRS-PROP-0002] sequential composition mismatch at node 5: left outputs (2) != right inputs (1)
  4 | process = _, _ : _;
    |                ^ failing composition
  = note: rule: seq(A, B) requires outputs(A) == inputs(B)
  = help: for `A : B`, enforce outputs(A) == inputs(B)
```

To fix it, count: two outputs on the left need two inputs on the right
(`_, _ : +`), or a merge (`_, _ :> _`).

## Reading the diagram

`faust -svg program.dsp` writes the block diagram of the program into a
`program-svg/` folder; the online IDE shows it in a tab. Each block is a
box, each signal a wire, and the compositions appear as they are written.
Reading the diagram is often the fastest way to understand wiring that does
not do what you think.

## Example: a mixer

([`mixer.dsp`](../examples/02/mixer.dsp))

```faust
gainA = hslider("gain A", 0.5, 0, 1, 0.01);
gainB = hslider("gain B", 0.5, 0, 1, 0.01);

process = *(gainA), *(gainA), *(gainB), *(gainB) :> _, _;
```

Four inputs (two stereo pairs), one gain per pair, and a merge into two
outputs. The check sets the gains to 0.25 and 0.5 and sends 1 on every
input: each output must be 0.75.

## The idiom in the libraries

The libraries give names to common wirings. In `signals.lib`:

```faust
bus(N) = par(i, N, _);     // N wires side by side
block(N) = par(i, N, !);   // N cuts
```

and in `routes.lib`, `ro.cross(N)` reverses the order of N signals and
`ro.interleave(R, C)` interleaves groups of signals. They rely on `par`,
the repeated parallel composition (chapter 11), and on the `route`
primitive, which describes any wiring as a list of (input, output) pairs:

```faust
cross(N) = route(N, N, par(i, N, (i+1, N-i)));
```

`si.bus(2)` is a name for `_, _`. It is written when the number of wires is
a parameter.

## Pitfalls

- **Count the wires** before composing. `faust -svg` or the IDE show the
  arities.
- **Merge adds**: `:>` is not a selector. Choosing one signal out of two
  needs `select2` (chapter 6).
- **Split copies cyclically**: `_, _ <: _, _, _` is an error (3 is not a
  multiple of 2), not a partial copy.

## Exercises

1. Swap the two channels of a stereo signal, using only `_`, `!`, `,` and
   `<:`. Solution: [`ex1_swap.dsp`](../examples/02/solutions/ex1_swap.dsp).
2. One input to four outputs, each half the previous one. Solution:
   [`ex2_fan.dsp`](../examples/02/solutions/ex2_fan.dsp).
3. The average of three inputs. Solution:
   [`ex3_average3.dsp`](../examples/02/solutions/ex3_average3.dsp).
