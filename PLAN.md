# Plan of the Faust tutorial

This tutorial teaches Faust programming step by step: each chapter only
relies on the ones before it. It starts from the *idioms* that the practice
of Faust programmers has produced (the "Faust programming idioms" document)
and ties each of them to the functions of the standard libraries
(`faustlibraries`) that use it.

## Audience and prerequisites

- Some programming experience, in any language.
- Knowing what a sample, a sampling rate and a lowpass filter are. No
  advanced signal processing is required: a large part of Faust work is
  building the signals that *drive* the algorithms, not the algorithms
  themselves.
- No functional programming background: it is introduced along the way.

## Tools

- The online IDE (<https://faustide.grame.fr>) to listen and see block
  diagrams, or the `faust` command-line compiler.
- `faustprobe` (from faust-rs) to *measure* a program: compile it, render it
  offline, read its samples and statistics. Every example and every exercise
  solution carries the faustprobe commands that check it, and `make check`
  runs them all, against both the C++ compiler and faust-rs.

## Shape of each chapter

1. **The idea**: the concept, in a few paragraphs.
2. **A minimal example** that runs (`examples/NN/*.dsp`).
3. **The idiom in the libraries**: the same idea in a real function of
   `faustlibraries`, quoted with its prefix (`ba.`, `si.`, ...) and its
   file.
4. **Pitfalls**: typical mistakes and how to recognise them.
5. **Exercises**, with solutions in `examples/NN/solutions/`, checked by the
   same mechanism as the examples.

## Part A. The language

1. **First sound.** `process`, `import("stdfaust.lib")`, an oscillator, a
   gain, two outputs, a slider. Listening in the IDE, measuring with
   faustprobe. Numbers and operators as blocks. Library anchor: `os.osc`.
2. **Block-diagram algebra.** The five compositions `:` `,` `<:` `:>` `~`,
   the wire `_` and the cut `!`, arity and the composition rules, operator
   priorities, arity errors, reading SVG diagrams. A stereo mixer.
   Anchors: `si.bus`, `si.block`, `ro.cross`, `route`.
3. **Naming inputs.** From pure wiring to arguments: `foo(a, b, c) = ...`,
   the `foo1`..`foo3` variants of the idioms document; `with`; applying a
   function is sending it signals; `inputs(x)` and `outputs(x)`. Anchors:
   `si.interpolate`, `fi.tf1`, `ma.sub`.
4. **One-sample memory.** `mem`, `x'`, `@(n)`; recursion `~` and its
   implicit one-sample delay; the integrator `+ ~ _`, the counter
   `1 : + ~ _`, the moving sum, the one-pole filter. Time only exists in
   the past. Anchors: `fi.integrator`, `fi.pole`, `ba.time`, `os.impulse`,
   `ba.slidingSum`, `si.smooth`.

## Part B. Building control signals

5. **State with several variables.** The `tick ~ (_, _) : !, _` pattern:
   as many feedback wires as state variables, `tick(x, y) = x1, y1` returns
   the next values, the output cuts what is internal. Examples: `line~`
   from Max (two writings), the quadrature oscillator `os.quadosc`,
   `ba.peakholder`; `letrec`, another way to write the same state. The
   overshoot of a `line~` whose ramp length is not an integer, and its fix
   (`ba.line` and `mm.line` had it until faustlibraries 2.74.3).
6. **Logical signals and events.** Booleans are 0 and 1; rising, falling
   and any edges; `impulse`, `release`, `trigger`; reset by
   multiplication; `min` and `max` as logic; sample and hold; counters with
   reset; `select2` and `ba.if`. Counting the edges of a MIDI clock over one
   second. Anchors: `ba.counter`, `ba.sAndH`, `ba.latch`, `ba.countdown`,
   `ba.toggle`, `ba.peakhold`, the release counter of `en.adsr`.
7. **Periodic signals and sequences.** The phasor and `ma.frac`, phase
   handling, pulse trains, metronome, step sequencer; from phase to a table
   oscillator; envelopes, ramps, control smoothing. Final example: the
   looping ADSR. Anchors: `os.lf_sawpos`, `ba.period`, `ba.pulse`,
   `ba.beat`, `os.lf_pulsetrain`, `no.lfnoise0`, `en.adsr`, `si.smoo`.
8. **User interface.** Sliders, buttons, checkboxes, `nentry`, groups,
   paths and labels, metadata (`[unit:Hz]`, `[scale:log]`, `[style:knob]`,
   `[style:menu{...}]`, `[midi:...]`), bargraphs and `attach` to show an
   internal signal, the `*_demo` idiom of demos.lib, bypass with a
   checkbox. Anchors: `dm.gate_demo`, `dm.moog_vcf_demo`, `ba.bypass1`,
   `db.probe_rms_db`.

## Part C. Computing at compile time

9. **Compile time or run time.** Faust does not compile the text but the
   semantics of the program: symbolic propagation, constants folded,
   unused outputs removed, common subexpressions shared. What must be known
   at compile time (number of channels, filter order, maximum delay, table
   size) and what may change while the program runs. `int` and `float`,
   and the errors met when a run-time value reaches a place that needs a
   constant. Anchors: `de.delay`, `de.fdelay`, `ba.if` versus `select2`.
10. **Choosing among values.** `waveform` + `rdtable` against
    `ba.selectn`: the major-scale table, the "choice mapper", the cost of
    each form; `rdtable` filled by a generator, `rwtable`; tabulating an
    expensive function. Anchors: `os.oscsin`, `os.osci`, `ba.selectn`,
    `ba.tabulate`, `it.frdtable`.
11. **Iteration and pattern matching.** `par`, `seq`, `sum`, `prod` with an
    index; definitions by cases `foo(0) = ...; foo(n) = ...` and `case`;
    recursion on an integer; patterns on a list `(x, xs)`; the oscillator
    network rewritten with patterns, and why it compiles faster. Anchors:
    `si.bus`, `si.repeat`, `ro.hadamard`, `ba.take`, `ba.count`,
    `fi.convN`, `os.sawN`.
12. **Higher-order programming.** Blocks as arguments and as results,
    lambda abstractions `\(x).(...)`, partial application, the library
    convention (fixed parameters first, audio signal last), combinators of
    `routes.lib` and `signals.lib`. Anchors: `ba.bypass_fade`,
    `rm.parReduce`, `it.interpolator_linear`, `ba.countdown`.

## Part D. Writing reusable code

13. **Environments.** Namespaces, `environment { }`, `library()`, the state
    variable filter `svf` as a "class", explicit substitution
    `lib[NAME = value;]`, environments as objects (`so.sound`), passed as
    arguments. Anchors: `fi.svf`, `mm.filtercoeff`, `no._noise_env`,
    `os[SAFE=1;]`, `db[DEBUG=0;]`.
14. **Generic, then specialised.** A general algorithm with dynamic
    parameters, specialised by fixing constants or cutting outputs: the
    compiler only generates the code that is used. Anchors: the `svf`
    family, Eric Tarr's multi-output filters in vaeffects.lib, the formant
    models of physmodels.lib.
15. **Writing a library.** Layers (generic block, intermediate level,
    user-facing wrappers), prefixes and `stdfaust.lib`, `declare`, the
    documentation format of the libraries, tests.
16. **Final project.** A complete reverb built step by step (comb and
    allpass filters, a feedback delay network, the interface), which reuses
    every chapter.

## Appendices

- **A. Observing a program**: faustprobe, diagrams, `attach`, bargraphs,
  how the examples of this tutorial are checked.
- **B. Automatic differentiation**: `fad` and `rad` in faust-rs,
  extensions absent from the C++ compiler, to learn the parameters of a
  Faust program by gradient descent.
- **C. Cheat sheet**: syntax, operator priorities, library prefixes.

## Corrections to the idioms document

The tutorial takes the examples of the idioms document after checking them.
Those that did not compile or did not do what the text said are corrected,
and the chapter says so:

- the `impulse` definition quoted from `faust_tutorial.pdf` looks truncated
  because the underscores were lost when it was copied out of the PDF; the
  original, `impulse = _ <: _, mem : - : (_ > 0.0);`, is complete;
- the two versions of `release` are not equivalent: the one with
  `max(0, ...)` never goes below zero;
- the pattern-matching rewrite of the oscillator network does not reproduce
  the original: the original chains four nodes, the rewrite three, in
  another order.

## Library definitions not taught as they are

The survey of `faustlibraries` found definitions that a tutorial must not
present as models without a warning. The chapters that use them say what is
wrong and show a sound version. Among them: `ba.pulse_countdown_loop` does
not count down for a positive `n`; `os.oscb` has an amplitude of
1/sin(2πf/SR), not 1. Each claim is checked with faustprobe before it is
written in a chapter. Four others were fixed in faustlibraries 2.74.3
after the tutorial found them, and the chapters tell them in the past:
`ba.line` and `mm.line` overshot when the ramp length in samples was not an
integer; `ba.impulsify`'s documentation said it outputs the current sample,
not the positive first difference; `en.adsr` and `en.asr` stretched when
the gate was a velocity below 1; Freeverb's allpass buffers were too short
above 81 kHz.
