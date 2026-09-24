// A block built inside a function keeps the values it was built with: each
// voice below has its own detune, captured when voice(i) is evaluated, and
// its own slider, named after i.
import("stdfaust.lib");

base = hslider("base", 220, 50, 1000, 1);

voice(i) = os.sawtooth(base * ratio) * level
with {
    ratio = 1 + 0.01 * i;
    level = hslider("level %i", 0.25, 0, 1, 0.01);
};

process = sum(i, 4, voice(i));

// check: --list-params
// expect: /closure/level_0
// expect: /closure/level_3
// check: --double --in zero -n 44100 --quiet
// expect: finite=yes
