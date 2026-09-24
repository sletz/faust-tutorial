// Exercise 1: a constant-intensity panner whose square roots are computed
// once per block. Smoothing after sqrt keeps sqrt out of the sample loop.
import("stdfaust.lib");

p = hslider("pan", 0.5, 0, 1, 0.01);

process = _ <: *(sqrt(1 - p) : si.smoo), *(sqrt(p) : si.smoo);

// Both square roots are block-rate values (fSlow), none is in the loop.
// cpp-expect: float fSlow\d+ = fConst0 \* std::sqrt\(1\.0f - fSlow0\);
// cpp-absent: output\d\[i0\] = .*std::sqrt
// check: --double --in dc -n 88200 --skip 44100 --quiet
// expect: out0: peak=0\.70710678\d*
