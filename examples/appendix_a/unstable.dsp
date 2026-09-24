// A feedback gain above 1 makes a recursion grow without bound. With
// --fail-above, faustprobe stops at the first sample above a level no sane
// signal reaches, long before the overflow, and says where it started.
gain = hslider("feedback", 0.5, 0, 2, 0.01);

process = + ~ (@(99) : *(gain));

// check: --double -n 44100 --quiet --set feedback=0.9 --fail-above 100
// expect: finite=yes
// check-fails: --double -n 44100 --quiet --set feedback=1.1 --fail-above 100
// expect: (?i)above
