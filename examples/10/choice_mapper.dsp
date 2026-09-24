// The "choice mapper" of the idioms document: map a menu entry to a value.
// With a widget as index, both forms run once per block, before the sample
// loop, so the cost difference disappears.
import("stdfaust.lib");

choice_table(choice, wf) = wf, (choice : int) : rdtable;
choice_select(choice, values) = values : ba.selectn(outputs(values), choice);

algo = nentry("algo", 4, 0, 4, 1);

process = choice_table(algo, waveform{4, 3, 2, 1, 0}),
          choice_select(algo, (4, 3, 2, 1, 0));

// cpp-expect: int iSlow\d+ = itbl0mydspSIG0\[
// check: --double -n 1 --in zero --set algo=1
// expect: ^0,3\.0,3\.0$
// check: --double -n 1 --in zero --set algo=4
// expect: ^0,0\.0,0\.0$
