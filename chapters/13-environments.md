# 13. Environments

## The idea

As programs grow, definitions need to be grouped: the coefficients of a
filter together, the parameters of a preset together, the functions of a
library under one prefix. An **environment** is a set of definitions with a
name. It is how the libraries are organised, and the idioms document
describes several ways to use it: as a namespace, as a "class", with
explicit substitution, and as a value passed to functions.

## Namespaces

([`namespace.dsp`](../examples/13/namespace.dsp))

```faust
ma = library("maths.lib");

tuning = environment {
    A4 = 440;
    semitone = pow(2, 1/12);
    note(n) = A4 * pow(semitone, n - 69);
};

process = tuning.note(69), tuning.note(81), ma.PI;
```

`environment { ... }` makes an environment from definitions;
`library("file.lib")` makes one from a file. A member is reached with a
dot. Inside the environment, the definitions see each other: `note` uses
`A4` and `semitone` without a prefix.

This is all `stdfaust.lib` does: it binds each library to its prefix,
`ma = library("maths.lib");`, `os = library("oscillators.lib");`... Every
library also binds its own prefix for itself (`ba = library("basics.lib");`
at the top of basics.lib), so that code copied from a library into a
program still works.

`import("file.lib")` is different: it pours the definitions of a file into
the current scope, without a prefix.

## Records and "classes"

An environment returned by a function is a record whose fields depend on
the arguments. The coefficients of a second-order lowpass from Robert
Bristow-Johnson's cookbook ([`record.dsp`](../examples/13/record.dsp)):

```faust
rbj_lowpass(f, q) = environment {
    w = 2 * ma.PI * f / ma.SR;
    alpha = sin(w) / (2 * q);
    a0 = 1 + alpha;
    b0 = (1 - cos(w)) / 2 / a0;
    b1 = (1 - cos(w)) / a0;
    b2 = b0;
    a1 = -2 * cos(w) / a0;
    a2 = (1 - alpha) / a0;
};

lowpass(f, q) = fi.tf2(c.b0, c.b1, c.b2, c.a1, c.a2) with { c = rbj_lowpass(f, q); };
```

The intermediate values `w`, `alpha` and `a0` are computed once and shared
by the coefficients that use them. maxmsp.lib's `mm.filtercoeff(f0, dBgain,
Q)` is such an environment, with members for every filter type of the
cookbook: `filtercoeff(f0,gain,Q).LPF`.

When members are processes rather than numbers, the environment behaves
like an object with methods. The idioms document's example is the
state-variable filter of filters.lib ([`svf.dsp`](../examples/13/svf.dsp)):

```faust
svf = environment {

    // Internal implementation
    svf(T,F,Q,G) = tick ~ (_,_) : !,!,si.dot(3, mix)
    with { ... };

    // External API
    lp(f,q)     = svf(0, f, q, 0);
    bp(f,q)     = svf(1, f, q, 0);
    hp(f,q)     = svf(2, f, q, 0);
    ...
    hs(f,q,g)   = svf(8, f, q, g);
};
```

One generic filter `svf(T, F, Q, G)`, whose type T selects its mixing
coefficients by pattern matching (`case`, chapter 11), and nine public
filters that fix T. From outside, the user sees `fi.svf.lp(f, q)`,
`fi.svf.hp(f, q)`... Chapter 14 comes back to this generic-then-specialised
structure.

## Explicit substitution

`env[name = value;]` is the environment `env` with one definition
replaced. Everything that used the old definition uses the new one
([`substitution.dsp`](../examples/13/substitution.dsp)):

```faust
synth = environment {
    freq = 440;
    gain = 0.5;
    tone = os.osc(freq) * gain;
};

process = synth.tone, synth[freq = 880;].tone;
```

The second voice is an octave higher: `tone` is recomputed with the new
`freq`. The original `synth` is not modified: substitution makes a new
environment.

The libraries use substitution for **compile-time switches**
([`library_switches.dsp`](../examples/13/library_switches.dsp)):

```faust
process = _ <: db[DEBUG = 0;].probe_rms_db(0, 0), db.probe_rms_db(1, 0);
```

debug.lib has a constant `DEBUG = 1;`, and every probe is defined by
pattern matching on it: with `DEBUG = 0` a probe is the identity, and
compiles to nothing. debug.lib's own documentation describes it: the
switch makes "a fully probed patch compile down to the unprobed one". In
the same way, `os[SAFE = 1;]` selects the safer phase increment of the
oscillators (chapter 7). This is the clean way to make the compile-time
choices of chapter 9: no widget, no `ba.if`, no dead branch.

## Environments as values

An environment can be passed to a function, like a preset
([`argument.dsp`](../examples/13/argument.dsp)):

```faust
play(cfg) = os.osc(cfg.freq) * cfg.gain;

low  = environment { freq = 220; gain = 0.5; };
high = environment { freq = 880; gain = 0.25; };

process = play(low), play(high);
```

`play` reads the members of whatever it receives. The idioms document cites
David Südholt's coupled finite-difference schemes as a use of this in
practice, and tonestacks.lib binds an environment of component values to a
local name:

```faust
bassman(T,M,L) = tonestack(t.C1,t.C2,t.C3,t.R1,t.R2,t.R3,t.R4,T,M,L)
                    with {t = ts.bassman;};
```

## The idiom in the libraries

- **Prefixes.** `stdfaust.lib` is a list of `xx = library("file.lib");`.
- **Units as blocks.** tonestacks.lib opens with an environment of units,
  each a partial application: `k = *(1e3); M = *(1e6); nF = *(1e-9);`, so
  that a component reads `R1 = 250:k;`.
- **A parametric environment.** noises.lib builds its generators in an
  environment parameterised by a seed, `_noise_env(seed)`, and defines
  `noise = _noise_env(12345).noise;`. The leading underscore marks the
  environment as internal to the library.
- **Objects.** soundfiles.lib's `so.sound(sf, part)` returns an environment
  with methods `.loop`, `.play(level, gate)`... to play a sound file.

## Pitfalls

- **`import` or `library`.** `import` mixes names into your scope, and two
  libraries may define the same name; `library` keeps them apart.
- **Substitution needs a name defined in the environment.** It replaces a
  definition, it does not add one.
- **Internal names.** Do not use another library's names that start with
  `_`: they may change without notice.

## Exercises

1. Two presets of a synth environment made by substitution: a dark one
   (low cutoff) and a bright one (higher pitch and cutoff). Solution:
   [`ex1_presets.dsp`](../examples/13/solutions/ex1_presets.dsp).
2. An environment `rbj(f, q)` whose members `lpf` and `hpf` are filters.
   Check at DC that the first passes and the second blocks. Solution:
   [`ex2_filter_object.dsp`](../examples/13/solutions/ex2_filter_object.dsp).
3. A meter environment with a `SHOW` switch, like debug.lib's `DEBUG`:
   `meters[SHOW = 0;].level` must compile to nothing. Solution:
   [`ex3_switch.dsp`](../examples/13/solutions/ex3_switch.dsp).
