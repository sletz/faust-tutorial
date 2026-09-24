# 5. State with several variables

## The idea

Chapter 4 fed back one signal. Many processes need several numbers that
evolve together: a ramp needs its current value *and* the number of
samples left; an oscillator needs a position *and* a velocity; an envelope
needs a level *and* the stage it is in. Faust has one pattern for all of
them, found throughout the libraries:

```faust
process = tick ~ (_, _) : !, _
with {
    tick(x, y) = next_x, next_y;
};
```

Read it as a recipe:

1. **As many feedback wires as state variables.** `~ (_, _)` brings back two
   signals, so the state has two variables.
2. **`tick` receives the current state and returns the next one.** Its
   arguments `x, y` are the values of the previous sample (the feedback
   delays them by one sample, chapter 4); its outputs are the new values.
   Extra arguments after the state are the inputs of the process.
3. **The output keeps what is useful and cuts the rest.** `: !, _` drops the
   internal variable and outputs the other.

The initial state is always zero: every variable starts at 0.

## A first example: two numbers that walk together

([`fibonacci.dsp`](../examples/05/fibonacci.dsp))

```faust
fibonacci = tick ~ (_, _) : !, _
with {
    kick = 1 - 1';                   // 1 at the first sample only
    tick(a, b) = b, a + b + kick;
};
```

The state (a, b) becomes (b, a + b) at each sample. Since it starts at
(0, 0), which would stay at 0 forever, `kick` adds 1 once. The output is b:
1, 1, 2, 3, 5, 8... Fibonacci is not audio, but the whole pattern is
there, and it is easy to check by hand.

## Max/MSP's `line~`

The idioms document gives an implementation of Max/MSP's `line~`, which goes
from its current value to a new target in a given time
([`line.dsp`](../examples/05/line.dsp)):

```faust
line(value, time) = state ~ (_, _) : !, _
with {
    samples = time * ma.SR / 1000.0;
    state(t, c) = nt, nc
    with {
        nt = ba.if(value != value', samples, t - 1);   // restart on a new target
        nc = ba.if(nt <= 0, value, c + (value - c) / nt);
    };
};
```

Two state variables: `t`, the number of samples left in the ramp, and `c`,
the current value.

- When the target changes (`value != value'`, chapter 6 comes back to this
  edge detector), `t` is reset to the length of the ramp in samples;
  otherwise it counts down.
- While samples are left, `c` covers `1/nt` of the remaining distance; at
  the end it is exactly the target.
- The output cuts `t` and keeps `c`.

`ma.SR` is the sampling rate and `ba.if(cond, then, else)` chooses between
two signals; both come back in chapter 6.

faustprobe can move a slider at an exact frame with `--at`. At 48 kHz, a
1 ms ramp towards 1, started at frame 100, is halfway at frame 123 and
arrives at frame 147:

```bash
faustprobe --double --sr 48000 --in zero -n 200 --at 100 target=1 line.dsp
```

The idioms document gives the same function a second time, with the next
values computed inline in the tuple: `state(t, c) = nt, ba.if(nt <= 0, ...)`.
Both writings compile to the same code. Naming the next values `nt` and
`nc` is what makes the pattern readable.

### A bug worth knowing: the overshoot

When the ramp is not a whole number of samples, the last step divides by a
number smaller than 1 and **overshoots**. At 48 kHz, 0.1 ms is 4.8 samples
([`line_overshoot.dsp`](../examples/05/line_overshoot.dsp)):

```text
frame  4    0.2083
frame  5    0.4167
frame  6    0.6250
frame  7    0.8333
frame  8    1.0417    <- above the target
frame  9    1.0000
```

The fix is exercise 1: round the length of the ramp to a whole number of
samples. The library's `ba.line` and `mm.line` in maxmsp.lib have the same
structure, and had the same overshoot until faustlibraries 2.74.3
(basics.lib 1.23.2, maxmsp.lib 1.1.1), which rounds their ramp length in
this way. The example outputs the three: the `line` above reaches 1.0417,
`ba.line` and `mm.line` go up in five steps of 0.2 and reach exactly 1.

## Two variables, both output: the quadrature oscillator

Sometimes every state variable is useful. The quadrature oscillator of
Dario Sanfilippo and Oleg Nesterov, quoted in the idioms document, keeps a
cosine and a sine and outputs both
([`quadosc.dsp`](../examples/05/quadosc.dsp)):

