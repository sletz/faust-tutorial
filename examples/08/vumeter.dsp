// A level meter from the Faust presentation at Den Haag (2006): a peak
// envelope that falls linearly by 1 per second, shown by a bargraph kept
// alive by attach. attach(x, y) outputs x and computes y for its side
// effect, the display.
import("stdfaust.lib");

envelope = abs : min(0.99) : max ~ -(1.0 / ma.SR);
vumeter = _ <: attach(_, envelope : vbargraph("meter", 0, 1));

process = *(0.5) : vumeter;

// A sine of amplitude 0.5 shows just under 0.5 on the meter (the envelope
// falls a little between two peaks).
// check: --double --in sine:440 -n 44100 --quiet
// expect: bargraph /vumeter/meter=0\.49\d*
