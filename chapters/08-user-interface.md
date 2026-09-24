# 8. User interface

## The idea

A Faust program declares its interface inside its code: a slider is an
expression, placed where its value is used. The program does not draw
anything. The compiler collects the widgets and hands a description of them
to an **architecture** (a plugin format, a web page, a phone app, the
IDE), which draws them its own way. The same program therefore gets a
slider in the IDE, a knob in a plugin host and an OSC address on a
network.

What the programmer controls is the **structure**: which widgets exist,
their ranges, how they are grouped and named, and hints in the labels
(metadata) that architectures may follow.

## Widgets

([`widgets.dsp`](../examples/08/widgets.dsp))

```faust
gate   = button("gate");                                 // 1 while pressed
on     = checkbox("on");                                 // 0 or 1, stays
level  = hslider("level", 0.5, 0, 1, 0.01);              // horizontal slider
tone   = vslider("tone", 1000, 100, 5000, 1);            // vertical slider
voices = nentry("voices", 1, 1, 8, 1);                   // numeric entry

process = os.osc(tone) * level * max(gate, on) / voices : hbargraph("out", -1, 1);
```

Sliders and numeric entries take a label, an initial value, a minimum, a
maximum and a step; their value always lies in [minimum, maximum].
`hbargraph` and `vbargraph` go the other way: they show a signal to the
user and pass it through unchanged.

## Groups and paths

`hgroup`, `vgroup` and `tgroup` arrange what they contain horizontally,
vertically, or as tabs. Groups also build the **path** of each widget, the
name under which hosts, OSC and faustprobe address it
([`groups.dsp`](../examples/08/groups.dsp)):

```faust
freq   = hslider("h:filter/freq", 1000, 20, 20000, 1);
master = hslider("../master", 0.5, 0, 1, 0.01);

osc_page  = vgroup("oscillator", hslider("pitch", 220, 50, 1000, 1));
enve_page = vgroup("envelope", hslider("decay", 0.2, 0.01, 2, 0.01));

synth = tgroup("pages", os.sawtooth(osc_page) * en.ar(0.01, enve_page, os.lf_imptrain(2)))
      : fi.resonlp(freq, res, 1);

process = vgroup("synth", synth * master);
```

```text
/groups/synth/pages/oscillator/pitch
/groups/synth/pages/envelope/decay
/groups/synth/filter/freq
/groups/master
```

Three rules show here:

- **a label can name its own groups**: `"h:filter/freq"` puts the slider in
  a horizontal group `filter`, wherever the expression is used;
- **`"../"` moves a widget up one group**: `master` is used inside
  `synth` but appears next to it;
- **the root**: when `process` is a single group, that group is the root
  of the interface; otherwise the compiler adds a root named after the
  program. Here `master` escapes `synth`, so a root `groups` is added.

Inside `par`, a label can contain the value of the loop index: `"voice %v"`
becomes `voice 0`, `voice 1`... when `v` is the index (see the mixer
below). Spaces become `_` in paths.

## Metadata

Square brackets inside a label carry hints for the architectures. They are
removed from the displayed name and from the path
([`metadata.dsp`](../examples/08/metadata.dsp)):

```faust
freq = hslider("[0] freq [unit:Hz] [scale:log] [tooltip:oscillator frequency]", 440, 20, 20000, 1);
gain = hslider("[1] gain [unit:dB] [style:knob] [midi:ctrl 7]", -12, -60, 0, 0.1) : ba.db2linear;
wave = hslider("[2] wave [style:menu{'sine':0;'saw':1;'square':2}]", 0, 0, 2, 1);
pan  = hslider("[3] pan [osc:/1/fader1 0 1]", 0.5, 0, 1, 0.01);
```

| metadata | effect |
|---|---|
| `[0]`, `[1]`... | order of the widgets in their group |
| `[unit:Hz]` | unit shown next to the value |
| `[scale:log]`, `[scale:exp]` | mapping of the slider's travel |
| `[style:knob]` | a knob instead of a slider |
| `[style:menu{'a':0;'b':1}]`, `[style:radio{...}]` | named choices |
| `[tooltip:...]` | help text |
| `[hidden:1]` | not displayed |
| `[midi:ctrl 7]`, `[midi:pitchwheel]`, `[midi:clock]` | MIDI mapping |
| `[osc:/1/fader1 0 1]` | OSC address and range |
| `[acc:...]`, `[gyr:...]` | phone sensors |

Each architecture follows the metadata it understands and ignores the
rest. The Faust distribution's documentation folder has, for instance, the
list of TouchOSC messages written as ready-to-paste `[osc:...]` metadata.
The `[midi:clock]` checkbox of chapter 6 is one such label: a MIDI
architecture flips it at every clock message.

## A label is an identity

Two widgets with the same label in the same group are **the same widget**
([`same_label.dsp`](../examples/08/same_label.dsp)):

```faust
foo = hslider("duration", 128, 2, 512, 1);
faa = hslider("duration", 128, 2, 512, 1);
process = foo + faa;
```

There is one control, and the output is twice its value. Orlarey, Gräf and
Kersten (LAC 2006) use this example to show that a Faust definition is a
name for an expression, not a place in memory. The 2003 tutorial says the
same: the definition mechanism is "a simple naming mechanism, very
different of the naming mechanism of C++ that is in fact an addressing
mechanism".

The converse is just as useful to know: a widget whose value cannot reach
any output **disappears**. With `process = foo - faa`, both compilers
simplify the output to 0 and the program has no widget at all.

## Showing internal signals

