// A program that learns inside itself (faust-rs only): the learned gain is
// recursive state (chapter 5), and each sample takes a gradient step on the
// squared error, the derivative coming from fad.
// cpp: no
target_gain = hslider("gain", 0.5, 0, 1, 0.01);
input = 1.0;
true_value = input * target_gain;

learned_gain = step ~ _
with {
    step(previous) = previous - rate * gradient
    with {
        rate = 0.01;
        loss = (true_value - input * previous) ^ 2;
        gradient = fad(loss, previous) : !, _;
    };
};

process = true_value, learned_gain;

// The learned gain starts at 0 and reaches the target within 2000 samples
// (0.2999999999999986, the rounding of the last step).
// check: --double --in zero -n 2000 --set gain=0.3
// expect: ^0,0\.3,0\.006$
// expect: ^1999,0\.3,0\.29999999999999\d*$
