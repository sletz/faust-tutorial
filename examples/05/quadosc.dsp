// The quadrature oscillator of the idioms document (Dario Sanfilippo and
// Oleg Nesterov): two state variables, both output, a cosine and a sine.
// The state starts at 0, so u is stored minus 1: "mem + 1" adds it back,
// and the cosine starts at 1.
import("stdfaust.lib");

quadosc(f) = tick ~ (_, _) : mem + 1, mem
with {
    k1 = tan(f * ma.PI / ma.SR);
    k2 = 2 * k1 / (1 + k1 * k1);
    tick(u_0, v_0) = u_1, v_1
    with {
        tmp = u_0 - k1 * v_0;
        v_1 = v_0 + k2 * (tmp + 1);
        u_1 = tmp - k1 * v_1;
    };
};

process = quadosc(440);

// Amplitude 1 on both outputs, and the same samples as the library's
// os.quadosc, which sets the initial state with select2(1', 1) instead.
// check: --double --in zero -n 44100 --quiet
// expect: out0: peak=1\.0000000000000
// expect: out1: peak=0\.99999
// check: --double --in zero -n 44100 --quiet --compare quadosc_library.dsp --rel-tolerance 1e-12
// expect: out0: max_abs=.*within tolerance
// expect: out1: max_abs=.*within tolerance
