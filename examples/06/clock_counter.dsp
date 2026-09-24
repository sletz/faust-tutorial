// The MIDI clock example of the idioms document: count the changes of a
// clock signal during the last second. A square wave at 12 Hz changes 24
// times per second, the rate of a MIDI clock at 60 beats per minute.
import("stdfaust.lib");

front(x) = (x - x') != 0.0;
per_second(x) = (x - x@ma.SR) : + ~ _;      // moving sum over one second

process = os.lf_squarewave(12) : front : per_second;

// check: --double --in zero -n 50000 --skip 45000 --quiet
// expect: out0: peak=24\.0 rms=24\.0
