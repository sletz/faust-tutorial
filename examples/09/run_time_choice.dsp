// The same choice on a slider is made at every sample, and both branches are
// computed: the sine table is back in the generated code.
import("stdfaust.lib");

mode = hslider("mode", 1, 0, 1, 1);

process = ba.if(mode == 0, os.osc(440), os.sawtooth(440));

// cpp-expect: SIG0
// check: --double --in zero -n 100 --quiet --set mode=0
// expect: out0: peak=0\.9999\d* rms=0\.70\d*
