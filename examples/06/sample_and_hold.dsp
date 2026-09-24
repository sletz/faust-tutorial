// Sample and hold: select2(t) ~ _ chooses between the previous output (t = 0)
// and the input (t = 1). With a one-sample trigger it samples, with a gate it
// tracks the input while the gate is up. It is ba.sAndH.
import("stdfaust.lib");

hold(t) = select2(t) ~ _;

take = button("take");

process = os.lf_sawpos(1000) <: hold(take), ba.sAndH(take);

// check: --double -n 20 --in zero --at 5 take=1 --at 6 take=0
// expect: ^5,(0\.1133\d*),(0\.1133\d*)$
// expect: ^19,0\.1133\d*,0\.1133\d*$
