// Exercise 1: N sawtooth oscillators spread around a frequency, summed and
// normalised. N is a compile-time constant; the detune is a slider.
import("stdfaust.lib");

N = 7;
freq   = hslider("freq", 110, 20, 1000, 1);
detune = hslider("detune", 0.01, 0, 0.05, 0.001);

supersaw(n, f, d) = sum(i, n, os.sawtooth(f * (1 + d * (i - (n - 1) / 2)))) / n;

process = supersaw(N, freq, detune);

// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=0\.\d+ .*finite=yes
