// The size of a table is fixed at compile time. The sampling rate is only
// known at initialisation, so it cannot size a table.
// expect-error
// expect: (?i)constant
import("stdfaust.lib");
process = rdtable(int(ma.SR), os.sinwaveform(1024), 0);
