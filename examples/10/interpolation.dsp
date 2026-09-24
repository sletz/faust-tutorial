// Reading a small table at the nearest entry is coarse; interpolating
// between two neighbours is much closer. Error of a 64-entry sine table
// against sin(), with and without linear interpolation.
import("stdfaust.lib");

N = 64;
sinwaveform(n) = sin(2 * ma.PI * float(ba.time) / n);
table(k) = rdtable(N + 1, sinwaveform(N), k);     // one extra entry for k + 1

phase = os.lf_sawpos(440);
pos = phase * N;
k = int(pos);
d = pos - k;

nearest = table(k);
linear  = table(k) + d * (table(k + 1) - table(k));
exact   = sin(2 * ma.PI * phase);

process = nearest - exact, linear - exact;

// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=0\.09\d*
// expect: out1: peak=0\.001\d*
