# 10. Choosing among values

## The idea

Many programs need to map a number to another: a step of a sequencer to a
note, a menu entry to a filter type, a phase to a sample of a waveform, an
input level to a curve. Faust offers two tools for it, and the idioms
document asks which to use:

- a **table**: a list of values stored once, read by index with
  `rdtable`, or written and read with `rwtable`;
- a **selector**: `ba.selectn(N, i)`, which picks one of N signals.

They look interchangeable for a list of constants. They are not the same
thing, and the generated code shows the difference.

## Tables of constants

`waveform{...}` is a list of constants, and `rdtable` reads it at an index
([`major_scale.dsp`](../examples/10/major_scale.dsp)):

```faust
major_scale = waveform{-1, 0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17};
scale_table(i)  = major_scale, i : rdtable;
scale_select(i) = -1, 0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17 : ba.selectn(12, i);
```

Both give the same values. The generated code does not look the same when
the index changes at every sample:

```cpp
const static int imydspSIG0Wave0[12] = {-1,0,2,4,5,7,9,11,12,14,16,17};
...
output0[i0] = itbl0mydspSIG0[std::max<int>(0, std::min<int>(iTemp1, 11))];
output1[i0] = ((iTemp1 >= 6) ? ((iTemp1 >= 9) ? ((iTemp1 >= 11) ? 17 : ...
```

The table is stored once and read with one memory access, the index being
clamped to the table's range. The selector becomes a tree of comparisons,
four deep for twelve values, evaluated at every sample. For a dozen values
both are cheap; for hundreds, the table wins. The idioms document states
it: a table built with `waveform` "is more efficient".

## When the index is a widget

The idioms document also gives a "choice mapper" in both forms, with the
remark that the table mapping is made at compile time while the selector
mapping is made "once per cycle"
([`choice_mapper.dsp`](../examples/10/choice_mapper.dsp)):

```faust
choice_table(choice, wf) = wf, (choice : int) : rdtable;
choice_select(choice, values) = values : ba.selectn(outputs(values), choice);

algo = nentry("algo", 4, 0, 4, 1);
process = choice_table(algo, waveform{4, 3, 2, 1, 0}),
          choice_select(algo, (4, 3, 2, 1, 0));
```

With a widget as index, chapter 9 applies: an expression of widgets and
constants is computed once per block, before the sample loop. Both forms
become a single block-rate value (`iSlow`), and their cost is the same. The
difference matters only when the index is itself a sample-rate signal.

## Tables of signals, selectors of signals

The real difference is elsewhere:

- a table holds **values**, computed before the program runs: constants,
  or the first samples of a generator (next section). It cannot hold the
  output of an oscillator that runs alongside;
- a selector chooses among **signals**, which may be anything: four
  oscillators, three filters, two effects. All of them run at every sample
  (chapter 9), and the selector passes one.

To choose a *constant*, use a table. To choose a *process*, use a selector
at run time, or pattern matching and environments at compile time
(chapters 11 and 13).

## Tables filled by a generator

`rdtable(N, gen, i)` fills its N cells with the first N samples of the
signal `gen`, once, when the program is initialised
([`generated_table.dsp`](../examples/10/generated_table.dsp)):

```faust
N = 64;
sinwaveform(n) = sin(2 * ma.PI * float(ba.time) / n);
osc_table(f) = rdtable(N, sinwaveform(N), int(os.lf_sawpos(f) * N));
```

`ba.time` counts 0, 1, 2..., so the generator produces one period of a sine
over N samples. The C++ shows a separate class `mydspSIG0` whose `fill`
method runs at initialisation. The 2003 tutorial draws the same picture:
the table is computed at init time, the sample loop only reads it. This is
exactly how `os.osc` works, with a table of 65536 values:

```faust
sinwaveform(tablesize) =
    sin(float(ba.period(tablesize)) * (2.0 * ma.PI) / float(tablesize));
```

## Interpolation

A table read at the nearest cell is only as fine as its size. Reading two
neighbours and interpolating between them is much finer
([`interpolation.dsp`](../examples/10/interpolation.dsp)):

