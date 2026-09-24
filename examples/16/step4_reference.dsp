// The library's Freeverb, to compare with step4_freeverb.dsp.
import("stdfaust.lib");
process = re.mono_freeverb(0.84, 0.5, 0.2, 0);
