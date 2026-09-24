// Exercise 2: a feedback echo whose time goes up to one second. The maximum
// delay must be known at compile time: ba.sec2samp(1) is ma.SR, which the
// libraries clamp to [1, 192000], so the compiler can size the buffer
// (262144 samples, the next power of two).
import("stdfaust.lib");

t = hslider("time", 0.25, 0.01, 1, 0.01);

echo = + ~ (de.delay(ba.sec2samp(1), ba.sec2samp(t) - 1) : *(0.5));

process = echo;

// At 48 kHz and 0.25 s, the first echo comes 12000 samples later, at half
// the level.
// cpp-expect: float fRec0\[262144\];
// check: --double --sr 48000 -n 24001
// expect: ^11999,0\.0$
// expect: ^12000,0\.5$
// expect: ^24000,0\.25$
