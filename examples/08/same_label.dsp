// Two widgets with the same label in the same group are one widget: a
// definition is a name for an expression, not a place in memory (lac06).
foo = hslider("duration", 128, 2, 512, 1);
faa = hslider("duration", 128, 2, 512, 1);

process = foo + faa;

// One control, and the sum is twice its value.
// check: --list-params
// expect: /same_label/duration
// check: --double --in zero -n 1 --set duration=300
// expect: ^0,600\.0$
