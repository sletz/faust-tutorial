// Pattern matching chooses among rules at compile time: only the rule that
// matches the constant argument is compiled. The rules may even have
// different numbers of outputs, which ba.if cannot do.
import("stdfaust.lib");

wave(0) = os.osc(440);
wave(1) = os.sawtooth(440);
wave(2) = os.osc(440), os.sawtooth(440);

mode = 1;

process = wave(mode);

// cpp-absent: SIG0
// check: --double --in zero -n 100 --quiet
// expect: out0: peak=0\.9\d*
