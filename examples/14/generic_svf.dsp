// A generic state-variable filter (the topology-preserving form used by
// filters.lib's fi.svf): one state update, three outputs, lowpass,
// bandpass and highpass. The specialisations keep one output each; the
// compiler removes what they cut.
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

svf_lp(f, q) = svf(f, q) : _, !, !;
svf_bp(f, q) = svf(f, q) : !, _, !;
svf_hp(f, q) = svf(f, q) : !, !, _;

process = _ <: svf_lp(1000, 0.707), svf_bp(1000, 0.707), svf_hp(1000, 0.707),
               (svf_lp(1000, 0.707) - fi.svf.lp(1000, 0.707));

// At DC the lowpass passes, the others block; and the lowpass is the
// library's to within rounding.
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=(1\.0|0\.9999)\d*
// expect: out1: peak=(0\.0|\d\.\d+e-1\d) 
// expect: out2: peak=(0\.0|\d\.\d+e-1\d) 
// check: --double --in white:1 -n 44100 --quiet
// expect: out3: peak=(0\.0|\d\.\d+e-1\d) 
