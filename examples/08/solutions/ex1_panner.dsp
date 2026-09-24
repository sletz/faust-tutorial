// Exercise 1: a constant-intensity panner (Tiziano Bole, "Faust Tutorial
// 2", 2008). Intensity goes as the square of the amplitude, so the gains
// are sqrt(1 - c) and sqrt(c): their squares always sum to 1.
import("stdfaust.lib");

c = hslider("pan [style:knob]", 0.5, 0, 1, 0.01) : si.smoo;

process = _ <: *(sqrt(1 - c)), *(sqrt(c));

// In the middle each side gets 1/sqrt(2), and the powers sum to 1 (the
// smoother starts at 0, so look at the second second).
// check: --double --in dc -n 88200 --skip 44100 --quiet
// expect: out0: peak=0\.70710678\d*
// expect: out1: peak=0\.70710678\d*
