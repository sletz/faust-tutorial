// Step 3: the Schroeder allpass of filters.lib: echoes like a comb, but
// with a flat magnitude response: it thickens the echo density without
// colouring the sound.
import("stdfaust.lib");

allpass(maxdel, N, aN) = (+ <: de.delay(maxdel, N - 1), *(aN)) ~ *(-aN) : mem, _ : +;

process = allpass(1024, 556, -0.5);

// The same as the library's fi.allpass_comb, and flat at every frequency.
// check: --double -n 20000 --in white:1 --quiet --compare step3_reference.dsp
// expect: out0: identical
// check: --double -n 65536 --freqresp 4:100:10000
// The magnitude is 0 dB to within 1e-12 dB.
// expect: ^100\.0,-?\d\.\d+e-1[2-9],
// expect: ^10000\.0,-?\d\.\d+e-1[2-9],
