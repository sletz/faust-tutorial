// Substitution on a library: db[DEBUG = 0;] is debug.lib with its DEBUG
// constant set to 0, which compiles every probe away; os[SAFE = 1;] selects
// the safer phase increment of the oscillators.
import("stdfaust.lib");

process = _ <: db[DEBUG = 0;].probe_rms_db(0, 0), db.probe_rms_db(1, 0),
               os[SAFE = 1;].lf_sawpos(440) * 0;

// Only the second probe remains.
// check: --list-params
// expect: Probe_RMS_dB_1
// cpp-absent: Probe RMS dB0
