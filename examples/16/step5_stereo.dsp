// Step 5: the playable reverb. Stereo by a spread of the tunings on the
// right channel, a dry/wet mix around the reverb (chapter 12), an
// interface with groups, metadata and smoothing (chapter 8), and presets
// by substitution (chapter 13).
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
      :> seq(i, 4, allpass(1024, allpass_tuning(i) + spread, -fb2));

stereo_freeverb(fb1, fb2, damp, spread) = + <: freeverb(fb1, fb2, damp, 0), freeverb(fb1, fb2, damp, spread);

dry_wet(mix, fx) = _, _ <: (_, _), fx : ro.interleave(2, 2) : si.interpolate(mix), si.interpolate(mix);

reverb = environment {
    SIZE = 0.5;                               // a preset constant, 0..1
    ui(x) = hgroup("reverb", x);
    size = ui(hslider("[0] size", SIZE, 0, 1, 0.01)) : si.smoo;
    damp = ui(hslider("[1] damping", 0.5, 0, 1, 0.01)) : si.smoo;
    mix  = ui(hslider("[2] wet [style:knob]", 0.3, 0, 1, 0.01)) : si.smoo;
    fb1  = 0.7 + 0.28 * size;                 // Freeverb's room size scaling
    // the parentheses matter: a comma inside an argument list separates arguments
    play = dry_wet(mix, (stereo_freeverb(fb1, 0.5, damp * 0.4, 23) : *(0.1), *(0.1)));
};

process = reverb.play;

// Two inputs, two outputs, three controls; with wet at 0 the input passes.
// check: --list-params
// expect: ^/reverb/size
// expect: ^/reverb/damping
// expect: ^/reverb/wet
// check: --double -n 88200 --skip 44100 --in dc --quiet --set wet=0
// expect: out0: peak=1\.0 rms=1\.0
// check: --double -n 44100 --in impulse:0 --quiet --set wet=1
// expect: out0: peak=0\.\d+ .*finite=yes
// expect: out1: peak=0\.\d+ .*finite=yes
