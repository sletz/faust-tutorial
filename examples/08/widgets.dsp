// The widgets: inputs the user controls, and bargraphs the program shows.
import("stdfaust.lib");

gate  = button("gate");                                  // 1 while pressed
on    = checkbox("on");                                  // 0 or 1, stays
level = hslider("level", 0.5, 0, 1, 0.01);               // horizontal slider
tone  = vslider("tone", 1000, 100, 5000, 1);             // vertical slider
voices = nentry("voices", 1, 1, 8, 1);                   // numeric entry

sound = os.osc(tone) * level * max(gate, on) / voices;

// A bargraph shows a signal and passes it through.
process = sound : hbargraph("out", -1, 1);

// check: --list-params
// expect: /widgets/gate +button
// expect: /widgets/on +checkbox
// expect: /widgets/level +slider
// expect: /widgets/voices +(nentry|numentry|entry)
// expect: /widgets/out +bargraph
// check: --double --in zero -n 1000 --quiet --set on=1
// expect: out0: peak=0\.49\d*
