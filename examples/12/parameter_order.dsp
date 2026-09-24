// The library convention: fixed parameters first, the signal last. Then a
// partial application is a ready-made block. With the signal first, every
// argument must be given at each use.
import("stdfaust.lib");

gain_last(g, x) = x * g;        // convention: gain_last(0.5) is a block
gain_first(x, g) = x * g;       // gain_first(_, 0.5) is needed instead

process = _ <: gain_last(0.5), gain_first(_, 0.5), (_ : gain_last(2) : gain_last(0.25));

// check: --double -n 1
// expect: ^0,0\.5,0\.5,0\.5$
