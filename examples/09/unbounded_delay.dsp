// A delay read with a counter has no known bound: the compiler cannot size
// the buffer and refuses the program.
// expect-error
// expect: (overflow|negative|interval)
import("stdfaust.lib");
process = _ <: @(ba.time);
