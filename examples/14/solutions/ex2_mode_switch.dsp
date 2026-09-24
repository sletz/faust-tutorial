// Exercise 2: one multimode filter, its mode chosen at compile time by
// substitution. pick(MODE) keeps one output by pattern matching.
import("stdfaust.lib");

multimode = environment {
    MODE = 0;                         // 0 lowpass, 1 bandpass, 2 highpass
    filter(f, q) = fi.svf.lp(f, q), fi.svf.bp(f, q), fi.svf.hp(f, q) : pick(MODE)
    with {
        pick(0) = _, !, !;
        pick(1) = !, _, !;
        pick(2) = !, !, _;
    };
};

process = _ <: multimode.filter(1000, 0.707), multimode[MODE = 2;].filter(1000, 0.707);

// At DC the lowpass passes and the highpass blocks.
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=(1\.0|0\.9999)\d*
// expect: out1: peak=(0\.0|\d\.\d+e-1\d) 
