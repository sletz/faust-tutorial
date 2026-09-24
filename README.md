# A progressive Faust tutorial

This tutorial teaches programming in [Faust](https://faust.grame.fr), the
functional language for real-time audio signal processing, from a first
sound to a complete reverb. Each chapter only relies on the ones before it.

It is built on the *idioms* that the practice of Faust programmers has
produced, collected in the document "Faust programming idioms", and ties
each of them to the functions of the standard libraries
([faustlibraries](https://github.com/grame-cncm/faustlibraries)) that use
it. It also draws on the earlier Faust tutorials (Gaudrain and Orlarey,
2003; Bole, 2008) and on the papers of the Faust team, and says so where it
does.

Every program in the tutorial, 173 of them, is compiled by the C++ Faust
compiler and run by faustprobe, and its output is checked against what the
text says (appendix A). The plan of the tutorial is in [PLAN.md](PLAN.md).

## Contents

**Part A. The language**

1. [First sound](chapters/01-first-sound.md)
2. [Block-diagram algebra](chapters/02-block-diagram-algebra.md)
3. [Naming inputs](chapters/03-naming-inputs.md)
4. [One-sample memory](chapters/04-one-sample-memory.md)

**Part B. Building control signals**

5. [State with several variables](chapters/05-state-with-several-variables.md)
6. [Logical signals and events](chapters/06-logical-signals-and-events.md)
7. [Periodic signals and sequences](chapters/07-periodic-signals-and-sequences.md)
8. [User interface](chapters/08-user-interface.md)

**Part C. Computing at compile time**

9. [Compile time or run time](chapters/09-compile-time-or-run-time.md)
10. [Choosing among values](chapters/10-choosing-among-values.md)
11. [Iteration and pattern matching](chapters/11-iteration-and-pattern-matching.md)
12. [Higher-order programming](chapters/12-higher-order-programming.md)

**Part D. Writing reusable code**

13. [Environments](chapters/13-environments.md)
14. [Generic, then specialised](chapters/14-generic-then-specialised.md)
15. [Writing a library](chapters/15-writing-a-library.md)
16. [Final project: a reverb](chapters/16-final-project.md)

**Appendices**

- A. [Observing a program](chapters/A-observing-a-program.md)
- B. [Automatic differentiation](chapters/B-automatic-differentiation.md) (faust-rs)
- C. [Cheat sheet](chapters/C-cheat-sheet.md)

## Layout

```text
chapters/           the text, one file per chapter
examples/NN/        the programs of chapter NN, and solutions/ for its exercises
examples/appendix_a, examples/appendix_b
scripts/check.py    runs the checks written in the programs' comments
Makefile            make check
```

## Checking the examples

```bash
make check
```

compiles every program with the C++ compiler (`faust`) and runs the
faustprobe commands written in its comments. It expects the faust-rs and
faustlibraries checkouts next to this one (`../faust-rs`,
`../../faustlibraries`); `FAUST`, `FAUSTPROBE` and `FAUSTLIBRARIES`
override the paths. `make check DIR=examples/07` checks one chapter.

## What the checks found

Writing checked examples turned up a few things worth knowing, each told
in its chapter:

- in the idioms document, the oscillator network rewritten with pattern
  matching did not reproduce the original (chapter 11), and the two
  versions of `release` are not equivalent (chapter 6);
- in the libraries, `ba.line` and `mm.line` overshoot on ramps that are not
  a whole number of samples (chapter 5), `en.adsr` stretches when a velocity
  is used as its gate (chapter 7), `ba.impulsify` does not do what its
  documentation says (chapter 6), and Freeverb's allpass buffers are too
  short above 80 kHz (chapter 16);
- in faust-rs, two divergences from the C++ compiler: rules were not always
  tried in textual order (chapter 11), and an environment passed as an
  argument was not resolved (chapter 13). Both are fixed in faust-rs
  (commits ff228fcc and f046cd03), and both examples are now checked on
  both compilers.
