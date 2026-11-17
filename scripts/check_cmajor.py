#!/usr/bin/env python3
"""Check the Cmajor programs of chapter 17 against the samples their comments give.

Usage
-----

    python3 scripts/check_cmajor.py                 every .cmajor file under examples/
    python3 scripts/check_cmajor.py FILE_OR_FOLDER  some of them

or, from the top of the repository, `make cmajor`. It prints one line per
program, `ok    PATH (N samples)` or `FAIL  PATH` followed by what went wrong,
then `K/N Cmajor programs checked`. The exit status is 0 when every program
passes, 1 otherwise.

This is not part of `make check`: the tutorial needs Faust, not Cmajor.

Tools
-----

    CMAJ    the Cmajor command-line tool (default `cmaj`, from the PATH)
    CXX     a C++17 compiler (default `c++`)

What is checked
---------------

Each program has one main processor or graph, marked `[[ main ]]`, with a
mono `input stream float in` and a mono `output stream float out`, and one
comment line

    // impulse: 0.5 0.25 0.125

which gives its first output samples when `in` receives 1, 0, 0, ...

`cmaj generate --target=cpp` turns the program into a C++ class, a few lines
of C++ run that class on the impulse at 48 kHz, and every sample must be
within 1e-6 of the one announced. `cmaj render` is not used: on short
renders it gave silence.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CMAJ = os.environ.get("CMAJ", "cmaj")
CXX = os.environ.get("CXX", "c++")
TOLERANCE = 1e-6

# The driver: MAIN is the name of the generated class, FRAMES the length.
DRIVER = r"""
#include <cstdio>
#include <vector>
#include "generated.h"

int main()
{
    MAIN dsp;
    dsp.initialise (1, 48000.0);
    std::vector<float> in (FRAMES, 0.0f), out (FRAMES, 0.0f);
    in[0] = 1.0f;
    dsp.setInputFrames (MAIN::getEndpointHandleForName ("in"), in.data(), FRAMES, 0);
    dsp.advance (FRAMES);
    dsp.copyOutputFrames (MAIN::getEndpointHandleForName ("out"), out.data(), FRAMES);
    for (float v : out) std::printf ("%.9g\n", v);
}
"""


def programs(args):
    """Yield the .cmajor files to check, as absolute paths, sorted.

    args: files or folders; none means the whole examples/ tree.
    """
    for t in args or [os.path.join(ROOT, "examples")]:
        t = os.path.abspath(t)
        if os.path.isfile(t):
            yield t
            continue
        for d, _, files in sorted(os.walk(t)):
            for f in sorted(files):
                if f.endswith(".cmajor"):
                    yield os.path.join(d, f)


def run(cmd, cwd):
    """Run cmd (a list) in cwd; return its exit status and stdout + stderr."""
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    return r.returncode, r.stdout + r.stderr


def check(path):
    """Check one program; return (number of samples compared, list of problems)."""
    src = open(path, encoding="utf-8").read()
    m = re.search(r"^//\s*impulse:\s*(.*)$", src, re.M)
    if not m:
        return 0, ["no `// impulse:` line"]
    expected = [float(v) for v in m.group(1).split()]
    m = re.search(r"\b(?:graph|processor)\s+(\w+)\s*\[\[\s*main\s*\]\]", src)
    if not m:
        return 0, ["no processor or graph marked [[ main ]]"]
    main = m.group(1)
    with tempfile.TemporaryDirectory() as d:
        name = os.path.basename(path)
        with open(os.path.join(d, name), "w", encoding="utf-8") as f:
            f.write(src)
        # cmaj compiles a patch: a manifest that names the source file.
        with open(os.path.join(d, "check.cmajorpatch"), "w", encoding="utf-8") as f:
            f.write('{ "CmajorVersion": 1, "ID": "tutorial.check", "version": "1.0", '
                    f'"name": "check", "source": ["{name}"] }}\n')
        rc, out = run([CMAJ, "generate", "--target=cpp", "--output=generated.h", "check.cmajorpatch"], d)
        if rc != 0 or "error:" in out or not os.path.exists(os.path.join(d, "generated.h")):
            return 0, ["cmaj:\n" + out.replace(d + "/", "").strip()]
        with open(os.path.join(d, "driver.cpp"), "w", encoding="utf-8") as f:
            f.write(DRIVER)
        rc, out = run([CXX, "-std=c++17", "-O1", "-w", f"-DMAIN={main}", f"-DFRAMES={len(expected)}",
                       "driver.cpp", "-o", "driver"], d)
        if rc != 0:
            return 0, ["C++ compiler:\n" + out.strip()]
        rc, out = run([os.path.join(d, "driver")], d)
        if rc != 0:
            return 0, [f"the program stopped with status {rc}\n{out.strip()}"]
    got = [float(v) for v in out.split()]
    problems = [f"sample {n}: {g!r}, expected {e!r}"
                for n, (g, e) in enumerate(zip(got, expected)) if abs(g - e) > TOLERANCE]
    if len(got) != len(expected):
        problems.append(f"{len(got)} samples rendered, {len(expected)} expected")
    return len(expected), problems


def main():
    """Check the programs named on the command line; return the exit status."""
    failures = count = 0
    for path in programs(sys.argv[1:]):
        count += 1
        rel = os.path.relpath(path, ROOT)
        n, problems = check(path)
        if problems:
            failures += 1
            print(f"FAIL  {rel}")
            for p in problems:
                print("    " + p.replace("\n", "\n    "))
        else:
            print(f"ok    {rel} ({n} samples)")
    print(f"\n{count - failures}/{count} Cmajor programs checked")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
