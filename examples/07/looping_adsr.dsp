// The looping ADSR of the idioms document (Dario Sanfilippo, answering a
// user on the Faust mailing list): a phasor whose period is the length of
// the whole envelope opens the gate for the attack, decay and sustain, then
// closes it for the release; at the next period the envelope starts again.
import("stdfaust.lib");

A = .01;
D = 1.1;
S = .1;
R = .01;
L = A + D + S + R;
ratio = (A + D + S) / L;

process = os.phasor(1, 1/L) < ratio : en.adsr(A, D, S, R);

// At 1 kHz a cycle is 1220 samples: the attack peaks at sample 9, the
// sustain holds 0.1, the release reaches 0 at 1220, and the attack starts
// again.
// check: --double --sr 1000 --in zero -n 1300
// expect: ^9,1\.0$
// expect: ^1200,0\.1$
// expect: ^1220,0\.0$
// expect: ^1222,0\.2$
