// Exercise 2: record n samples while a button is held, and play them in a
// loop. When not recording, the writes go to an extra "dead" cell, as the
// 2003 tutorial advises for a table that is not always written.
import("stdfaust.lib");

n = 100;
rec = button("rec");

position = (+(1) : %(n)) ~ _ : mem;                    // 0, 1, ..., n-1, 0, ...
write_index = select2(rec, n, position);               // cell n is the dead cell
recorder = rwtable(n + 1, 0.0, write_index, _, position);

process = recorder;

// The impulse at frame 0 is recorded in cell 0; recording stops at frame
// 100; the loop plays it back at frames 100 and 200.
// check: --double -n 201 --at 0 rec=1 --at 100 rec=0
// expect: ^100,1\.0$
// expect: ^150,0\.0$
// expect: ^200,1\.0$
