# 7. Periodic signals and sequences

## The idea

Oscillators, LFOs, metronomes, sequencers and looping envelopes all rest on
one signal: the **phase**, a number that climbs from 0 to 1 once per period
and wraps back to 0. Once you have the phase, every periodic shape is a
function of it, every beat is a wrap of it, and every sequence is a count of
its wraps.

## The phasor

The phase grows by f/SR per sample, where f is the frequency and SR the
sampling rate, and keeps only its fractional part
([`phasor.dsp`](../examples/07/phasor.dsp)):

```faust
phasor(f) = (+(f / ma.SR) : ma.frac) ~ _;
```

This is the integrator of chapter 4 with `ma.frac` inside the loop, so that
the state never grows beyond 1. `ma.frac(x) = x - floor(x)` keeps the phase
in [0, 1) even for a negative frequency, which runs the phase backwards.

At 44.1 kHz a frequency of 11025 Hz is four samples per period: the phase
goes 0.25, 0.5, 0.75, 0, 0.25... The library's `os.lf_sawpos` is the same
phasor, but it starts at 0 instead of one step later.

## Shapes from the phase

([`waveforms.dsp`](../examples/07/waveforms.dsp))

```faust
p = os.lf_sawpos(freq);

sine     = sin(2 * ma.PI * p);
saw      = 2 * p - 1;
square   = 2 * (p < 0.5) - 1;
triangle = 4 * abs(p - 0.5) - 1;
pulse(d) = p < d;                     // 0/1 pulse, duty cycle d
```

The comparison `p < 0.5` is a condition (chapter 6) that holds during the
first half of each period. A phase offset is an addition followed by a new
wrap ([`phase_offset.dsp`](../examples/07/phase_offset.dsp)): a sine whose
phase is shifted by a quarter period is a cosine, to within 1e-12.

These shapes are fine for LFOs and control signals. As audio, the saw,
square and triangle alias: their sharp corners contain harmonics above half
the sampling rate, which fold back as inharmonic noise. oscillators.lib has
alias-suppressed versions (`os.sawtooth`, `os.square`, `os.polyblep_saw`),
and this chapter's section on the libraries shows where to read them.

## Beats

A beat is the moment the phase wraps. The phase then drops, so the wrap is
detected by comparing the phase with its previous value
([`metronome.dsp`](../examples/07/metronome.dsp)):

```faust
wraps(p) = p < p';
beat = os.lf_sawpos(bpm / 60) : wraps;
```

At 120 beats per minute and a rate of 1 kHz, `beat` is 1 at frames 500,
1000, 1500... The library's `ba.beat(bpm)` counts samples instead of
accumulating a phase, and also clicks at frame 0:

```faust
tempo(t) = (60*ma.SR)/t;
period(p) = %(int(p))~+(1');
pulse(p) = period(p) : \(x).(x <= x');
beat(t) = pulse(tempo(t));
```

`ba.period` is a counter modulo p that starts at 0 (the `1'` adds 0 at the
first sample, then 1). `ba.pulse` is 1 when that counter does not grow,
that is at its first sample and at every wrap. The `\(x).(...)` notation is
a lambda abstraction, the subject of chapter 12. Because `ba.period` works
in whole samples, `ba.beat` rounds the period down: at a tempo where
60·SR/bpm is not an integer, it runs a little fast.

## Sequences

Counting beats gives a position; the position modulo the length of a
sequence gives a step; a table gives the value of each step
([`sequencer.dsp`](../examples/07/sequencer.dsp)):

```faust
beat = ba.beat(bpm);                           // 1 at frame 0, then every beat
step = beat : + ~ _ : -(1) : int : %(8);       // 0, 1, ..., 7, 0, ...
note = waveform{60, 62, 64, 65, 67, 69, 71, 72}, step : rdtable;

voice = os.osc(ba.midikey2hz(note)) * en.ar(0.002, 0.2, beat);
```

`+ ~ _` counts the beats (1 after the first beat), `-(1)` makes the first
step 0, and `%(8)` wraps. `waveform{...}` is a constant table and `rdtable`
reads it; chapter 10 explains both. `ba.midikey2hz` converts a MIDI note
number to a frequency, and `en.ar` is an attack-release envelope started by
each beat.

## Envelopes and smoothing

Envelopes are state machines started by events, built exactly like the
examples of chapters 5 and 6. The library provides the classic ones in
envelopes.lib: `en.ar(attack, release, trigger)`,
`en.asr(attack, sustain, release, gate)` and
`en.adsr(attack, decay, sustain, release, gate)`, with times in seconds and
the sustain level between 0 and 1.

One detail of `en.adsr` matters: the value of its gate does not scale it.
Its attack counter counts one sample per sample while the gate is positive
(`atime = +(float(gate > 0)) ~ ...`), so a **velocity** of 0.5 used as the
gate gives the whole envelope, up to 1, with the times asked for. To play
softer, pass a 0/1 gate and multiply by the velocity
([`adsr_velocity.dsp`](../examples/07/adsr_velocity.dsp)):

```faust
process = en.adsr(0.01, 0.1, 0.5, 0.1, velocity),
          en.adsr(0.01, 0.1, 0.5, 0.1, velocity > 0) * velocity;
```

