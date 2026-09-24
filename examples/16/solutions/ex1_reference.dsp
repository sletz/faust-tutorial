// Reference for exercise 1: the reverb first, then the 10 ms delay.
import("stdfaust.lib");
process = re.mono_freeverb(0.84, 0.5, 0.2, 0) : @(441);
