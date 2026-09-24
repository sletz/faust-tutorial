// The same line~ when the ramp is not a whole number of samples:
// 0.1 ms at 48 kHz is 4.8 samples. The last step divides by 0.8 and
// overshoots. ba.line and maxmsp.lib's line did the same until
// faustlibraries 2.74.3; they now round the ramp to 5 samples.
import("stdfaust.lib");
mm = library("maxmsp.lib");

line(value, time) = state ~ (_, _) : !, _
with {
    samples = time * ma.SR / 1000.0;
    state(t, c) = nt, nc
    with {
        nt = ba.if(value != value', samples, t - 1);
        nc = ba.if(nt <= 0, value, c + (value - c) / nt);
    };
};

target = hslider("target", 0, 0, 1, 0.001);

process = line(target, 0.1), ba.line(0.1 * ma.SR / 1000, target), mm.line(target, 0.1);

// check: --double --sr 48000 --in zero -n 16 --at 4 target=1
// expect: ^4,0\.208333\d*,0\.2,0\.2$
// expect: ^8,1\.041666\d*,1\.0,1\.0$
// expect: out0: peak=1\.041666
// expect: out1: peak=1\.0 
// expect: out2: peak=1\.0 
