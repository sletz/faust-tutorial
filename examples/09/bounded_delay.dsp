// A delay read with a variable amount needs a bound, to size its buffer.
// The compiler takes it from the interval of the signal: a slider's range
// is known, so @ can take it directly. de.delay(n, d) clamps d to [0, n].
import("stdfaust.lib");

d = hslider("delay", 10, 0, 100, 1);

process = _ <: @(d), de.delay(100, d);

// A buffer sized from the slider's maximum, 100, plus the current sample,
// rounded up to a power of two: 128.
// cpp-expect: fVec0\[128\]
// check: --double -n 11 --set delay=10
// expect: ^10,1\.0,1\.0$
