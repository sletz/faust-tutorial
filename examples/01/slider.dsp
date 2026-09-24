// A slider: label, initial value, minimum, maximum, step.
import("stdfaust.lib");

gain = hslider("gain", 0.1, 0, 1, 0.01);
freq = hslider("freq", 440, 50, 2000, 1);

process = os.osc(freq) * gain;

// check: --list-params
// expect: /slider/gain
// check: --double --in zero -n 44100 --quiet --set gain=0.5
// expect: out0: peak=0\.49999
