// The laws of the mid/side change of domain, checked with law (law.dsp).
import("stdfaust.lib");

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

inDomain(T, fx, Tinv) = T : fx : Tinv;
toMS = _, _ <: +, - : /(2), /(2);
fromMS = _, _ <: +, -;
inMS(fx) = inDomain(toMS, fx, fromMS);

lp = fi.lowpass(2, 1000);

process = law(inMS(si.bus(2)), si.bus(2)),      // there and back is the identity
          law(inMS((lp, lp)), (lp, lp));        // the same filter on both signals: the domain does not matter

// Four differences; a sample above 1e-12 would fail the check.
// check: --double -n 20000 --in zero --quiet --fail-above 1e-12
// expect: out3: peak=
