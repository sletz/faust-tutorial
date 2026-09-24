// Reference for major_scale.dsp: the same scale written as arithmetic on
// the step, used only to compare.
import("stdfaust.lib");
i = int(os.lf_sawpos(10) * 12);
note(k) = (k == 0) * -1 + (k == 1) * 0 + (k == 2) * 2 + (k == 3) * 4 + (k == 4) * 5 + (k == 5) * 7
        + (k == 6) * 9 + (k == 7) * 11 + (k == 8) * 12 + (k == 9) * 14 + (k == 10) * 16 + (k == 11) * 17;
process = note(i), note(i);
