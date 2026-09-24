// Max/MSP's line~ from the idioms document: go from the current value to a
// new target in `time` milliseconds. Two state variables: t, the number of
// samples left in the ramp, and c, the current value.
import("stdfaust.lib");

line(value, time) = state ~ (_, _) : !, _
with {
    samples = time * ma.SR / 1000.0;
    state(t, c) = nt, nc
    with {
        nt = ba.if(value != value', samples, t - 1);   // restart on a new target
        nc = ba.if(nt <= 0, value, c + (value - c) / nt);
    };
};

target = hslider("target", 0, 0, 1, 0.001);
time = hslider("time", 1, 0, 1000, 0.001);

process = line(target, time);

// 1 ms at 48 kHz is 48 samples: the target set at frame 100 is reached at 147.
// check: --double --sr 48000 --in zero -n 200 --at 100 target=1
// expect: ^99,0\.0$
// expect: ^123,0\.49999
// expect: ^147,1\.0$
// expect: out0: peak=1\.0 
