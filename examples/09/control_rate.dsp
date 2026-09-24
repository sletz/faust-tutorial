// An expression of sliders only is computed once per block, outside the
// sample loop: here the conversion from decibels (fSlow0), then one
// multiplication per sample.
import("stdfaust.lib");

process = *(hslider("gain", 0, -60, 0, 0.1) : ba.db2linear);

// cpp-expect: float fSlow0 = std::pow\(1e\+01f, 0\.05f \* static_cast<float>\(fHslider0\)\);
// cpp-expect: output0\[i0\] = static_cast<FAUSTFLOAT>\(fSlow0 \* static_cast<float>\(input0\[i0\]\)\);
// check: --double -n 1 --set gain=-20
// expect: ^0,0\.1$
