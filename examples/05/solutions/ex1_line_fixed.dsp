// Exercise 1: a line~ that never overshoots. The ramp length is rounded to
// a whole number of samples, at least one.
import("stdfaust.lib");

line(value, time) = state ~ (_, _) : !, _
with {
    samples = max(1, int(time * ma.SR / 1000.0 + 0.5));
    state(t, c) = nt, nc
    with {
        nt = ba.if(value != value', samples, t - 1);
        nc = ba.if(nt <= 0, value, c + (value - c) / nt);
    };
};

target = hslider("target", 0, 0, 1, 0.001);

process = line(target, 0.1);

// 4.8 samples become 5 equal steps of 0.2, and the peak is exactly 1.
// check: --double --sr 48000 --in zero -n 16 --at 4 target=1
// expect: ^4,0\.2$
// expect: ^8,1\.0$
// expect: out0: peak=1\.0 
