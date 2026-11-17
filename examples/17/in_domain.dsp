// A combinator: transform, process, transform back. inDomain takes three
// circuits and returns one. With the mid/side transform it gives a stereo
// width control: a gain on the side signal alone.
import("stdfaust.lib");

inDomain(T, fx, Tinv) = T : fx : Tinv;

toMS = _, _ <: +, - : /(2), /(2);       // left, right -> mid, side
fromMS = _, _ <: +, -;                  // mid, side -> left, right
inMS(fx) = inDomain(toMS, fx, fromMS);

width = hslider("width", 1, 0, 2, 0.01);

process = inMS((_, *(width)));

// An impulse on the left input. Width 1 leaves it alone, width 0 puts it
// in the middle, width 2 sends its opposite to the right.
// check: --double -n 1 --in impulse:0
// expect: ^0,1\.0,0\.0$
// check: --double -n 1 --in impulse:0 --set width=0
// expect: ^0,0\.5,0\.5$
// check: --double -n 1 --in impulse:0 --set width=2
// expect: ^0,1\.5,-0\.5$
