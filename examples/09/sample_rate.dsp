// The sampling rate is known when the program is initialised, not when it
// is compiled: expressions of ma.SR go into instanceConstants, computed
// once at initialisation.
import("stdfaust.lib");

process = os.lf_sawpos(1000);

// cpp-expect: void instanceConstants\(int sample_rate\)
// cpp-expect: fConst0 = 1e\+03f / std::min<float>\(1\.92e\+05f, std::max<float>\(1\.0f, static_cast<float>\(fSampleRate\)\)\);
// check: --double --sr 4000 -n 5 --in zero
// expect: ^4,0\.0$
