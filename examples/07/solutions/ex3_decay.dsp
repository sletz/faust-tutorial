// Exercise 3: an exponential decay started by each beat: set to 1 on the
// beat, multiply by the pole at every other sample. With a pole of 0.99 the
// level loses 1 % per sample.
import("stdfaust.lib");

decay(pole, trig) = loop ~ _
with {
    loop(prev) = ba.if(trig > 0, 1, prev * pole);
};

process = decay(0.99, ba.beat(120));

// check: --double --sr 1000 --in zero -n 502
// expect: ^0,1\.0$
// expect: ^1,0\.99$
// expect: ^2,0\.9801$
// expect: ^500,1\.0$
