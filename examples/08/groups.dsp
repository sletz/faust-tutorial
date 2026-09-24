// Groups arrange widgets and build their paths. A label can also name its
// groups itself ("h:filter/freq"), and "../" moves a widget up one group.
import("stdfaust.lib");

freq   = hslider("h:filter/freq", 1000, 20, 20000, 1);
res    = hslider("h:filter/resonance", 1, 0.5, 10, 0.01);
master = hslider("../master", 0.5, 0, 1, 0.01);          // out of "synth"

osc_page    = vgroup("oscillator", hslider("pitch", 220, 50, 1000, 1));
enve_page   = vgroup("envelope", hslider("decay", 0.2, 0.01, 2, 0.01));

synth = tgroup("pages", os.sawtooth(osc_page) * en.ar(0.01, enve_page, os.lf_imptrain(2)))
      : fi.resonlp(freq, res, 1);

process = vgroup("synth", synth * master);

// check: --list-params
// expect: /groups/synth/pages/oscillator/pitch
// expect: /groups/synth/pages/envelope/decay
// expect: /groups/synth/filter/freq
// expect: /groups/master
