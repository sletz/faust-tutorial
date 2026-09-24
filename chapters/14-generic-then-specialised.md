# 14. Generic, then specialised

## The idea

Chapter 9 showed that the compiler only generates the code a program
actually uses, and computes in advance everything that is constant. The
idioms document draws the design lesson: write **one generic algorithm**,
with all its parameters and all its outputs, and derive the specific
versions from it by

- **cutting outputs** that a version does not need;
- **fixing parameters** to constants;
- **partial application**, which fixes the first parameters (chapter 12).

Each specialised version costs no more than a version written by hand,
and the algorithm exists once.

## Cutting outputs

A state-variable filter computes its lowpass, bandpass and highpass outputs
from the same state. A generic version outputs all three
([`generic_svf.dsp`](../examples/14/generic_svf.dsp)):

```faust
svf(f, q) = tick ~ (_, _) : !, !, _, _, _
with {
    g = tan(ma.PI * f / ma.SR);
    k = 1 / q;
    tick(ic1, ic2, v0) = 2 * v1 - ic1, 2 * v2 - ic2, v2, v1, v0 - k * v1 - v2
    with {
        v1 = (ic1 + g * (v0 - ic2)) / (1 + g * (g + k));
        v2 = ic2 + g * v1;
    };
};

svf_lp(f, q) = svf(f, q) : _, !, !;
svf_bp(f, q) = svf(f, q) : !, _, !;
svf_hp(f, q) = svf(f, q) : !, !, _;
```

The `tick` of chapter 5 carries two state variables and outputs five
values; the first cut removes the state from the outputs, and each
specialisation cuts two more. The lowpass matches the library's
`fi.svf.lp` to within rounding.

The idioms document points to Eric Tarr's filters in vaeffects.lib, built
exactly this way. `ve.oberheim(normFreq, Q)` has four outputs, band-stop,
band-pass, highpass and lowpass, and each specialisation is one line
([`cutting_outputs.dsp`](../examples/14/cutting_outputs.dsp)):

```faust
oberheimBSF(normFreq,Q) = oberheim(normFreq,Q):_,!,!,!;
oberheimBPF(normFreq,Q) = oberheim(normFreq,Q):!,_,!,!;
oberheimHPF(normFreq,Q) = oberheim(normFreq,Q):!,!,_,!;
oberheimLPF(normFreq,Q) = oberheim(normFreq,Q):!,!,!,_;
```

The cut is not a runtime operation: the compiler removes whatever only fed
the cut outputs. Counting the statements of the generated sample loop:

| program | statements in the sample loop |
|---|---|
| `ve.oberheim(0.5, 1)`, four outputs | 20 |
| `ve.oberheimLPF(0.5, 1)` | 11 |
| `ve.oberheimHPF(0.5, 1)` | 12 |

The same holds for `ve.sallenKey2ndOrder` and `ve.sallenKeyOnePole` in the
same library.

## Fixing parameters

A parameter given a constant is computed by the compiler or at
initialisation; given a widget, at every block. The same filter, both ways
([`constant_parameter.dsp`](../examples/14/constant_parameter.dsp),
[`slider_parameter.dsp`](../examples/14/slider_parameter.dsp)):

```faust
process = fi.resonlp(1000, 2, 1);
```

```cpp
fConst0 = std::tan(3141.5928f / std::min<float>(1.92e+05f, std::max<float>(1.0f, static_cast<float>(fSampleRate))));
```

```faust
process = fi.resonlp(hslider("freq", 1000, 100, 5000, 1), 2, 1);
```

```cpp
float fSlow0 = std::tan(fConst0 * static_cast<float>(fHslider0));
```

With a constant frequency, the `tan` and the coefficients are computed
once, when the program starts (`fConst`). With a slider, they are
recomputed at every block (`fSlow`). A generic filter used with constant
parameters is therefore as cheap as a filter with hard-coded coefficients.

The idioms document's advice follows: put the parameters that are most
likely to be fixed **first**, so that partial application can fix them,
and the signal last (chapter 12). Then `fi.resonlp(1000, 2)` is a ready
filter, and `resonant(f) = fi.resonlp(f, 5, 0.5)` (exercise 3) a version
with one control left.

## Choosing among variants

When the variants differ in structure, not in coefficients, the choice is
made by pattern matching on a constant, or by a constant condition, which
the compiler resolves (chapter 9). `fi.svf` in filters.lib does the first:
its generic `svf(T, F, Q, G)` selects its coefficients with `case` on the
type `T`, and nine one-line filters fix `T` (chapter 13).

physmodels.lib's formant voice does the second. The generic model takes the
source signal, the filter bank *function* and a flag:

```faust
SFFormantModel(voiceType,vowel,exType,freq,gain,source,filterbank,isFof) =
    excitation : resonance
with {
    breath = no.noise;
    excitation = ba.if(isFof,source,source*(1-exType) + breath*exType :
            *(gain));
    resonance = filterbank(voiceType,vowel,freq) <: ba.if(isFof,*(gain),_);
};
```

and each variant fixes them:

```faust
SFFormantModelFofCycle(voiceType,vowel,freq,gain) =
SFFormantModel(voiceType,vowel,0,freq,gain,os.lf_imptrain(freq),
formantFilterbankFofCycle,1);

SFFormantModelBP(voiceType,vowel,exType,freq,gain) =
SFFormantModel(voiceType,vowel,exType,freq,gain,os.sawtooth(freq),
formantFilterbankBP,0);
```

`isFof` is a constant in every variant, so `ba.if(isFof, ...)` is resolved
by the compiler and only one branch is compiled. On top of each variant,
physmodels.lib adds a `_ui` version with sliders and a `_ui_MIDI` version
with MIDI controls: the same generic core serves six user-facing
functions. Chapter 15 generalises this into a way of writing libraries.

## Pitfalls

- **A cut is free only if the output is really unused.** An output used
  by a bargraph or by `attach` is kept.
- **A widget in a structural parameter** (a type, an order, a count) is
  not a specialisation: it makes the compiler loop forever or computes all
  variants (chapter 9).
- **Order the parameters** so that the fixed ones come first.

## Exercises

1. A notch filter from the generic state-variable filter, by *combining*
   two of its outputs (lowpass plus highpass). Check that it removes a sine
   at its frequency. Solution: [`ex1_notch.dsp`](../examples/14/solutions/ex1_notch.dsp).
2. A multimode filter whose mode is chosen at compile time: an environment
   with a `MODE` constant, a `pick(MODE)` defined by patterns, and
   substitution to get the highpass. Solution:
   [`ex2_mode_switch.dsp`](../examples/14/solutions/ex2_mode_switch.dsp).
3. A resonant lowpass with Q and gain fixed by partial application, and its
   frequency as the only control; find the fixed part in `fConst`.
   Solution: [`ex3_fixed_q.dsp`](../examples/14/solutions/ex3_fixed_q.dsp).
