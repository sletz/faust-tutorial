// The control of ms_laws.dsp: a filter on the mid signal alone is not a
// filter on the left signal alone. The same check must fail here, or it
// proves nothing in ms_laws.dsp.
import("stdfaust.lib");

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

inDomain(T, fx, Tinv) = T : fx : Tinv;
toMS = _, _ <: +, - : /(2), /(2);
fromMS = _, _ <: +, -;
inMS(fx) = inDomain(toMS, fx, fromMS);

lp = fi.lowpass(2, 1000);

process = law(inMS((lp, _)), (lp, _));

// check-fails: --double -n 20000 --in zero --quiet --fail-above 1e-12
// The difference is as large as the signals.
// check: --double -n 20000 --in zero --quiet
// expect: out0: peak=1\.16
// expect: out1: peak=1\.13
