// par, seq, sum and prod repeat a block N times, with an index i that the
// body may use. N must be known at compile time.
gains   = par(i, 4, *(i + 1));          // 4 inputs, 4 outputs: x1, 2 x2, 3 x3, 4 x4
chain   = seq(i, 3, +(1));              // +(1) : +(1) : +(1)
total   = sum(i, 4, i * i);             // 0 + 1 + 4 + 9, a constant
product = prod(i, 3, i + 2);            // 2 * 3 * 4, a constant

process = gains, chain, total, product;

// cpp-expect: static_cast<FAUSTFLOAT>\(14\)
// cpp-expect: static_cast<FAUSTFLOAT>\(24\)
// check: --double -n 1 --in dc
// expect: ^0,1\.0,2\.0,3\.0,4\.0,4\.0,14\.0,24\.0$
