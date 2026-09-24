// Exercise 1: a notch filter made from the generic state-variable filter by
// combining two of its outputs: lowpass + highpass.
import("stdfaust.lib");

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

svf_notch(f, q) = svf(f, q) : _, !, _ :> _;

process = svf_notch(1000, 0.707);

// A sine at the notch frequency is almost removed; one far below passes.
// check: --double --in sine:1000 -n 44100 --skip 22050 --quiet
// expect: out0: peak=\d\.\d+e-(0[4-9]|1\d) 
// check: --double --in sine:50 -n 44100 --skip 22050 --quiet
// expect: out0: peak=0\.99\d*
