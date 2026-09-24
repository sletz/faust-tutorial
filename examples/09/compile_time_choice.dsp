// A choice on a constant is made by the compiler: only the chosen branch is
// compiled. With mode = 1 the sine oscillator, and its table, are gone.
import("stdfaust.lib");

mode = 1;

process = ba.if(mode == 0, os.osc(440), os.sawtooth(440));

// cpp-absent: SIG0
// check: --double --in zero -n 100 --quiet
// expect: out0: peak=0\.9\d*
