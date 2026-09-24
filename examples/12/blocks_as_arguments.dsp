// A function may take blocks as arguments. twice applies a block two times,
// stereo makes a stereo effect from a mono one.
import("stdfaust.lib");

twice(f) = f : f;
stereo(f) = f, f;

process = twice(*(3)), stereo(fi.pole(0.5));

// Three inputs: the first is multiplied by 9, the two others filtered.
// check: --double -n 2 --in dc
// expect: ^0,9\.0,1\.0,1\.0$
// expect: ^1,9\.0,1\.5,1\.5$
