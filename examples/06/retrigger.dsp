// A second press during a trigger. release and the additive countdown add
// the new count to what is left, so the gate stretches; the countdown of
// exercise 3 restarts at n instead.
import("stdfaust.lib");

impulse(x) = x > x';
release(n) = + ~ (_ <: _, (_ > 0) / n : -);
trigger(n) = impulse : release(n) : >(0);

countdown(n) = *(n) : + ~ (-(1) : max(0));                  // adds up
restart(n) = loop ~ _ with { loop(left, t) = ba.if(t, n, max(0, left - 1)); };

gate = button("gate");

process = gate <: trigger(100),
                  (impulse : countdown(100) : >(0)),
                  (impulse : restart(100) : >(0));

// Presses at frames 1000 and 1050. The first two gates last until frame
// 1199 (150 samples after the second press); the restart ends at 1149.
// check: --double -n 1300 --in zero --at 1000 gate=1 --at 1001 gate=0 --at 1050 gate=1 --at 1051 gate=0
// expect: ^1149,1\.0,1\.0,1\.0$
// expect: ^1150,1\.0,1\.0,0\.0$
// expect: ^1199,1\.0,1\.0,0\.0$
// expect: ^1200,0\.0,0\.0,0\.0$
