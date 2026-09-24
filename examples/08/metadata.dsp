// Metadata in square brackets, inside a label, tell the interface how to
// show a widget and how to map it. They are not part of the path.
import("stdfaust.lib");

freq = hslider("[0] freq [unit:Hz] [scale:log] [tooltip:oscillator frequency]", 440, 20, 20000, 1);
gain = hslider("[1] gain [unit:dB] [style:knob] [midi:ctrl 7]", -12, -60, 0, 0.1) : ba.db2linear;
wave = hslider("[2] wave [style:menu{'sine':0;'saw':1;'square':2}]", 0, 0, 2, 1);
pan  = hslider("[3] pan [osc:/1/fader1 0 1]", 0.5, 0, 1, 0.01);

osc = os.osc(freq), os.sawtooth(freq), os.square(freq) : ba.selectn(3, wave);

process = osc * gain <: *(1 - pan), *(pan);

// check: --list-params
// expect: /metadata/freq +slider +440\.0 +20\.0 +20000\.0
// expect: /metadata/gain
// expect: /metadata/wave
// expect: /metadata/pan
// check: --double --in zero -n 44100 --quiet --set gain=-6 --set pan=0
// expect: out0: peak=0\.50\d*
// expect: out1: peak=0\.0 
