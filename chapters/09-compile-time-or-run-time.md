# 9. Compile time or run time

## The idea

The Faust compiler does not translate the text of a program line by line.
It works out **what the program computes**, and generates code for that.
Orlarey, Fober and Letz put it in one sentence (SMC 2009): the idea is "not
to compile the block diagram itself, but what it computes".

This has two consequences that every Faust programmer uses, knowingly or
not:

1. anything that can be computed before the program runs is computed by
   the compiler, and costs nothing at run time;
2. some things **must** be known before the program runs, and the compiler
   refuses a program where they are not.

This chapter shows both, with the generated C++ as evidence. To see it
yourself, run `faust program.dsp` and read the `compute` method at the end.

## How the compiler works

In broad strokes (SMC 2009; Soft Computing, 2004):

1. **Evaluation.** The program is evaluated like a functional program:
   definitions are expanded, functions applied, pattern matching resolved
   (chapter 11), until only primitive blocks and the five compositions
   remain. This happens entirely at compile time.
2. **Symbolic propagation.** Symbolic signals are sent through the
   resulting diagram, which gives one equation per output, in terms of the
   inputs, the widgets and time.
3. **Typing.** Every signal gets a type: its nature (integer or float), its
   interval of values, **when** it is known (compile time, initialisation,
   run time), and **how often** it changes (never, once per block for
   widgets, every sample).
4. **Normalisation.** The equations are simplified and put in a normal
   form, so that different writings of the same computation become
   identical and are computed once.
5. **Code generation**, which places each computation according to its
   type: constants in the code, initialisation constants in
   `instanceConstants`, widget expressions before the sample loop, the rest
   inside it.

## Constants cost nothing

([`constant_folding.dsp`](../examples/09/constant_folding.dsp))

```faust
process = (1 + 2) * 3, sin(0.5), 1/3 + 1/3;
```

```cpp
output0[i0] = static_cast<FAUSTFLOAT>(9);
output1[i0] = static_cast<FAUSTFLOAT>(0.47942555f);
output2[i0] = static_cast<FAUSTFLOAT>(0.6666667f);
```

No `sin` is called at run time. The same happens to a factorial computed by
pattern matching (chapter 11), or to the coefficients of a filter whose
frequency is a constant.

## Different diagrams, one computation

([`normal_form.dsp`](../examples/09/normal_form.dsp))

```faust
process = _ <: (/(2) : @(10)), (*(2) : @(7) : /(4) : @(3));
```

Both outputs are x(t − 10)/2. The compiler finds it: it generates one delay
line of 11 samples and one multiplication, shared by the two outputs.

```cpp
float fTemp0 = 0.5f * fVec0[10];
```

Write what is clearest; the normal form takes care of the arithmetic.

## Three rates

Signals change at three rates, and the compiler puts each computation where
it belongs.

**Constant**: computed by the compiler.

**Initialisation**: the sampling rate is known when the program starts, not
when it is compiled. Expressions of `ma.SR` are computed once, in
`instanceConstants` ([`sample_rate.dsp`](../examples/09/sample_rate.dsp)):

```cpp
fConst0 = 1e+03f / std::min<float>(1.92e+05f, std::max<float>(1.0f, static_cast<float>(fSampleRate)));
```

**Control rate**: a widget changes at most once per block of samples, so an
expression of widgets alone is computed once per block, before the sample
loop ([`control_rate.dsp`](../examples/09/control_rate.dsp)):

```faust
process = *(hslider("gain", 0, -60, 0, 0.1) : ba.db2linear);
```

```cpp
float fSlow0 = std::pow(1e+01f, 0.05f * static_cast<float>(fHslider0));
for (int i0 = 0; i0 < count; i0 = faust_wrap_add(i0, 1)) {
    output0[i0] = static_cast<FAUSTFLOAT>(fSlow0 * static_cast<float>(input0[i0]));
}
```

The costly `pow` runs once per block; the loop only multiplies. This is why
chapter 8 advised smoothing *after* the control-rate arithmetic: `si.smoo`
is a recursion, hence a per-sample signal, and everything after it is
computed at every sample (exercise 1).

**Sample rate**: everything that depends on an input, a recursion or time.

## Only what is used is computed

([`dead_code.dsp`](../examples/09/dead_code.dsp))

```faust
a = os.osc(hslider("a", 440, 20, 2000, 1));
b = os.sawtooth(hslider("b", 220, 20, 2000, 1));
process = a, b : !, _;
```

The first oscillator reaches no output: it is not compiled, and its slider
does not exist. Chapter 14 builds on this: a generic function with many
outputs can be specialised by cutting the ones you do not need, at no cost.

## Choosing at compile time

A choice whose condition is a constant is made by the compiler
([`compile_time_choice.dsp`](../examples/09/compile_time_choice.dsp)):

```faust
mode = 1;
process = ba.if(mode == 0, os.osc(440), os.sawtooth(440));
```

Only the sawtooth is compiled; the sine table of `os.osc` is absent from the
generated code. With `mode` on a slider
([`run_time_choice.dsp`](../examples/09/run_time_choice.dsp)), both
oscillators run at every sample and `select2` picks one: the table is back.
When a choice does not need to change while the program runs, make it a
constant. Chapters 11 and 13 show cleaner ways to do so: pattern matching
and environments.

