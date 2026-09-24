// The state-variable filter of filters.lib, quoted in the idioms document:
// one environment, fi.svf, holds a generic svf(T, F, Q, G) and nine
// one-line filters that call it with a type T.
import("stdfaust.lib");

process = _ <: fi.svf.lp(1000, 0.707), fi.svf.hp(1000, 0.707), fi.svf.bp(1000, 0.707);

// At DC: the lowpass passes, the highpass and the bandpass block.
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=(1\.0|0\.9999)\d*
// expect: out1: peak=(0\.0|\d\.\d+e-1\d) 
// expect: out2: peak=(0\.0|\d\.\d+e-1\d) 
