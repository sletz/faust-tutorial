// Exercise 2: a feedback loop around any block. With a delay it is an
// echo, with a lowpass filter a resonance.
import("stdfaust.lib");

feedback(g, fx) = + ~ (fx : *(g));

process = feedback(0.5, @(4)), feedback(0.9, fi.lowpass(1, 1000));

// The echo: @(4) in the loop, plus the sample of ~, comes back every 5.
// check: --double -n 11
// expect: ^5,0\.5,
// expect: ^10,0\.25,