```faust
quadosc(f) = tick ~ (_, _) : mem + 1, mem
with {
    k1 = tan(f * ma.PI / ma.SR);
    k2 = 2 * k1 / (1 + k1 * k1);
    tick(u_0, v_0) = u_1, v_1
    with {
        tmp = u_0 - k1 * v_0;
        v_1 = v_0 + k2 * (tmp + 1);
        u_1 = tmp - k1 * v_1;
    };
};
```

Each sample rotates the point (u, v) by the angle 2πf/SR. A cosine must
start at 1, but the state starts at 0. This version stores u − 1 instead of
u: the `+ 1` inside `tick` and the `mem + 1` at the output add it back.

The library's `os.quadosc` solves the same problem differently: it forces
the first value with `select2(1', 1)`, which is 1 at the first sample and
the computed value afterwards.

```faust
u_1 = tmp - k1 * v_1 : select2(1',1);
```

faustprobe finds the two versions equal to within 2e-14 over one second.
Both tricks, an offset or a forced first sample, are the two ways to give a
state a non-zero start.

## `letrec`: the same states as equations

`letrec` writes the state as a set of equations instead of a function
([`letrec.dsp`](../examples/05/letrec.dsp)):

```faust
counter = c letrec { 'c = c + 1; };

fibonacci = a letrec {
    'a = b;
    'b = a + b + (1 - 1');
};
```

Each line `'x = E` defines the next value of the variable x. Inside the
equations, a variable denotes its value at the previous sample. Outside,
in the expression before `letrec`, it denotes its new value. The counter
therefore outputs 1, 2, 3... exactly like `1 : + ~ _`. In the Fibonacci
version the output is `a`, which is b delayed by one sample: 0, 1, 1, 2, 3,
5.

`letrec` is convenient when the equations come from a paper. The `tick`
pattern is more common in the libraries, because it composes with the rest
of the block algebra.

## The idiom in the libraries

`ba.peakholder` in basics.lib holds the peak of a signal for a given number
of samples. It is the `line~` pattern with well-named variables:

```faust
peakholder(holdTime, x) = loop ~ si.bus(2) : ! , _
    with {
        loop(timerState, outState) = timer , output
            with {
                isNewPeak = abs(x) >= outState;
                isTimeOut = timerState >= holdTime;
                bypass = isNewPeak | isTimeOut;
                timer = ba.if(bypass, 0, timerState + 1);
                output = ba.if(bypass, abs(x), outState);
            };
    };
```

`si.bus(2)` is `_, _`. The names `timerState` and `outState` say what each
wire holds, and the output cuts the timer.

Other examples to read:

- `si.onePoleSwitching` in signals.lib has a single state variable, whose
  coefficient depends on the direction the signal moves;
- the envelopes of envelopes.lib (`en.adsr_bias`) are state machines,
  with a stage index and a level;
- `si.smoothq` in signals.lib carries seven state variables and cuts six;
- `letrec` appears in `an.goertzelOpt` (analyzers.lib) and in mi.lib's
  masses.

## Pitfalls

- **The initial state is zero.** Plan for it: an offset, a forced first
  sample (`select2(1', ...)`), or an initialisation on the first sample
  (exercise 2).
- **Count the wires.** `~ (_, _)` needs a `tick` with at least two inputs
  and exactly two outputs coming back; the process's own inputs come after
  the state arguments.
- **Divisions in a state update.** A step that divides by a count
  (`(value - c) / nt`) is safe only when the count is a whole number; see
  the overshoot above.

## Exercises

1. Fix the overshoot of `line`: round the ramp length to a whole number of
   samples, at least 1. Check that the ramp of 4.8 samples becomes 5 equal
   steps and never exceeds its target. Solution:
   [`ex1_line_fixed.dsp`](../examples/05/solutions/ex1_line_fixed.dsp).
2. Output the minimum and the maximum of a signal since the start, with two
   state variables. Beware of the initial 0. Solution:
   [`ex2_minmax.dsp`](../examples/05/solutions/ex2_minmax.dsp).
3. The "magic circle" oscillator: `x` and `y` rotate by a small angle each
   sample (x ← x + e·y, then y ← y − e·x with the new x, e = 2 sin(πf/SR)).
   Start it with an impulse and check that its amplitude stays bounded.
   Solution: [`ex3_circle.dsp`](../examples/05/solutions/ex3_circle.dsp).
