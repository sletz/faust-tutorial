# 3. Naming inputs

## The idea

In chapter 2, signals had no name: they were designated by their position on
a bus of wires. That is concise for two or three wires and unreadable
beyond. So Faust also lets you write a block as a **function** whose
arguments name its inputs:

```faust
foo(a, b, c) = (a + b) * c;
process = foo;
```

`process = foo` is a block with three inputs: the three arguments. This is
not another kind of program, it is another way to write the same block. The
compiler turns the arguments into wires, and the result is, sample for
sample, that of the wired version.

## Arguments and wires

The idioms document gives three functions of the same shape
([`arguments.dsp`](../examples/03/arguments.dsp)):

```faust
foo1(in_a, in_b, in_c) = (in_a, in_b : +), in_c : *;   // (a + b) * c
foo2(in_a, in_b, in_c) = (in_c, in_b : +), in_a : *;   // (c + b) * a
foo3(in_a, in_b, in_c) = (in_c, in_c : +), in_c : *;   // (c + c) * c
```

The bodies are written with the block algebra, but the signals in them are
designated by name: `in_a, in_b : +` is the sum of the first two inputs.
Changing the order or repeating a name needs no wiring: `foo3` only uses
`in_c`, three times, and still has three inputs, because its arguments
define them. The other two are simply ignored.

The following three writings describe the same block
([`infix.dsp`](../examples/03/infix.dsp), [`wires.dsp`](../examples/03/wires.dsp)):

```faust
foo1(a, b, c) = (a + b) * c;           // usual notation
foo1(a, b, c) = (a, b : +), c : *;     // blocks, named inputs
foo1 = +, _ : *;                       // blocks, no name at all
```

The check of `infix.dsp` proves it: faustprobe sends the same noise to both
programs and compares their outputs.

```bash
faustprobe --double -n 256 --in white:1 --quiet --compare wires.dsp infix.dsp
```

```text
# compare out0: identical
```

The nameless version is the shortest here; it quickly becomes unreadable
when a signal is used twice or out of order, as in `foo2` (exercise 2). The
rule of thumb: write as wires what is obvious wiring, name as soon as you
have to think to count.

## Applying a function

Calling a function on signals is sending them to it in sequence. `f(x, y)`
is the same block as `x, y : f`
([`application.dsp`](../examples/03/application.dsp)):

```faust
f(a, b) = a - b;

process = f(os.osc(440), os.osc(440)), (os.osc(440), os.osc(440) : f);
```

Both outputs are zero. This equivalence is what lets you move from one
writing to the other without changing the program. Applying a function to
*fewer* arguments than it expects is allowed too: the result is a block that
takes the remaining arguments on its inputs. This is partial application,
the subject of chapter 12.

## Local definitions

`with` attaches definitions to an expression
([`with.dsp`](../examples/03/with.dsp)):

```faust
mix(a, b, c) = total * c
with {
    total = a + b;
};
```

`total` is only visible inside `mix`, and may use its arguments. The
libraries use `with` everywhere to name the steps of a computation; chapter
1 showed one in the definition of `os.oscsin`.

## Measuring arity: `inputs` and `outputs`

`inputs(x)` and `outputs(x)` are constants computed by the compiler
([`arity.dsp`](../examples/03/arity.dsp)):

```faust
foo1(a, b, c) = (a + b) * c;

// The mean of all the outputs of a block, whatever their number.
mean(x) = x :> /(outputs(x));

process = inputs(foo1), outputs(foo1), mean((1, 2, 3)), mean((1, 2, 3, 4, 5));
```

The outputs are 3, 1, 2 and 3. `mean` adapts to the block it is given: it
is the first function of this tutorial that takes a *block* as argument
rather than a signal. Chapter 12 generalises the idea.

## The idiom in the libraries

`si.interpolate` in `signals.lib` combines both uses:

```faust
interpolate(i,x,y) = x + i*(y-x);
```

Its three arguments are named, but it is most often used with the
coefficient `i` alone: `si.interpolate(0.3)` is a block with two inputs that
mixes its two signals. Fixed parameters come first, the signals to process
last; this is the convention of all the libraries, and chapter 12 explains
why.

`ma.sub` in `maths.lib` shows what naming buys: the order of the operands
can change without any wiring.

```faust
sub(x,y) = y-x;
```

`fi.tf1` in `filters.lib`, by contrast, names its coefficients but wires its
signal:

```faust
tf1(b0,b1,a1) = _ <: *(b0), (mem : *(b1)) :> + ~ *(0-a1);
```

`mem` and `~` are the subject of the next chapter.

## Pitfalls

- **An unused argument is still an input.** `foo3` has three inputs;
  whoever uses it must provide three signals.
- **Argument names shadow global definitions** of the same name inside the
  body of the function.
- **`outputs(x)` expects a block**, not a number: `outputs(3)` is 1, because
  the constant 3 is a block with one output.

## Exercises

1. A crossfade between two inputs `x` and `y`, set by a slider `amount`,
   written with named arguments. Solution:
   [`ex1_crossfade.dsp`](../examples/03/solutions/ex1_crossfade.dsp).
2. Write `foo2` without any name, using only `_`, `!`, `<:`, `:` and the
   operators, and check with `--compare` that it is identical to the named
   version. Solution: [`ex2_wires.dsp`](../examples/03/solutions/ex2_wires.dsp),
   reference: [`reference_foo2.dsp`](../examples/03/reference_foo2.dsp).
