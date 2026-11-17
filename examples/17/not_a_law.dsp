// The control of law.dsp: a saturation does not do the same at any level.
// The same check must fail here, or it proves nothing in law.dsp. This
// failure is what the drive of a distortion is made of.
import("stdfaust.lib");

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

inDomain(T, fx, Tinv) = T : fx : Tinv;
atLevel(g, fx) = inDomain(*(g), fx, /(g));

process = law(atLevel(4, ma.tanh), ma.tanh);

// check-fails: --double -n 20000 --in zero --quiet --fail-above 1e-12
// The difference is as large as the signals.
// check: --double -n 20000 --in zero --quiet
// expect: out0: peak=0\.51
