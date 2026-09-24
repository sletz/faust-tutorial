// An environment computed by a function is a record: the coefficients of a
// second-order lowpass (Robert Bristow-Johnson's cookbook), computed once
// and read by name.
import("stdfaust.lib");

rbj_lowpass(f, q) = environment {
    w = 2 * ma.PI * f / ma.SR;
    alpha = sin(w) / (2 * q);
    a0 = 1 + alpha;
    b0 = (1 - cos(w)) / 2 / a0;
    b1 = (1 - cos(w)) / a0;
    b2 = b0;
    a1 = -2 * cos(w) / a0;
    a2 = (1 - alpha) / a0;
};

lowpass(f, q) = fi.tf2(c.b0, c.b1, c.b2, c.a1, c.a2) with { c = rbj_lowpass(f, q); };

process = lowpass(1000, 0.707);

// A lowpass lets a constant through with a gain of 1.
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=1\.0\d* rms=1\.0
