// A phase offset: shift the phase, then wrap it again. A sine shifted by a
// quarter of a period is a cosine.
import("stdfaust.lib");

p = os.lf_sawpos(440);
shifted = ma.frac(p + 0.25);

process = sin(2 * ma.PI * shifted) - cos(2 * ma.PI * p);

// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=\d\.\d+e-1[2-6] 
