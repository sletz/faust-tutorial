// Two expressions separated by a comma: two outputs.
import("stdfaust.lib");

process = os.osc(440) * 0.1, os.osc(660) * 0.1;

// check: --double --in zero -n 1000 --quiet
// expect: out0: peak=
// expect: out1: peak=
