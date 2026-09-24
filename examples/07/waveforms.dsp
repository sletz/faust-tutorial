// Every basic waveform is a function of the phase.
import("stdfaust.lib");

freq = hslider("freq", 100, 1, 1000, 1);
p = os.lf_sawpos(freq);

sine     = sin(2 * ma.PI * p);
saw      = 2 * p - 1;
square   = 2 * (p < 0.5) - 1;
triangle = 4 * abs(p - 0.5) - 1;
pulse(d) = p < d;                     // 0/1 pulse, duty cycle d

process = sine, saw, square, triangle, pulse(0.25);

// Over 10 whole periods of 441 samples: the waveforms have almost no mean
// (the square spends one more sample up than down), the pulse is up 111
// samples out of 441.
// check: --double --in zero -n 4410 --quiet
// expect: out0: peak=0\.9999\d* rms=0\.7071\d* dc=-?\d\.\d+e-1\d
// expect: out2: peak=1\.0 rms=1\.0 dc=0\.002\d* 
// expect: out3: peak=1\.0 
// expect: out4: peak=1\.0 rms=0\.50\d* dc=0\.25\d* 
