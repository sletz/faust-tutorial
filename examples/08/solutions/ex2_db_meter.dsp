// Exercise 2: a peak meter in decibels next to the signal, from -60 to 0 dB.
import("stdfaust.lib");

envelope = abs : min(0.99) : max ~ -(1.0 / ma.SR);
db_meter = _ <: attach(_, envelope : ba.linear2db : max(-60) : hbargraph("level [unit:dB]", -60, 0));

process = *(0.5) : db_meter;

// A sine of amplitude 0.5 reads about -6 dB.
// check: --double --in sine:440 -n 44100 --quiet
// expect: bargraph /ex2_db_meter/level=-6\.0\d*
