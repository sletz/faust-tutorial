// A matrix whose coefficient is a function: output o is the sum over i of
// c(i, o) times input i. The matrix is described by a rule, not by a table,
// and the rule is an argument like any other.
import("stdfaust.lib");

matrix(n, m, c) = si.bus(n) <: par(o, m, par(i, n, *(c(i, o))) :> _);

// Sylvester's Hadamard matrix, P a power of 2: +1 or -1 by the parity of the
// bits that i and o share, divided by sqrt(P) so that it keeps the energy.
hadamard(P) = \(i, o).((1 - 2 * (bits(i & o) % 2)) / sqrt(P))
with {
    bits(x) = sum(b, 16, (x >> b) & 1);
};

// A rotation: input i goes to output i + 1, the last one to the first.
rotation(P) = \(i, o).(o == (i + 1) % P);

law(a, b) = no.multinoise(inputs(a)) <: a, b : ro.interleave(outputs(a), 2) : par(i, outputs(a), -);

process = law(matrix(8, 8, hadamard(8)), (ro.hadamard(8) : par(i, 8, /(sqrt(8))))),    // the library's matrix
          law(matrix(8, 8, hadamard(8)) : matrix(8, 8, hadamard(8)), si.bus(8)),        // applied twice: the identity
          law(seq(k, 4, matrix(4, 4, rotation(4))), si.bus(4));                         // four quarter turns: the identity

// Twenty differences; a sample above 1e-12 would fail the check.
// check: --double -n 20000 --in zero --quiet --fail-above 1e-12
// expect: out19: peak=
// The control: a rotation is not its own inverse, and the same check fails
// on two quarter turns.
// check-fails: --double -n 20000 --in zero --quiet --fail-above 1e-12 --eval "law(matrix(4, 4, rotation(4)) : matrix(4, 4, rotation(4)), si.bus(4))"
// check: --double -n 20000 --in zero --quiet --eval "law(matrix(4, 4, rotation(4)) : matrix(4, 4, rotation(4)), si.bus(4))"
// expect: out0: peak=1\.99
