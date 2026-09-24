// The phasor: a phase that grows by f/SR per sample and wraps from 1 to 0.
// It is the integrator of chapter 4 with the fractional part in the loop.
import("stdfaust.lib");

phasor(f) = (+(f / ma.SR) : ma.frac) ~ _;

// The library's os.lf_sawpos starts at 0; this one starts one step later.
// A negative frequency runs backwards: ma.frac(x) = x - floor(x) keeps the
// phase in [0, 1).
process = phasor(11025), os.lf_sawpos(11025), phasor(-11025);

// At 44.1 kHz, 11025 Hz is a quarter of the rate: four samples per period.
// check: --double -n 5 --in zero
// expect: ^0,0\.25,0\.0,0\.75$
// expect: ^1,0\.5,0\.25,0\.5$
// expect: ^3,0\.0,0\.75,0\.0$
// expect: ^4,0\.25,0\.0,0\.75$
