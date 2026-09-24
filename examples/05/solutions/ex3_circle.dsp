// Exercise 3: the "magic circle" oscillator. Two state variables x and y
// rotate by a small angle each sample; an impulse starts the rotation.
import("stdfaust.lib");

circle(f) = tick ~ (_, _) : _, !
with {
    e = 2 * sin(ma.PI * f / ma.SR);
    tick(x, y) = xn, yn
    with {
        xn = x + e * y + (1 - 1');
        yn = y - e * xn;
    };
};

process = circle(440);

// The amplitude stays bounded and the output is finite after one second.
// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=1\.0\d* 
// expect: finite=yes
