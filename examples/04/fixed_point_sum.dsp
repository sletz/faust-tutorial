// The remedy of Orlarey, Fober and Letz (SMC 2009) for the drift of a
// recursive moving sum: accumulate integers, which add and subtract
// exactly, and convert back at the end. 20 bits of fraction.
float2fix(x) = int(x * (1 << 20));
fix2float(x) = float(x) / (1 << 20);

moving_sum(n, x) = +(x - x@n) ~ _;
moving_sum_fixed(n) = float2fix : moving_sum(n) : fix2float;

direct(x) = float2fix(x), float2fix(x'), float2fix(x''), float2fix(x@3) :> fix2float;

// The float version drifts from the direct sum of the last four samples;
// the fixed-point version equals the direct sum of the same quantised
// samples, exactly, however long it runs.
process = _ <: moving_sum(4) - direct, moving_sum_fixed(4) - direct;

// Single precision, 100 seconds of white noise.
// check: --in white:1 -n 4410000 --quiet
// expect: out0: peak=0\.000\d+ 
// expect: out1: peak=0\.0 
