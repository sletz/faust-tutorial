// Exercise 1: a dry/wet mix around any mono effect, the effect being an
// argument: dry_wet(mix, fx).
import("stdfaust.lib");

dry_wet(mix, fx) = _ <: _, fx : si.interpolate(mix);

mix = hslider("mix", 0.5, 0, 1, 0.01);

process = dry_wet(mix, *(-1));

// With an effect that inverts the signal: mix 0 is the input, mix 1 its
// opposite, mix 0.5 silence.
// check: --double -n 1 --set mix=0
// expect: ^0,1\.0$
// check: --double -n 1 --set mix=1
// expect: ^0,-1\.0$
// check: --double -n 1 --set mix=0.5
// expect: ^0,0\.0$
