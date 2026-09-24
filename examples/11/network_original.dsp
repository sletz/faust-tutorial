// The oscillator network of the idioms document, as written there: each node
// computes four oscillators and keeps one with ba.selector.
import("stdfaust.lib");

node_0 = os.osc(rfreq), os.sawtooth(rfreq), os.triangle(rfreq),
os.square(rfreq) with {
   freq = hslider("freq_node_0", 440, 1, 1000, 1);
   rfreq = freq + 10 * (node_3 : ba.selector(0, 4));
};

node_1 = ((node_0 : ba.selector(3, 4)) : fi.resonlp(freq, q, 1.0)),
((node_0 : ba.selector(3, 4)) : fi.resonhp(freq, q, 1.0)), ((node_0 :
ba.selector(3, 4)) : fi.resonbp(freq, q, 1.0)) with {
   freq = hslider("freq_node_1", 440, 50, 5000, 1);
   q = hslider("q_node_1", 0.5, 0.01, 1, 0.01);
};

process = (node_1 : ba.selector(0, 3)), (node_1 : ba.selector(0, 3));

node_3 = os.osc(rfreq), os.sawtooth(rfreq), os.triangle(rfreq),
os.square(rfreq) with {
   freq = hslider("freq_node_3", 440, 1, 1000, 1);
   rfreq = freq + 10 * (node_4 : ba.selector(0, 4));
};

node_4 = os.osc(rfreq), os.sawtooth(rfreq), os.triangle(rfreq),
os.square(rfreq) with {
   freq = hslider("freq_node_4", 440, 1, 1000, 1);
   rfreq = freq + 10 * (node_6 : ba.selector(0, 4));
};

node_6 = os.osc(rfreq), os.sawtooth(rfreq), os.triangle(rfreq),
os.square(rfreq) with {
   freq = hslider("freq_node_6", 440, 1, 1000, 1);
   rfreq = freq + 10 * 0;
};

// check: --list-params
// expect: /network_original/freq_node_6
