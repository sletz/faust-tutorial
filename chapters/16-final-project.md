# 16. Final project: a reverb

## The idea

A reverb imitates the thousands of reflections of a sound in a room: a few
distinct early echoes, then a dense tail that decays, faster at high
frequencies than at low ones. It is a good final project because it uses
almost everything in this tutorial: delays and recursion (chapter 4),
state (chapter 5), iteration and pattern matching (chapter 11), higher-order
functions (chapter 12), environments (chapter 13), an interface (chapter 8),
and constraints known at compile time (chapter 9).

We build two classic designs. The first is **Freeverb**, by "Jezar at
Dreampoint", a Schroeder-Moorer reverb of parallel combs and series
allpasses; we rebuild it piece by piece and check that the result is,
sample for sample, the library's `re.mono_freeverb`. The second is a
**feedback delay network** (Jot and Chaigne, 1991), whose decay time we set
and measure.

## Step 1: a comb

The feedback comb of chapter 4 ([`step1_comb.dsp`](../examples/16/step1_comb.dsp)):

```faust
comb(d, g) = + ~ (@(d - 1) : *(g));
```

One impulse gives echoes every d samples, each g times the previous one:
1, 0.7, 0.49... Alone, it sounds metallic: the echoes are regular, and the
comb colours the sound with peaks at multiples of SR/d.

## Step 2: a comb that absorbs

In a room, each reflection loses more high frequencies than low ones.
Freeverb puts the one-pole lowpass of chapter 4 in the feedback of each
comb ([`step2_lbcf.dsp`](../examples/16/step2_lbcf.dsp)):

```faust
lbcf(dt, fb, damp) = (+ : @(max(0, dt - 1))) ~ (*(1 - damp) : (+ ~ *(damp)) : *(fb)) : mem;
```

The delay sits before the output, and the final `mem` makes the first
output come dt samples after the input. Without damping the second echo is
0.8; with `damp = 0.5` it is 0.4, and the rest of it is spread over the
following samples: the echo is duller.

## Step 3: an allpass

Four Schroeder allpasses in series increase the density of echoes without
colouring the sound: their magnitude response is flat
([`step3_allpass.dsp`](../examples/16/step3_allpass.dsp)):

```faust
allpass(maxdel, N, aN) = (+ <: de.delay(maxdel, N - 1), *(aN)) ~ *(-aN) : mem, _ : +;
```

This is the library's `fi.allpass_comb`, and faustprobe checks both claims:
it is identical to the library, and its frequency response
(`--freqresp`, appendix A) is 0 dB to within 3e-13 dB from 100 Hz to
10 kHz.

## Step 4: Freeverb

Eight combs in parallel, their outputs summed, then four allpasses in
series ([`step4_freeverb.dsp`](../examples/16/step4_freeverb.dsp)):

```faust
adapt(n) = int(n * ma.SR / 44100);

comb_tuning(0) = adapt(1116);  comb_tuning(1) = adapt(1188);
comb_tuning(2) = adapt(1277);  comb_tuning(3) = adapt(1356);
comb_tuning(4) = adapt(1422);  comb_tuning(5) = adapt(1491);
comb_tuning(6) = adapt(1557);  comb_tuning(7) = adapt(1617);

allpass_tuning(0) = adapt(556);  allpass_tuning(1) = adapt(441);
allpass_tuning(2) = adapt(341);  allpass_tuning(3) = adapt(225);

freeverb(fb1, fb2, damp, spread) =
    _ <: par(i, 8, lbcf(comb_tuning(i) + spread, fb1, damp))
      :> seq(i, 4, allpass(4096, allpass_tuning(i) + spread, -fb2));
```

- The tunings, in samples at 44.1 kHz, are defined **by cases**
  (chapter 11), and `par` and `seq` read them with their index.
- `adapt` scales them to the actual sampling rate; `int` rounds to whole
  samples (chapter 9).
- `<:` sends the input to the eight combs and `:>` sums them (chapter 2).
- The allpass buffers hold 4096 samples: the longest tuning, 556 samples
  at 44.1 kHz, is 2420 at 192 kHz, the highest value of `ma.SR` (see the
  pitfalls).

The delay lengths are chosen without common factors, so that the echoes of
the eight combs do not coincide. faustprobe finds this program identical,
sample for sample, to `re.mono_freeverb(0.84, 0.5, 0.2, 0)` in reverbs.lib,
at 44.1 kHz and at 96 kHz.

## Step 5: a playable stereo reverb

([`step5_stereo.dsp`](../examples/16/step5_stereo.dsp))

```faust
stereo_freeverb(fb1, fb2, damp, spread) = + <: freeverb(fb1, fb2, damp, 0), freeverb(fb1, fb2, damp, spread);

dry_wet(mix, fx) = _, _ <: (_, _), fx : ro.interleave(2, 2) : si.interpolate(mix), si.interpolate(mix);

reverb = environment {
    SIZE = 0.5;
    ui(x) = hgroup("reverb", x);
    size = ui(hslider("[0] size", SIZE, 0, 1, 0.01)) : si.smoo;
    damp = ui(hslider("[1] damping", 0.5, 0, 1, 0.01)) : si.smoo;
    mix  = ui(hslider("[2] wet [style:knob]", 0.3, 0, 1, 0.01)) : si.smoo;
    fb1  = 0.7 + 0.28 * size;
    // the parentheses matter: a comma inside an argument list separates arguments
    play = dry_wet(mix, (stereo_freeverb(fb1, 0.5, damp * 0.4, 23) : *(0.1), *(0.1)));
};

process = reverb.play;
```

