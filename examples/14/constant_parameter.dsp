// Fixing a parameter to a constant specialises the code: the coefficients
// of fi.resonlp at 1000 Hz are computed once, at initialisation (fConst),
// where a slider would recompute them at every block (fSlow).
import("stdfaust.lib");

process = fi.resonlp(1000, 2, 1);

// cpp-expect: fConst0 = std::tan\(3141\.5928f /
// cpp-absent: fSlow
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=(1\.0|0\.9999)\d*
