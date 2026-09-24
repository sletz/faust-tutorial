// The eight-voice mixer of Orlarey, Fober and Letz (SMC 2009), with today's
// library names. Each voice: mute, volume, meter, pan, in its own group,
// numbered by "%v". The two "vol" of the stereo output have the same label
// in the same group, so they are one slider for both channels.
import("stdfaust.lib");

vol      = *(hslider("vol [unit:dB]", 0, -70, 4, 0.1) : ba.db2linear : si.smoo);
mute     = *(1 - checkbox("mute"));
pan      = _ <: *(sqrt(1 - p)), *(sqrt(p)) with { p = hslider("pan", 0.5, 0, 1, 0.01) : si.smoo; };
envelope = abs : min(0.99) : max ~ -(1.0 / ma.SR);
vumeter  = _ <: attach(_, envelope : vbargraph("level", 0, 1));

voice(v) = vgroup("voice %v", mute : hgroup("", vol : vumeter) : pan);
stereo   = hgroup("stereo out", vol, vol);

process  = hgroup("mixer", par(i, 8, voice(i)) :> stereo);

// process is one group, "mixer", which becomes the root of the paths.
// check: --list-params
// expect: ^/mixer/voice_0/mute
// expect: ^/mixer/voice_7/pan
// expect: ^/mixer/stereo_out/vol
// A pan of 0 sends voice 3 to the left only, once the smoothing has
// settled (the second second of a constant input on every voice).
// check: --double -n 88200 --skip 44100 --in dc --quiet --set voice_3/pan=0 --set voice_0/mute=1 --set voice_1/mute=1 --set voice_2/mute=1 --set voice_4/mute=1 --set voice_5/mute=1 --set voice_6/mute=1 --set voice_7/mute=1
// expect: out0: peak=0\.99999999\d* 
// expect: out1: peak=0\.0 
// expect: bargraph /mixer/voice_3//level=0\.99