- **Stereo** comes from the same design with all delays lengthened by 23
  samples on the right, which decorrelates the two channels (this is
  `re.stereo_freeverb`).
- **Dry/wet** is a higher-order function (chapter 12): it takes the reverb
  as an argument, runs the dry and the wet signals side by side,
  interleaves them (`ro.interleave`) and crossfades each pair.
- **The interface** is grouped and smoothed (chapter 8), and lives in an
  environment whose `SIZE` constant can be replaced by substitution
  (chapter 13): `reverb[SIZE = 0.9;].play` is a preset for a large room.

The note in the code is a trap this tutorial fell into while writing it: in
`dry_wet(mix, A : B, C)`, the comma is read as a separator between
arguments, giving three arguments instead of two. Parentheses make the
second argument one block.

## Step 6: a feedback delay network

Freeverb's combs are independent: each recirculates its own echoes. A
feedback delay network mixes all its delay lines at every round trip, which
gives a denser and smoother tail
([`step6_fdn.dsp`](../examples/16/step6_fdn.dsp)):

```faust
N = 8;
lengths = (1031, 1327, 1523, 1801, 2053, 2311, 2579, 2803);
len(i) = ba.take(i + 1, lengths);

T60 = hslider("T60 [unit:s]", 1, 0.1, 10, 0.01);
gain(i) = pow(10, -3 * len(i) / (T60 * ma.SR));

line(i) = @(len(i) - 1) : *(gain(i));           // ~ adds the last sample
mixing = ro.hadamard(N) : par(i, N, /(sqrt(N)));

fdn = (si.bus(2 * N) :> par(i, N, line(i))) ~ mixing;

process = _ <: si.bus(N) : fdn :> _, _;
```

- The **lengths** are prime numbers, a list read with `ba.take`
  (chapter 11).
- The **mixing matrix** is `ro.hadamard(8)`, built by divide and conquer
  (chapter 11), divided by √8 so that it keeps the energy: whatever enters
  the matrix comes out with the same total power.
- The **structure** is one recursion over eight wires: the lines' outputs
  go through the matrix and come back, added to the input, on the first
  eight inputs of the merge (chapter 2).
- The **decay** is set by the gains alone. A signal that travels a line of
  `len(i)` samples must lose 60 dB per T60 seconds, that is a factor
  10^(−3·len/(T60·SR)). Since the matrix keeps the energy, the whole
  network then decays by 60 dB in T60.

faustprobe measures it: with T60 = 1 s, the RMS level of the impulse
response is 0.0110 between 0.2 and 0.3 s and 1.13e-5 one second later, a
ratio of 972, or 59.7 dB.

## Going further in the libraries

- `re.jcrev` in reverbs.lib is John Chowning's reverb, three allpasses and
  four combs, in about twenty lines.
- `re.fdnrev0` is a general feedback delay network, with its own recursive
  Hadamard matrix and a filter bank that gives each frequency band its own
  decay time; `dm.fdnrev0_demo` in demos.lib wraps it in an interface.
- `re.zita_rev1_stereo` is Fons Adriaensen's reverb, an 8 × 8 network with
  separate low and mid decay times, and a reference for quality.

## Pitfalls

- **Maximum delays and the sampling rate.** A delay tuned in samples at
  44.1 kHz grows with the sampling rate, and a delay longer than its
  buffer is silently clamped. Freeverb's allpasses had a buffer of 1024
  samples in reverbs.lib until faustlibraries 2.74.3 (reverbs.lib 1.5.2):
  at 96 kHz, 556 samples at 44.1 kHz become 1210, and the reverb was
  detuned above 81 kHz. Size buffers for the highest rate you support
  (chapter 9).
- **Stability.** A network whose matrix gains energy, or whose gains
  exceed 1, grows without bound. Check with faustprobe's `--fail-above`
  when experimenting.
- **Commas in arguments.** Parenthesise a block that contains a comma when
  it is passed as an argument.

## Exercises

1. A pre-delay of up to 100 ms before the reverb, bounded by its slider's
   range. Check that pre-delaying the input equals delaying the output.
   Solution: [`ex1_predelay.dsp`](../examples/16/solutions/ex1_predelay.dsp).
2. The feedback delay network with its size N as a compile-time parameter
   and its lengths taken from `ma.primes`; check that 4 and 16 lines both
   decay by about 60 dB in T60. Solution:
   [`ex2_fdn_size.dsp`](../examples/16/solutions/ex2_fdn_size.dsp).
3. Damping: a one-pole lowpass in each line. Measure that the high band of
   the tail now dies much faster than its low band. Solution:
   [`ex3_damping.dsp`](../examples/16/solutions/ex3_damping.dsp).