## What must be known at compile time

Some quantities shape the program itself, and must be constants:

| quantity | why | example |
|---|---|---|
| the number of inputs and outputs of every block | the diagram is fixed | `par(i, N, ...)`, `si.bus(N)` |
| the arguments of pattern matching | the rules are applied by the compiler | `fi.lowpass(N, fc)`: `N` |
| the size of a table | memory is allocated once | `rdtable(N, ...)`, `rwtable(N, ...)` |
| the maximum of a delay | the buffer is allocated once | `@(d)`, `de.delay(N, d)` |

**Delays** need a *bound*, not a constant. The compiler takes it from the
interval of the delay signal, so a slider's range is enough
([`bounded_delay.dsp`](../examples/09/bounded_delay.dsp)):

```faust
d = hslider("delay", 10, 0, 100, 1);
process = _ <: @(d), de.delay(100, d);
```

The buffer gets 128 samples: the maximum 100, plus the current sample,
rounded up to a power of two. `de.delay(n, d)` clamps `d` to [0, n], which
gives a bound to any delay signal. Without a bound, the program is refused
([`unbounded_delay.dsp`](../examples/09/unbounded_delay.dsp)):

```faust
process = _ <: @(ba.time);
```

```text
ERROR : possible negative values of : ...
        used in delay expression : IN[0]
        interval(-2.14748e+09,2.14748e+09,0)
```

**Tables** need a true constant. The sampling rate is only known at
initialisation, so it cannot size a table
([`table_size.dsp`](../examples/09/table_size.dsp)):

```text
ERROR : the parameter must be an integer constant numerical expression : ...
```

The libraries clamp `ma.SR` to [1, 192000], which gives it an interval:
that is why a delay of at most one second, `de.delay(ba.sec2samp(1), d)`,
compiles (exercise 2), while a table of `ma.SR` entries does not.

**Pattern matching** on a value that is not a constant is the worst case:
the compiler does not refuse it, it **never stops**. `fi.lowpass(N, fc)`
builds its filter by a recursion on N (`N` is written in capitals in the
libraries, the convention for compile-time parameters). With
`N = int(hslider("order", 2, 1, 8, 1))`, the recursion never reaches its
base case: both compilers were still running when stopped after 20
seconds. If a compilation seems to hang, look for a widget in a parameter
written in capitals.

## Integers and floats

([`int_float.dsp`](../examples/09/int_float.dsp))

```faust
process = int(2.7), int(-2.7), 7 % 2, 7.5 % 2, 2147483647 + 1;
```

gives 2, −2, 1, 1.5 and −2147483648. `int` truncates towards zero; `%`
is the integer remainder on integers and the floating remainder on floats;
integer arithmetic wraps around on 32 bits. That wrap-around is not a bug
to avoid: the noise generator of noises.lib relies on it (exercise 3).
Division always gives a float (chapter 1). Widgets and `ma.SR` are floats.

## The idiom in the libraries

- **Capitals for compile-time parameters.** The contribution guide of
  faustlibraries asks that parameters which must be known at compile time
  be written in capitals: `fi.lowpass(N, fc)`, `de.delay(N, d)`,
  `si.bus(N)`.
- **Two selectors.** `ba.selector(i, n)` chooses one of n signals with an
  index known at compile time, and compiles only that one;
  `ba.selectn(N, i)` chooses with a run-time index, and computes all N.
  Note the opposite order of their arguments.
- **`de.delay`** is `delay(n,d,x) = x @ min(n, max(0,d));`: the clamp is the
  bound.
- **A compile-time switch.** `os.SAFE` in oscillators.lib and `DEBUG` in
  debug.lib are constants that select an implementation; chapter 13 shows
  how a user changes them.

## Other compilation options

The same analysis lets the compiler reorganise the code. `-vec` splits the
sample loop into simpler loops over vectors, which the C++ compiler can
vectorise; `-omp` and `-sch` run independent parts in parallel threads.
Whether they pay depends on the program: SMC 2009 measured large gains on
programs with independent parts, and none on a purely sequential one.
Measure before choosing.

## Pitfalls

- **A widget in a capital parameter** makes the compiler loop forever.
- **A table sized by `ma.SR`** is refused; size it for the largest rate.
- **`ba.if` on a widget computes both branches.** Use a constant, pattern
  matching or an environment when the choice is fixed.
- **Smoothing too early** moves control-rate arithmetic into the sample
  loop.

## Exercises

1. The constant-intensity panner of chapter 8, with both square roots
   computed once per block. Check in the generated C++ that no `sqrt`
   remains in the sample loop. Solution:
   [`ex1_smooth_late.dsp`](../examples/09/solutions/ex1_smooth_late.dsp).
2. A feedback echo with a time slider up to one second. Check the size of
   its buffer. Solution:
   [`ex2_echo_one_second.dsp`](../examples/09/solutions/ex2_echo_one_second.dsp).
3. Write the linear congruential generator of `no.noise` with integers, and
   check that it gives the library's sequence exactly. Solution:
   [`ex3_integer_noise.dsp`](../examples/09/solutions/ex3_integer_noise.dsp).
