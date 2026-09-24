// trigger(n): an impulse turned into a gate n samples long, from the idioms
// document. The float version lasts n + 1 samples here, because of the
// rounding shown in release.dsp. Counting down whole numbers is exact.
impulse(x) = x > x';
release(n) = + ~ (_ <: _, (_ > 0) / n : -);
trigger(n) = impulse : release(n) : >(0);

// Exact version: start at n, subtract 1 per sample, stop at 0.
countdown(n) = *(n) : + ~ (-(1) : max(0));
trigger_exact(n) = impulse : countdown(n) : >(0);

gate = button("gate");

process = gate <: trigger(3), trigger_exact(3);

// check: --double -n 8 --in zero --at 1 gate=1
// expect: ^3,1\.0,1\.0$
// expect: ^4,1\.0,0\.0$
// expect: ^5,0\.0,0\.0$
