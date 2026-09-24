// Exercise 2: count the presses of one button, reset by another.
press = button("press");
reset = button("reset");

presses = (press > press') : (+ : *(1 - reset)) ~ _;

process = presses;

// check: --double -n 12 --in zero --at 1 press=1 --at 2 press=0 --at 4 press=1 --at 5 press=0 --at 7 reset=1 --at 8 reset=0 --at 9 press=1
// expect: ^6,2\.0$
// expect: ^7,0\.0$
// expect: ^9,1\.0$
