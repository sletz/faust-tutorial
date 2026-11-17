// A law says that two circuits are equal. law(a, b) is the circuit that
// checks it: it feeds the same noises to a and to b and outputs the
// differences, one per output, which must stay at zero or at the rounding
// error. Here, the laws of the smallest change of domain: a signal g times
// as loud, and back.
import("stdfaust.lib");

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

inDomain(T, fx, Tinv) = T : fx : Tinv;

// fx applied to the signal g times as loud
atLevel(g, fx) = inDomain(*(g), fx, /(g));

lp = fi.lowpass(2, 1000);

process = law(atLevel(4, _), _),        // there and back is the identity
          law(atLevel(4, lp), lp);      // a filter does the same at any level

// Two differences; a sample above 1e-12 would fail the check.
// check: --double -n 20000 --in zero --quiet --fail-above 1e-12
// expect: out1: peak=
