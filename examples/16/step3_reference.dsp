// The library's allpass, to compare with step3_allpass.dsp.
import("stdfaust.lib");
process = fi.allpass_comb(1024, 556, -0.5);
