// Exercises 1 to 3: the new functions of tutorial_v2.lib, a bandpass with
// its documentation and test, a renamed filter whose old name is a
// deprecated alias, and a _ui layer.
import("stdfaust.lib");
tu = library("tutorial_v2.lib");

process = _ <: tu.bp(1000, 0.707), tu.band_reject(1000, 0.707) - tu.notch_v1(1000, 0.707), tu.lp_ui;

// The alias is the same filter; the bandpass blocks DC; the _ui layer adds
// two controls.
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=(0\.0|\d\.\d+e-1\d) 
// expect: out1: peak=0\.0 
// check: --list-params
// expect: /ex_use_v2/cutoff
// expect: /ex_use_v2/Q
