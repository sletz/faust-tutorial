// A table filled by a generator: the signal sinwaveform(N) is computed for
// the first N samples, once, when the program is initialised; then rdtable
// reads it. This is how os.osc works.
import("stdfaust.lib");

N = 64;
sinwaveform(n) = sin(2 * ma.PI * float(ba.time) / n);
osc_table(f) = rdtable(N, sinwaveform(N), int(os.lf_sawpos(f) * N));

process = osc_table(440);

// The table is filled in a separate class at initialisation.
// cpp-expect: class mydspSIG0
// cpp-expect: void fillmydspSIG0\(int count, float\* table\)
// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=1\.0 
