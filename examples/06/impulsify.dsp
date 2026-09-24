// impulsify from faust_tutorial.pdf, quoted in the idioms document, and
// ba.impulsify in basics.lib: the positive part of the first difference.
// It marks each rise of a signal with a spike as high as the rise.
// (The library's documentation says it outputs "the value of the current
// sample"; it outputs the size of the step.)
import("stdfaust.lib");

impulsify = _ <: _, mem : - <: >(0) * _;

steps = 0.3 * (ba.time >= 1) + 0.2 * (ba.time >= 3) - 0.4 * (ba.time >= 5);

process = steps <: _, impulsify, ba.impulsify;

// The signal climbs to 0.3, then to 0.5, then falls to 0.1: two spikes of
// 0.3 and 0.2, nothing on the fall.
// check: --double -n 6 --in zero
// expect: ^1,0\.3,0\.3,0\.3$
// expect: ^3,0\.5,0\.2,0\.2$
// expect: ^5,0\.0999\d*,-0\.0,-0\.0$
