// Learning a filter coefficient by gradient descent (faust-rs only). The
// target is a one-pole filter with pole 0.9; the model has a slider a. The
// program outputs the loss and its gradient over each block, and
// faustprobe's --train runs the descent, as a host would.
// cpp: no
import("stdfaust.lib");

a = hslider("a", 0.5, 0, 0.99, 0.0001);

model  = fi.pole(a);
target = fi.pole(0.9);

process = _ <: model, target : - : ^(2) : rad(_, a);

// The gradient agrees with finite differences, and the descent finds 0.9.
// check: --double --in white:1 --block 256 --train a --fd-check --blocks 0
// expect: fd-check .*relative error \d\.\d+e-1[0-9]
// check: --double --in white:1 --block 256 --train a --lr 0.01 --blocks 800 --every 200
// expect: trained /train_pole/a=0\.9$
// expect: loss: minimum 0\.000000e0
