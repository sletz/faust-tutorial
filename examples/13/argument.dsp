// An environment passed as an argument: a preset. play reads the members
// of whatever environment it receives.
import("stdfaust.lib");

play(cfg) = os.osc(cfg.freq) * cfg.gain;

low  = environment { freq = 220; gain = 0.5; };
high = environment { freq = 880; gain = 0.25; };

process = play(low), play(high);

// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=0\.4999
// expect: out1: peak=0\.2499

// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(0\.5f \*
// cpp-expect: output1\[i0\] = static_cast<FAUSTFLOAT>\(0\.25f \*
