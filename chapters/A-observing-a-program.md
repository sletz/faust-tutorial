# Appendix A. Observing a program

Listening tells you whether a program sounds right; it does not tell you
whether a value is exactly 0, whether a filter is 3 dB down at its cutoff,
or whether a feedback loop will blow up after a minute. This appendix
gathers the tools used throughout the tutorial to *observe* a program.

## The block diagram

```bash
faust -svg program.dsp
```

writes the diagram of every definition into `program-svg/`; the online IDE
shows it in a tab. Use it to check wiring and arities (chapter 2).

## The generated code

```bash
faust program.dsp
```

prints the C++ class the compiler generates. Read the `compute` method at
the end: constants appear as numbers, initialisation-time values as
`fConst`, block-rate values as `fSlow`, and the rest inside the sample loop
(chapter 9). This is the evidence for any claim about cost.

## faustprobe

faustprobe, part of faust-rs, compiles a program with a just-in-time
compiler, runs it offline, and prints samples and statistics. It is built
in the faust-rs repository:

```bash
cargo build --release -p cranelift-ffi --bin faustprobe
```

The options used in this tutorial:

| option | effect |
|---|---|
| `--double` | compute in double precision (use it for measurements) |
| `-n N`, `--sr RATE` | number of samples, sampling rate |
| `--in zero`, `--in dc`, `--in white:SEED`, `--in sine:HZ`, `--in impulse:CH` | the input signal (default: an impulse on every input) |
| `--quiet` | statistics only: peak, RMS, mean, finiteness |
| `--skip N` | leave out the first N samples, a transient |
| `--set PATH=VALUE`, `--at FRAME PATH=VALUE` | set a control, or change it at an exact frame |
| `--list-params` | the controls and their paths |
| `--eval EXPR` | evaluate an expression of the file instead of `process` |
| `--compare OTHER.dsp` | the same excitation to two programs, and the first difference |
| `--freqresp N:FMIN:FMAX` | the frequency response, from the impulse response |
| `--sweep PATH=V1,V2 --reduce rms` | one render per value, one number each |
| `--check all` | same samples at other block sizes, after a reset, and from a second compilation |
| `--fail-above LEVEL` | stop at the first sample above a level |
| `--time` | compile and compute time |

Four examples in [`examples/appendix_a`](../examples/appendix_a):

- [`frequency_response.dsp`](../examples/appendix_a/frequency_response.dsp):
  `fi.lowpass(2, 1000)` is −3.01 dB at 1 kHz; faustprobe also checks that
  the program is linear and time-invariant before trusting the response.
- [`sweep.dsp`](../examples/appendix_a/sweep.dsp): the RMS output of the
  same filter fed with a 1 kHz sine, for three cutoffs.
- [`consistency.dsp`](../examples/appendix_a/consistency.dsp): `--check all`
  on a resonant filter.
- [`unstable.dsp`](../examples/appendix_a/unstable.dsp): a feedback gain
  of 1.1 is stopped by `--fail-above 100`, with the frame where it started.

## Showing signals inside the program

A bargraph passes its input through and shows it; `attach(x, y)` keeps a
bargraph `y` alive without sending it to an output (chapter 8). faustprobe
prints the last value of every bargraph, and debug.lib's `db.probe_*`
functions are ready-made meters.

## How the examples of this tutorial are checked

Every `.dsp` file under `examples/` carries its checks in comments, and
`make check` runs them all ([`scripts/check.py`](../scripts/check.py)):

| line | meaning |
|---|---|
| `// check: ARGS` | `faustprobe ARGS file.dsp` must succeed |
| `// expect: REGEX` | ... and its output must match (one per line) |
| `// check-fails: ARGS` | the command must fail |
| `// expect-error` | both compilers must reject the file |
| `// cpp-expect: REGEX`, `// cpp-absent: REGEX` | the generated C++ must, or must not, match |
| `// cpp: no` | a faust-rs extension: not compiled with the C++ compiler |
| `// faust-rs: no` | checked with the C++ compiler only (the line says why) |

Every file is also compiled by the C++ compiler, unless marked. The checks
are how this tutorial knows that its code does what its text says.
