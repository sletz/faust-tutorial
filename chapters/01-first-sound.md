# 1. First sound

## The idea

A Faust program describes a **signal processor**: a box that receives
signals and computes other signals from them, at every sample, tens of
thousands of times per second. The program never says "for each sample, do
this": it describes *what the box is*, and the compiler writes the loop.

The main box is always called `process`. The simplest program has one
output that is 0.5 at every sample ([`constant.dsp`](../examples/01/constant.dsp)):

```faust
process = 0.5;
```

A number is already a signal processor: no input, one output, constant.

## Operators are blocks

`*(0.5)` is a block with one input and one output that multiplies its input
by 0.5 ([`gain.dsp`](../examples/01/gain.dsp)):

```faust
process = *(0.5);
```

`+`, `-`, `*`, `/`, `min`, `max`, `sin`... are all blocks. Written alone,
`+` has two inputs and one output. Written with one argument, `*(0.5)` fixes
one of the two inputs and leaves only one. Written in the usual infix
notation, `a * b` combines two signals `a` and `b`. The three notations
denote the same operator; chapter 3 shows that they are equivalent.

## An oscillator

The standard libraries provide hundreds of functions. They are imported all
at once, and each one is named with a two-letter prefix: `os.` for
oscillators, `fi.` for filters, `no.` for noises, `ba.` for basic functions
([`sine.dsp`](../examples/01/sine.dsp)):

```faust
import("stdfaust.lib");

process = os.osc(440) * 0.1;
```

`os.osc(440)` is a 440 Hz sine wave of amplitude 1; the product by 0.1 keeps
the output from clipping. An audio output must stay within [-1, 1].

Two expressions separated by a comma give two outputs, one per loudspeaker
([`two_channels.dsp`](../examples/01/two_channels.dsp)):

```faust
process = os.osc(440) * 0.1, os.osc(660) * 0.1;
```

## A slider

A user interface is declared inside the program itself. `hslider` is a
horizontal slider: label, initial value, minimum, maximum, step
([`slider.dsp`](../examples/01/slider.dsp)):

```faust
import("stdfaust.lib");

gain = hslider("gain", 0.1, 0, 1, 0.01);
freq = hslider("freq", 440, 50, 2000, 1);

process = os.osc(freq) * gain;
```

`gain` and `freq` are **definitions**: names given to expressions. A slider
is a signal like any other, whose value is chosen by the user. It can be
added, multiplied, passed to an oscillator. Chapter 8 is about user
interfaces.

## Listening, and measuring

In the online IDE (<https://faustide.grame.fr>), pasting the program and
running it is enough to hear it and move its sliders. The diagram tab shows
the box the program describes.

Listening does not tell everything: a signal may be inaudible, too loud, or
contain an infinite value. Throughout this tutorial, programs are also
**measured** with `faustprobe`, which compiles a program, runs it offline
and prints its samples and some statistics:

```bash
faustprobe --double --in zero -n 44100 --quiet examples/01/sine.dsp
```

```text
# frames=44100 sr=44100 window=0..44100 (44100 frames)
# out0: peak=0.09999997748012666 rms=0.07071067803218169 dc=-1.9565096361497186e-9 finite=yes peak_at=877
```

`--in zero` feeds silence to the inputs (this program has none), `-n` is the
number of samples computed, `--quiet` hides the list of samples. The peak is
0.1, the RMS value 0.1/√2 and the mean `dc` is zero: this is indeed a sine
wave of amplitude 0.1. Without `--quiet`, faustprobe prints one sample per
line. Appendix A describes the tool in more detail.

Every example file ends with `// check:` and `// expect:` lines: the
faustprobe command that checks it and what its output must contain.
`make check` runs them all.

## The idiom in the libraries

There is nothing magic about `os.osc`. It is defined in `oscillators.lib` as
another name for `oscsin`:

```faust
osc = oscsin;

oscsin(freq) = rdtable(tablesize, sinwaveform(tablesize), int(phasor(tablesize,freq)))
with {
    tablesize = pl.tablesize;
};
```

A table holds one period of a sine, and a phase counter (`phasor`) reads it
at the right speed. Everything in this definition will be explained by
chapter 10: `with` in chapter 3, the phase counter in chapter 7, tables in
chapter 10. Reading the libraries is the best way to learn Faust, and every
chapter points into them.

## Pitfalls

- **The semicolon** ends every definition. Forgetting it gives a syntax
  error on the *next* line.
- **Integers and floats**: `1/2` is 0.5 in Faust, because division always
  gives a float; `int(7/2)` is 3. Chapter 9 comes back to types.
- **Clipping**: a sum of sources quickly exceeds 1. Measure the peak with
  faustprobe rather than guessing it.

## Exercises

1. White noise (`no.noise`) whose level is set by a slider called "level".
   Check with faustprobe that at level 1 the peak is close to 1. Solution:
   [`ex1_noise.dsp`](../examples/01/solutions/ex1_noise.dsp).
2. A chord of three sine waves (440, 554.37 and 659.26 Hz) on a single
   output, never exceeding 0.3 in amplitude. Solution:
   [`ex2_chord.dsp`](../examples/01/solutions/ex2_chord.dsp).
