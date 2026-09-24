// Edge detectors from the idioms document: compare a signal with itself one
// sample earlier.
upfront(x)   = x > x';     // 1 on a rising edge
downfront(x) = x < x';     // 1 on a falling edge
front(x)     = x != x';    // 1 on any change

gate = button("gate");

process = gate <: upfront, downfront, front;

// Press at frame 3, release at frame 6.
// check: --double -n 8 --in zero --at 3 gate=1 --at 6 gate=0
// expect: ^2,0\.0,0\.0,0\.0$
// expect: ^3,1\.0,0\.0,1\.0$
// expect: ^4,0\.0,0\.0,0\.0$
// expect: ^6,0\.0,1\.0,1\.0$