A bargraph passes its input through, so it can be inserted anywhere. To
show a signal *without* sending it to an output, use `attach(x, y)`, which
outputs `x` and keeps `y` alive for its side effect, the display. The level
meter of the Den Haag presentation (Orlarey, Fober and Letz, 2006)
([`vumeter.dsp`](../examples/08/vumeter.dsp)):

```faust
envelope = abs : min(0.99) : max ~ -(1.0 / ma.SR);
vumeter = _ <: attach(_, envelope : vbargraph("meter", 0, 1));
```

The envelope follows the peaks and falls by 1 per second in between: its
feedback subtracts 1/SR, and `max` with the new input keeps it above the
signal. A sine of amplitude 0.5 reads just under 0.5. faustprobe prints the
last value of every bargraph:

```text
# bargraph /vumeter/meter=0.49...
```

## Example: a mixer

Orlarey, Fober and Letz give an eight-voice mixer in their SMC 2009 paper;
here it is with today's library names ([`mixer.dsp`](../examples/08/mixer.dsp)):

```faust
vol      = *(hslider("vol [unit:dB]", 0, -70, 4, 0.1) : ba.db2linear : si.smoo);
mute     = *(1 - checkbox("mute"));
pan      = _ <: *(sqrt(1 - p)), *(sqrt(p)) with { p = hslider("pan", 0.5, 0, 1, 0.01) : si.smoo; };
envelope = abs : min(0.99) : max ~ -(1.0 / ma.SR);
vumeter  = _ <: attach(_, envelope : vbargraph("level", 0, 1));

voice(v) = vgroup("voice %v", mute : hgroup("", vol : vumeter) : pan);
stereo   = hgroup("stereo out", vol, vol);

process  = hgroup("mixer", par(i, 8, voice(i)) :> stereo);
```

`par(i, 8, voice(i))` puts eight voices side by side (chapter 11 explains
`par`), each in its own group `voice 0` to `voice 7`. `:>` sums the sixteen
outputs into two. The two `vol` of the master have the same label in the
same group, so they are one slider for both channels. The check mutes
seven voices, pans the fourth hard left, and reads a level of 1 on the left
and 0 on the right.

The panner uses square roots so that the powers of the two sides sum to 1
(exercise 1). An empty group label, as in `hgroup("", ...)`, groups the
widgets on screen and leaves an empty segment in their paths
(`/mixer/voice_3//level`).

## Smooth where it is cheap

A slider changes at most once per block of samples, and the compiler
computes expressions that depend only on sliders once per block too
(chapter 9). `si.smoo` runs at every sample, and so does everything after
it. Tiziano Bole ("Faust Tutorial 2", 2008) measured the difference on a
panner: smoothing the slider *before* `sqrt` puts `sqrt` in the per-sample
loop and multiplies its cost; smoothing *after* `sqrt` keeps `sqrt` at
block rate, at the price of an error he measured at about 0.0085 dB. Smooth
as late as possible, just before the multiplication by the audio.

## The idiom in the libraries

**The `*_demo` functions of demos.lib** wrap a library function in an
interface, with every control defined in a `with` block and a group
function that builds the path ([`demo_pattern.dsp`](../examples/08/demo_pattern.dsp)):

```faust
resonant_lowpass_demo = fi.resonlp(freq, q, gain)
with {
    group(x) = hgroup("resonant lowpass", x);
    freq = group(hslider("[0] freq [unit:Hz] [scale:log]", 1000, 50, 10000, 1)) : si.smoo;
    q    = group(hslider("[1] Q [style:knob]", 2, 0.5, 20, 0.01)) : si.smoo;
    gain = group(hslider("[2] gain", 0.5, 0, 1, 0.01)) : si.smoo;
};
```

The library function stays free of any interface, and the demo adds one.
`dm.moog_vcf_demo` and `dm.gate_demo` in demos.lib are written this way;
`dm.gate_demo` also shows `[tooltip:...]`, `[scale:log]` and a gain meter
kept alive by `attach`.

**Bypass.** `ba.bypass1(bypass, effect)` lets the input through when
`bypass` is 1, and feeds silence to the effect meanwhile
([`bypass.dsp`](../examples/08/bypass.dsp)):

```faust
bypass1(bpc,e) = _ <: select2(bpc,(inswitch:e),_)
with {
    inswitch = select2(bpc,_,0);
};
```

`ba.bypass2` does the same for stereo effects, and `ba.bypass_fade`
crossfades instead of switching.

**Probes.** debug.lib (`db.`) provides ready-made meters that pass the
signal through: `db.probe_rms_db`, `db.probe_peak_db`, `db.probe_value`...
Each takes an identifier and a "hidden" flag, for example
`_ : db.probe_rms_db(0, 0) : _`.

## Pitfalls

- **Same label, same widget.** Two sliders meant to be different need
  different labels or different groups.
- **Unused widgets vanish.** A control that cannot affect an output is
  removed with the code that used it.
- **Paths depend on the root.** Wrapping `process` in a group changes every
  path; scripts and presets that address controls must follow.
- **Smooth late.** Put `si.smoo` after the control-rate arithmetic.

## Exercises

1. A constant-intensity panner with a knob: gains √(1 − c) and √c, whose
   squares sum to 1. Check that the centre gives 0.7071 on each side.
   Solution: [`ex1_panner.dsp`](../examples/08/solutions/ex1_panner.dsp).
2. A peak meter in decibels, from −60 to 0 dB, next to the signal. Check
   that a sine of amplitude 0.5 reads about −6 dB. Solution:
   [`ex2_db_meter.dsp`](../examples/08/solutions/ex2_db_meter.dsp).
3. A four-channel gain stage with one tab per channel. Solution:
   [`ex3_tabs.dsp`](../examples/08/solutions/ex3_tabs.dsp).
