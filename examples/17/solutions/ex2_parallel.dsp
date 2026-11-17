// Exercise 2: parallel(P, m, mk), the processes mk(0) ... mk(m-1) applied
// to the same P channels and averaged, and its law: m times the same
// process is that process.
import("stdfaust.lib");

parallel(P, m, mk) = si.bus(P) <: par(k, m, mk(k)) :> par(h, P, /(m));

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

lp = fi.lowpass(2, 1000);

same(k) = lp, lp;                                                       // four times the same stereo filter
different(k) = fi.lowpass(2, 500 * (k + 1)), fi.lowpass(2, 500 * (k + 1));  // four different ones

process = law(parallel(2, 4, same), (lp, lp)),
          law(parallel(2, 4, different), (lp, lp));

// The law holds for the first pair of outputs, not for the second.
// check: --double -n 20000 --in zero --quiet
// expect: out0: peak=0\.0 rms=0\.0 dc=0\.0 finite
// expect: out1: peak=0\.0 rms=0\.0 dc=0\.0 finite
// expect: out2: peak=0\.\d*[1-9]\d* rms=0\.0[1-9]
// expect: out3: peak=0\.\d*[1-9]\d* rms=0\.0[1-9]