```faust
table(k) = rdtable(N + 1, sinwaveform(N), k);     // one extra cell for k + 1
pos = phase * N;
k = int(pos);
d = pos - k;

nearest = table(k);
linear  = table(k) + d * (table(k + 1) - table(k));
```

With 64 cells, the error against `sin` is:

| reading | peak error |
|---|---|
| nearest cell | 0.098 |
| linear interpolation | 0.0012 |

The table has one extra cell so that `k + 1` never falls outside it. The
library's `os.osci` is this very construction on the 65536-value table:

```faust
osci(freq) = s1 + d * (s2 - s1)
with {
    tablesize = pl.tablesize;
    i = int(phasor(tablesize,freq));
    d = ma.decimal(phasor(tablesize,freq));
    s1 = rdtable(tablesize+1,sinwaveform(tablesize),i);
    s2 = rdtable(tablesize+1,sinwaveform(tablesize),i+1);
};
```

## Writing tables: `rwtable`

`rwtable(N, init, write_index, write_value, read_index)` is a table the
program writes while it runs. At every sample it stores `write_value` at
`write_index` and outputs the value at `read_index`. A delay line is the
classic use (Orlarey, Fober and Letz, Den Haag 2006)
([`rwtable_delay.dsp`](../examples/10/rwtable_delay.dsp)):

```faust
index(n) = &(n - 1) ~ +(1);
delay(n, d, x) = rwtable(n, 0.0, index(n), x, (index(n) - int(d)) & (n - 1));
```

The write index goes round a table of n = 2^k cells; the read index is d
cells behind. `& (n - 1)` wraps the index into the table, and unlike `%`
it stays positive when `index(n) - d` is negative. The result equals
`@(d)` sample for sample; `@` is simpler, but `rwtable` gives full control
over what is written where (exercise 2).

## The idiom in the libraries

- `os.oscsin` and `os.osci` read a sine table at the nearest cell and with
  interpolation, as above.
- `ma.primes` reads the prime numbers from a `waveform` of 2048 values.
- `ba.tabulate(C, FX, S, r0, r1, x)` tabulates a function `FX` over
  [r0, r1] in S cells, and reads it with `.val` (nearest), `.lin` (linear)
  or `.cub` (cubic interpolation). Its documentation uses it for
  `ba.midikey2hz`; exercise 3 uses it for `tanh`.
- `it.frdtable` in interpolators.lib reads a table with Lagrange
  interpolation of any order.
- `ba.selectn` is built as a balanced tree of `select2` (`ba.selectnX`),
  which is why it compiles to nested comparisons; `ba.selectmulti` does the
  same with crossfades between neighbours.

## Pitfalls

- **Index range.** When the compiler cannot prove that an index stays in
  the table, it clamps it (the `std::max`/`std::min` above), so an
  out-of-range index silently reads the first or last cell. Keep one extra
  cell for interpolation, and do not count on the clamp for correctness.
- **Tables hold values, not processes.** Choosing among running signals
  needs a selector.
- **`%` can be negative.** Use `& (n - 1)` with a power-of-two size, or
  `ma.modulo`, to wrap an index that may go below zero.
- **Table sizes are constants** (chapter 9).

## Exercises

1. A sixteen-step rhythm stored as 0s and 1s in a `waveform`, played in
   sixteenth notes: a trigger on each step marked 1. Solution:
   [`ex1_drum_pattern.dsp`](../examples/10/solutions/ex1_drum_pattern.dsp).
2. A recorder: while a button is held, write the input into a table of n
   cells; always play the table in a loop. When not recording, send the
   writes to an extra "dead" cell, as the 2003 tutorial advises. Solution:
   [`ex2_recorder.dsp`](../examples/10/solutions/ex2_recorder.dsp).
3. Tabulate `ma.tanh` over [−4, 4] in 256 cells with linear interpolation,
   and measure the error against the exact function (it stays below 1e-4).
   Solution: [`ex3_tabulate.dsp`](../examples/10/solutions/ex3_tabulate.dsp).
