// Exercise 3: a retriggerable gate of exactly 100 ms after each press.
// The state counts down whole samples, which is exact; every new press
// restarts it at n.
import("stdfaust.lib");

press = button("press");

gate_for(n, b) = (b > b') : (loop ~ _) : >(0)
with {
    loop(left, trig) = ba.if(trig, n, max(0, left - 1));
};

process = gate_for(ba.sec2samp(0.1), press);

// 100 ms at 48 kHz is 4800 samples: frames 10 to 4809.
// check: --double --sr 48000 -n 5000 --in zero --at 10 press=1 --at 11 press=0
// expect: ^9,0\.0$
// expect: ^10,1\.0$
// expect: ^4809,1\.0$
// expect: ^4810,0\.0$
