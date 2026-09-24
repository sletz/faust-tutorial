// Step 2: the lowpass-feedback comb of Freeverb (Schroeder-Moorer). The
// feedback goes through the one-pole lowpass of chapter 4, so each echo is
// duller than the previous one, as in a real room where the air and the
// walls absorb the high frequencies first. The delay sits before the
// output, and the final mem makes the first echo come dt samples late.
lbcf(dt, fb, damp) = (+ : @(max(0, dt - 1))) ~ (*(1 - damp) : (+ ~ *(damp)) : *(fb)) : mem;

process = lbcf(100, 0.8, 0), lbcf(100, 0.8, 0.5);

// Without damping the second echo is 0.8; with damping it is lower and
// spread over the following samples.
// check: --double -n 202
// expect: ^100,1\.0,1\.0$
// expect: ^200,0\.8,0\.4$
// expect: ^201,0\.0,0\.2$
