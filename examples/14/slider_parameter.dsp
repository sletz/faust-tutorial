// The same filter with its frequency on a slider: the tan and the
// coefficients move to the block rate.
import("stdfaust.lib");

process = fi.resonlp(hslider("freq", 1000, 100, 5000, 1), 2, 1);

// cpp-expect: float fSlow0 = std::tan\(fConst0 \* static_cast<float>\(fHslider0\)\);
// check: --double --in dc -n 44100 --skip 40000 --quiet
// expect: out0: peak=(1\.0|0\.9999)\d*
