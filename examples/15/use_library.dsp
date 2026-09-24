// A program that uses tutorial.lib through its prefix, like stdfaust.lib
// does for the standard libraries.
import("stdfaust.lib");
tu = library("tutorial.lib");

process = tu.svf_demo;

// check: --list-params
// expect: ^/tutorial_svf/mode
// expect: ^/tutorial_svf/cutoff
// check: --double --in dc -n 44100 --skip 40000 --quiet --set mode=0
// expect: out0: peak=(1\.0|0\.9999)\d*
// check: --double --in dc -n 44100 --skip 40000 --quiet --set mode=1
// expect: out0: peak=(0\.0|\d\.\d+e-1\d) 
