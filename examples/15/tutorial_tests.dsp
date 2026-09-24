// The tests of tutorial.lib, one definition per documented function, as in
// faustlibraries' tests/<library>_tests.dsp. Each test is evaluated on its
// own with faustprobe --eval, and must produce a finite, non-zero signal.
import("stdfaust.lib");
tu = library("tutorial.lib");

svf_test = no.noise : tu.svf(1000, 0.707);
lp_test = no.noise : tu.lp(1000, 0.707);
hp_test = no.noise : tu.hp(1000, 0.707);
notch_test = no.noise : tu.notch(1000, 0.707);
svf_demo_test = no.noise : tu.svf_demo;

process = lp_test;

// check: --double --in zero -n 4410 --quiet --eval svf_test --eval lp_test --eval hp_test --eval notch_test --eval svf_demo_test
// expect: out0: peak=(?!0\.0 )\d+\.\d+ .*finite=yes
// expect: out2: peak=(?!0\.0 )\d+\.\d+ .*finite=yes
// expect: out3: peak=(?!0\.0 )\d+\.\d+ .*finite=yes
// expect: out4: peak=(?!0\.0 )\d+\.\d+ .*finite=yes
// expect: out5: peak=(?!0\.0 )\d+\.\d+ .*finite=yes
// expect: out6: peak=(?!0\.0 )\d+\.\d+ .*finite=yes
