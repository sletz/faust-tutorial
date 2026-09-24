// Reset by multiplication: a counter multiplied by (1 - reset) inside the
// loop goes back to 0 while reset is 1.
reset = button("reset");

counter = (+(1) : *(1 - reset)) ~ _;

process = counter;

// check: --double -n 8 --in zero --at 3 reset=1 --at 4 reset=0
// expect: ^2,3\.0$
// expect: ^3,0\.0$
// expect: ^4,1\.0$
// expect: ^7,4\.0$
