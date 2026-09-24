// A mixer of two stereo sources, each with its own gain.
gainA = hslider("gain A", 0.5, 0, 1, 0.01);
gainB = hslider("gain B", 0.5, 0, 1, 0.01);

process = *(gainA), *(gainA), *(gainB), *(gainB) :> _, _;

// All inputs at 1: each output is gainA + gainB.
// check: --double -n 1 --in dc --set gain_A=0.25 --set gain_B=0.5
// expect: ^0,0\.75,0\.75$
