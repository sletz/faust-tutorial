// Higher-order functions of the libraries. fi.fb_comb_common takes the
// delay operator itself as an argument: fi.fb_comb passes de.delay(maxdel),
// a partial application; here we pass @, the plain delay.
import("stdfaust.lib");

comb_at = fi.fb_comb_common(@, 10, 1, 0.5);
comb_de = fi.fb_comb_common(de.delay(64), 10, 1, 0.5);

// si.repeat(n, FX) chains n copies of FX and sums the output of every
// stage: FX(x) + FX(FX(x)) + FX(FX(FX(x))). With *(2): 2x + 4x + 8x = 14x.
repeated = si.repeat(3, *(2));

process = _ <: comb_at, comb_de, repeated;

// check: --double -n 21
// expect: ^0,1\.0,1\.0,14\.0$
// The echo comes N = 10 samples later: the comb delays by N - 1 in its
// loop, and ~ adds the last sample (chapter 4).
// expect: ^9,0\.0,0\.0,0\.0$
// expect: ^10,0\.5,0\.5,0\.0$
// expect: ^20,0\.25,0\.25,0\.0$
