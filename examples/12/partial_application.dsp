// Partial application: give a function fewer arguments than it takes, and
// the missing ones become the inputs of the result.
import("stdfaust.lib");

db2linear = pow(10, /(20.0));          // Den Haag, 2006: 10^(x/20)
clip(lo, hi, x) = max(lo, min(hi, x));
soft = clip(-0.5, 0.5);                // a block with one input
kilo = *(1e3);                         // units, as in tonestacks.lib

process = db2linear(-20), (2 : soft), (4.7 : kilo);

// check: --double -n 1 --in zero
// expect: ^0,0\.1,0\.5,4700\.0$
