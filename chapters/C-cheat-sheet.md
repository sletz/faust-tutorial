# Appendix C. Cheat sheet

## Compositions

| written | name | arity rule |
|---|---|---|
| `A : B` | sequential | outputs(A) = inputs(B) |
| `A , B` | parallel | none |
| `A <: B` | split | inputs(B) multiple of outputs(A) |
| `A :> B` | merge (sum) | outputs(A) multiple of inputs(B) |
| `A ~ B` | recursion, one-sample delay in the loop | inputs(B) ≤ outputs(A), outputs(B) ≤ inputs(A) |

`_` is a wire, `!` a cut.

## Operator priorities

From the C++ parser (`faustparser.y`), from the weakest to the strongest:

1. `with`, `letrec`
2. `<:`, `:>`
3. `:`
4. `,`
5. `~`
6. `<`, `<=`, `==`, `>`, `>=`, `!=`
7. `+`, `-`, `|`
8. `*`, `/`, `%`, `&`, `xor`, `<<`, `>>`
9. `^` (power)
10. `@`
11. `'` (one-sample delay)
12. `.` (environment access)

So `A, B : C` is `(A, B) : C`, and `x + y ~ z` is `(x + y) ~ z`. When in
doubt, parenthesise.

## Primitives and constructs

| construct | meaning | chapter |
|---|---|---|
| `mem`, `x'`, `x@n` | delay by 1, 1, n samples | 4 |
| `select2(c, a, b)` | `a` if c is 0, `b` if c is 1 | 6 |
| `int(x)`, `float(x)` | conversions; `int` truncates | 9 |
| `rdtable(n, gen, i)` | read-only table filled by `gen` | 10 |
| `rwtable(n, init, wi, wv, ri)` | read-write table | 10 |
| `waveform{...}` | a constant table | 10 |
| `par`, `seq`, `sum`, `prod` | `(i, N, block)`: repetition with an index | 11 |
| `f(0) = ...; f(n) = ...;`, `case {...}` | rules, first match wins | 11 |
| `\(x).(expr)` | lambda abstraction | 12 |
| `with { ... }` | local definitions | 3 |
| `letrec { 'x = ...; }` | state as equations | 5 |
| `environment { ... }`, `library("f.lib")` | named groups of definitions | 13 |
| `env[name = value;]` | explicit substitution | 13 |
| `inputs(x)`, `outputs(x)` | arity, a constant | 3 |
| `attach(x, y)` | output x, keep y alive | 8 |
| `button`, `checkbox`, `hslider`, `vslider`, `nentry` | inputs from the user | 8 |
| `hbargraph`, `vbargraph` | displays | 8 |
| `hgroup`, `vgroup`, `tgroup` | layout and paths | 8 |

## Library prefixes (`stdfaust.lib`)

| prefix | library | prefix | library |
|---|---|---|---|
| `aa` | aanl.lib (antialiased nonlinearities) | `ma` | maths.lib |
| `an` | analyzers.lib | `mi` | mi.lib (mass-interaction) |
| `ba` | basics.lib | `mo` | motion.lib |
| `co` | compressors.lib | `no` | noises.lib |
| `db` | debug.lib | `os` | oscillators.lib |
| `de` | delays.lib | `pf` | phaflangers.lib |
| `dm` | demos.lib | `pl` | platform.lib |
| `dx` | dx7.lib | `pm` | physmodels.lib |
| `ef` | misceffects.lib | `qu` | quantizers.lib |
| `en` | envelopes.lib | `re` | reverbs.lib |
| `fd` | fds.lib (finite differences) | `rm` | reducemaps.lib |
| `fi` | filters.lib | `ro` | routes.lib |
| `ho` | hoa.lib (ambisonics) | `si` | signals.lib |
| `hy` | hysteresis.lib | `so` | soundfiles.lib |
| `it` | interpolators.lib | `sp` | spats.lib |
| `la` | linearalgebra.lib | `sy` | synths.lib |
| `sf` | all.lib (every library, flat) | `ve` | vaeffects.lib |
| `vl` | version.lib | `wa` | webaudio.lib |
| | | `wd` | wdmodels.lib (wave digital) |

## Conventions of the libraries

- Parameters known at compile time are written in capitals.
- Fixed parameters come first, the audio signal last.
- Internal helpers live in `with` blocks, environments, or start with `_`.
- `*_demo` functions in demos.lib add an interface to a library function;
  instrument models come as core, `_ui`, `_ui_MIDI`.
