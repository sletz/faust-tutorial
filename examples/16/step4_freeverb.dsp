// Step 4: Freeverb for one channel ("Jezar at Dreampoint"), as in
// reverbs.lib: eight lowpass-feedback combs in parallel, then four
// allpasses in series. The tunings are defined by cases (chapter 11) and
// scaled to the sampling rate (chapter 9).
import("stdfaust.lib");

lbcf(dt, fb, damp) = (+ : @(max(0, dt - 1))) ~ (*(1 - damp) : (+ ~ *(damp)) : *(fb)) : mem;
allpass(maxdel, N, aN) = (+ <: de.delay(maxdel, N - 1), *(aN)) ~ *(-aN) : mem, _ : +;

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

process = freeverb(0.84, 0.5, 0.2, 0);

// Sample for sample the library's re.mono_freeverb.
// check: --double -n 44100 --in white:1 --quiet --compare step4_reference.dsp
// expect: out0: identical
// At 96 kHz too: the allpass buffers hold the longest tuning up to 192 kHz.
// check: --double --sr 96000 -n 44100 --in white:1 --quiet --compare step4_reference.dsp
// expect: out0: identical
