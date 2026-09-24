// The same network rewritten with pattern matching: wave(w, f) and
// filter(w, f, q) are chosen by the compiler, and node(k, ...) is one
// definition for the five nodes. It reproduces the original exactly (the
// rewrite in the idioms document chains other nodes, in another order).
import("stdfaust.lib");

wave(0, f) = os.osc(f);
wave(1, f) = os.sawtooth(f);
wave(2, f) = os.triangle(f);
wave(3, f) = os.square(f);

// an oscillator node: its own frequency slider, modulated by another signal
node(k, modulation, w) = wave(w, freq + 10 * modulation)
with {
    freq = hslider("freq_node_%k", 440, 1, 1000, 1);
};

filter(0, f, q) = fi.resonlp(f, q, 1.0);
filter(1, f, q) = fi.resonhp(f, q, 1.0);
filter(2, f, q) = fi.resonbp(f, q, 1.0);

node_6(w) = node(6, 0, w);
node_4(w) = node(4, node_6(0), w);
node_3(w) = node(3, node_4(0), w);
node_0(w) = node(0, node_3(0), w);
node_1(w) = node_0(3) : filter(w, freq, q)
with {
    freq = hslider("freq_node_1", 440, 50, 5000, 1);
    q = hslider("q_node_1", 0.5, 0.01, 1, 0.01);
};

process = node_1(0), node_1(0);

// Identical to the original, sample for sample, with the same controls.
// check: --double --in zero -n 44100 --quiet --compare network_original.dsp
// expect: out0: identical
// expect: out1: identical
// check: --list-params
// expect: /network_patterns/freq_node_6
// expect: /network_patterns/q_node_1
