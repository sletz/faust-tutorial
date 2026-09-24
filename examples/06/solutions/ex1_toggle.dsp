// Exercise 1: a toggle. Each press of the button flips the output between
// 0 and 1: the rising edge, then an exclusive or with the previous output.
press = button("press");

toggle(b) = (b > b') : (!= ~ _);

process = toggle(press);

// Two presses: on at frame 2, off at frame 6.
// check: --double -n 10 --in zero --at 2 press=1 --at 3 press=0 --at 6 press=1 --at 8 press=0
// expect: ^1,0\.0$
// expect: ^2,1\.0$
// expect: ^5,1\.0$
// expect: ^6,0\.0$
// expect: ^9,0\.0$
