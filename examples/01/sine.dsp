// A 440 Hz sine wave, scaled down so as not to clip.
import("stdfaust.lib");

process = os.osc(440) * 0.1;

// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=0\.09999
// expect: finite=yes
