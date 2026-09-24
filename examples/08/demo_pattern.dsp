// The pattern of demos.lib: a library function, and around it an interface
// defined in a with block, with a group function for the path and smoothing
// on every control.
import("stdfaust.lib");

resonant_lowpass_demo = fi.resonlp(freq, q, gain)
with {
    group(x) = hgroup("resonant lowpass", x);
    freq = group(hslider("[0] freq [unit:Hz] [scale:log]", 1000, 50, 10000, 1)) : si.smoo;
    q    = group(hslider("[1] Q [style:knob]", 2, 0.5, 20, 0.01)) : si.smoo;
    gain = group(hslider("[2] gain", 0.5, 0, 1, 0.01)) : si.smoo;
};

process = resonant_lowpass_demo;

// check: --list-params
// expect: ^/resonant_lowpass/freq
// expect: ^/resonant_lowpass/Q
// check: --double --in white:1 -n 44100 --quiet
// expect: finite=yes
