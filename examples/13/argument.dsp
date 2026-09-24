// An environment passed as an argument: a preset. play reads the members
// of whatever environment it receives.
// faust-rs: no (it does not resolve cfg.freq yet; reported)
import("stdfaust.lib");

play(cfg) = os.osc(cfg.freq) * cfg.gain;

low  = environment { freq = 220; gain = 0.5; };
high = environment { freq = 880; gain = 0.25; };

process = play(low), play(high);

// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(0\.5f \*
// cpp-expect: output1\[i0\] = static_cast<FAUSTFLOAT>\(0\.25f \*
