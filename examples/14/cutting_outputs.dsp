// Eric Tarr's Oberheim filter in vaeffects.lib: ve.oberheim computes four
// outputs (band-stop, band-pass, highpass, lowpass); ve.oberheimLPF is
// ve.oberheim(normFreq, Q) : !,!,!,_ and compiles to about half the code.
import("stdfaust.lib");

process = _ <: ve.oberheimLPF(0.5, 1), (ve.oberheim(0.5, 1) : !, !, !, _);

// Identical: the specialisation is only a cut.
// check: --double --in white:1 -n 10000 --quiet
// expect: out0: peak=
// check: --double -n 3
// expect: ^1,(-?[0-9.e-]+),\1$
// expect: ^2,(-?[0-9.e-]+),\1$