With a velocity of 0.5 at 48 kHz, both outputs peak at sample 479, the
end of the 10 ms attack: the first at 1.0, the second at 0.5.

A slider that jumps makes a click. `si.smoo` is the one-pole lowpass of
chapter 4 with a pole of 1 − 44.1/SR, a time constant of about 23 ms
([`smoothing.dsp`](../examples/07/smoothing.dsp)): after a jump from 0 to 1,
the smoothed value is 0.632 after 1000 samples at 44.1 kHz. Every
`hslider` that drives a gain or a frequency in an audio path should go
through `si.smoo`.

## Example: the looping ADSR

The idioms document ends with a question from a user of the Faust mailing
list, who wanted an ADSR that restarts once its release has finished, and
Dario Sanfilippo's answer ([`looping_adsr.dsp`](../examples/07/looping_adsr.dsp)):

```faust
A = .01;
D = 1.1;
S = .1;
R = .01;
L = A + D + S + R;
ratio = (A + D + S) / L;

process = os.phasor(1, 1/L) < ratio : en.adsr(A, D, S, R);
```

The phasor's period is the length L of the whole envelope. The gate is open
while the phase is below the fraction of L taken by attack, decay and
sustain, and closed for the rest, which is exactly the release time. When
the phase wraps, the gate opens again and the envelope restarts. Here the
"sustain" parameter of the function holds the time S spent at the sustain
level, which `en.adsr` does not know about: it is encoded in the gate's
duty cycle. `os.phasor(1, f)` is a phasor scaled to a table of size 1, which
is `os.lf_sawpos(f)`.

At 1 kHz a cycle lasts 1220 samples: the attack peaks at sample 9, the
sustain holds 0.1 until sample 1210, the release reaches 0 at 1220, and the
next attack begins.

## The idiom in the libraries

**The reference phasor.** `os.lf_sawpos` and every table oscillator rest on
`_phasor_imp` in oscillators.lib:

```faust
_phasor_imp(freq, reset, phase) = (select2(hard_reset, +(incr(SAFE)), phase) : ma.decimal) ~ _
with {
    ...
    hard_reset = (1-1')|reset;
};
```

It is our phasor plus two features: a `reset` input that jumps the phase to
a given value (hard sync), and a first sample forced to `phase` by
`1-1'`, the impulse of chapter 4. `SAFE` chooses, at compile time, between
a plain increment and one that avoids increments too small to change the
phase; chapter 13 shows how such a constant is set.

**Oscillators, from simple to refined.** oscillators.lib reads well in this
order:

1. `os.m_oscsin`: `lf_sawpos(freq) : *(2*ma.PI) : sin`, the sine of the
   phase, computed with `sin` at every sample;
2. `os.oscsin` (`os.osc`): the same phase reading a table of 65536 sine
   values, cheaper than `sin`;
3. `os.osci`: the table read with linear interpolation between neighbours;
4. `os.lf_saw`, `os.lf_triangle`, `os.lf_squarewave`: the shapes of this
   chapter, for LFOs;
5. `os.oscrs`, `os.quadosc`: recursive oscillators that rotate a vector
   (chapter 5);
6. `os.polyblep_saw`, `os.sawN`: alias-suppressed audio waveforms.

**Random steps.** `no.lfnoise0(freq)` is a random value held for one period:

```faust
lfnoise0(freq) = noise : ba.latch(os.oscrs(freq));
```

a noise sampled at each rising zero crossing of a sine. The noise itself is
the recursion quoted in chapter 4:

```faust
random = +(seed) ~ *(1103515245); // "linear congruential"
noise = random / RANDMAX
```

Each sample multiplies the previous integer by 1103515245 and adds a seed;
the 32-bit integer overflow keeps the result in range and scrambles it, and
the division by 2^31 − 1 brings it to [-1, 1]. The same seed always gives
the same sequence, which is why two `no.noise` in a program are the same
signal. `no.multinoise(N)` gives N different ones.

## Pitfalls

- **The phase must wrap inside the loop.** `(+(f/ma.SR) ~ _) : ma.frac`
  looks equivalent, but its state grows forever and loses precision. At
  440 Hz in single precision, faustprobe finds that this phase no longer
  moves at all after 590 seconds: the increment has become smaller than
  the spacing of the floats around the state.
- **`ba.beat` rounds its period** to whole samples.
- **A velocity used as a gate does not scale** `en.adsr` and `en.asr`:
  multiply their output by it.
- **Raw shapes alias** as audio; use them as LFOs, or use the
  alias-suppressed oscillators.

## Exercises

1. A triangle LFO in [-1, 1] with a frequency and a phase slider. Check that
   a phase of 0.5 starts it at −1. Solution:
   [`ex1_triangle_lfo.dsp`](../examples/07/solutions/ex1_triangle_lfo.dsp).
2. A metronome whose first beat of every four is twice as loud as the
   others. Solution: [`ex2_accent.dsp`](../examples/07/solutions/ex2_accent.dsp).
3. An exponential decay restarted by every beat: 1 on the beat, then
   multiplied by 0.99 at every sample. Solution:
   [`ex3_decay.dsp`](../examples/07/solutions/ex3_decay.dsp).
