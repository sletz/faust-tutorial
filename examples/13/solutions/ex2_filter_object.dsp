// Exercise 2: an environment with "methods": the cookbook coefficients and
// the filters built from them, read as rbj(f, q).lpf and rbj(f, q).hpf.
import("stdfaust.lib");

rbj(f, q) = environment {
    w = 2 * ma.PI * f / ma.SR;
    alpha = sin(w) / (2 * q);
    a0 = 1 + alpha;
    a1 = -2 * cos(w) / a0;
    a2 = (1 - alpha) / a0;
    lpf = fi.tf2((1 - cos(w)) / 2 / a0, (1 - cos(w)) / a0, (1 - cos(w)) / 2 / a0, a1, a2);
    // not -(1 + cos(w)): that is the partial application of -, a block
    // computing input - (1 + cos(w)), not a negation
    hpf = fi.tf2((1 + cos(w)) / 2 / a0, 0 - (1 + cos(w)) / a0, (1 + cos(w)) / 2 / a0, a1, a2);
};

process = _ <: rbj(1000, 0.707).lpf, rbj(1000, 0.707).hpf;

// At DC the lowpass passes and the highpass blocks.
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=(1\.0|0\.9999)\d*
// expect: out1: peak=(0\.0|\d\.\d+e-1\d) 
