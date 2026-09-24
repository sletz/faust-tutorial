// An environment groups definitions under a name. library("file.lib") is
// the environment of a file; stdfaust.lib only binds each library to its
// two-letter prefix this way.
ma = library("maths.lib");
os = library("oscillators.lib");

tuning = environment {
    A4 = 440;
    semitone = pow(2, 1/12);
    note(n) = A4 * pow(semitone, n - 69);
};

process = tuning.note(69), tuning.note(81), ma.PI, os.osc(tuning.A4) * 0;

// check: --double -n 1 --in zero
// (2^(12/12) computed in floating point: 880 to within 3e-13)
// expect: ^0,440\.0,880\.000000000000\d*,3\.141592653589793,0\.0$
