// The major scale of the idioms document, two ways: a constant table read
// with rdtable, and ba.selectn over twelve constants. Same values.
import("stdfaust.lib");

major_scale = waveform{-1, 0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17};
scale_table(i)  = major_scale, i : rdtable;
scale_select(i) = -1, 0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17 : ba.selectn(12, i);

// The index changes at every sample: it walks through the scale ten times
// per second.
i = int(os.lf_sawpos(10) * 12);

process = scale_table(i), scale_select(i);

// The table is stored once and read with one memory access; selectn becomes
// a tree of comparisons evaluated at every sample.
// cpp-expect: const static int imydspSIG0Wave0\[12\] = \{-1,0,2,4,5,7,9,11,12,14,16,17\};
// cpp-expect: itbl0mydspSIG0\[std::max<int>\(0, std::min<int>\(iTemp1, 11\)\)\]
// cpp-expect: \(iTemp1 >= 6\) \?
// check: --double --in zero -n 4410 --quiet --compare scale_reference.dsp
// expect: out0: identical
// expect: out1: identical
