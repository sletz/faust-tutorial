// Additive synthesis: the sum of the first N harmonics with amplitudes 1/k
// approximates a sawtooth. The index sets both frequency and amplitude.
import("stdfaust.lib");

N = 16;
f0 = hslider("freq", 110, 20, 1000, 1);

additive_saw = sum(k, N, os.osc(f0 * (k + 1)) / (k + 1)) * 2 / ma.PI;

process = additive_saw * 0.5;

// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=0\.5\d* 
