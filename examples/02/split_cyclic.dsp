// With two outputs into four inputs, the outputs are distributed
// cyclically: a, b, a, b.
process = _, _ <: *(1), *(1), *(10), *(10);

// An impulse on input 0 only comes out on outputs 0 and 2.
// check: --double -n 1 --in impulse:0
// expect: ^0,1\.0,0\.0,10\.0,0\.0$
