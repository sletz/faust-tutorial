#!/usr/bin/env python3
"""Check every program of the tutorial.

For each .dsp file under examples/:

1. the C++ Faust compiler must compile it (unless it has a `// cpp: no`
   line, kept for the faust-rs extensions);
2. faustprobe must compile and render it (one frame, zero input);
3. each `// check: ARGS` line runs `faustprobe ARGS file.dsp`, which must
   succeed (exit status 0); each `// expect: REGEX` line that follows must
   match its output (stdout and stderr together, one line at a time for
   `^` and `$`). The command runs in the file's folder, so that
   `--compare other.dsp` works. A `// check-fails: ARGS` line expects a
   failure instead;
4. a file marked `// expect-error` shows an error: both compilers must
   reject it, and each `// expect:` line placed before any `check` line
   must match faustprobe's message;
5. `// cpp-expect: REGEX` and `// cpp-absent: REGEX` lines must, and must
   not, match the C++ code that `faust` generates for the file;
6. a file with a `// faust-rs: no` line is checked with the C++ compiler
   only (for a construct faust-rs does not handle yet; the line says why).

Environment: FAUST, FAUSTPROBE, FAUSTLIBRARIES.
Arguments: files or folders to restrict the check to.
"""
import os
import re
import shlex
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAUST = os.environ.get("FAUST", "faust")
FAUSTPROBE = os.environ.get("FAUSTPROBE", os.path.join(ROOT, "..", "faust-rs", "target", "release", "faustprobe"))
LIBS = os.path.abspath(os.environ.get("FAUSTLIBRARIES", os.path.join(ROOT, "..", "..", "faustlibraries")))
FAUSTPROBE = os.path.abspath(FAUSTPROBE) if os.sep in FAUSTPROBE else FAUSTPROBE


def programs(args):
    targets = args or [os.path.join(ROOT, "examples")]
    for t in targets:
        t = os.path.abspath(t)
        if os.path.isfile(t):
            yield t
            continue
        for d, _, files in sorted(os.walk(t)):
            for f in sorted(files):
                if f.endswith(".dsp"):
                    yield os.path.join(d, f)


def directives(path):
    checks = []
    cpp = True
    error = None
    cpp_expect, cpp_absent = [], []
    probe = True
    for line in open(path, encoding="utf-8"):
        s = line.strip()
        if s.startswith("// cpp: no"):
            cpp = False
        if s.startswith("// faust-rs: no"):
            probe = False
        if s.startswith("// expect-error"):
            error = []
            continue
        m = re.match(r"//\s*cpp-(expect|absent):\s*(.*)$", s)
        if m:
            (cpp_expect if m.group(1) == "expect" else cpp_absent).append(m.group(2))
            continue
        m = re.match(r"//\s*(check|check-fails):\s*(.*)$", s)
        if m:
            checks.append({"fails": m.group(1) == "check-fails", "args": shlex.split(m.group(2)), "expect": []})
            continue
        m = re.match(r"//\s*expect:\s*(.*)$", s)
        if m and checks:
            checks[-1]["expect"].append(m.group(1))
        elif m and error is not None:
            error.append(m.group(1))
    return cpp, checks, error, cpp_expect, cpp_absent, probe


def run(cmd, cwd=None):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    return r.returncode, r.stdout + r.stderr


def shorten(out, head=20, tail=8):
    lines = out.splitlines()
    if len(lines) <= head + tail + 1:
        return out
    return "\n".join(lines[:head] + [f"... ({len(lines) - head - tail} lines)"] + lines[-tail:])


def main():
    failures = 0
    count = 0
    for path in programs(sys.argv[1:]):
        count += 1
        rel = os.path.relpath(path, ROOT)
        inc = ["-I", os.path.dirname(path), "-I", LIBS]
        cpp, checks, error, cpp_expect, cpp_absent, probe = directives(path)
        if not probe:
            checks = []
        problems = []
        if error is not None:
            rc, out = run([FAUST, *inc, path, "-o", os.devnull])
            if rc == 0:
                problems.append("faust C++ accepted a program marked expect-error")
            rc, out = run([FAUSTPROBE, "--double", *inc, "-n", "1", "--in", "zero", "--quiet", path])
            if rc == 0:
                problems.append("faustprobe accepted a program marked expect-error")
            for e in error:
                if not re.search(e, out, re.MULTILINE):
                    problems.append(f"error message: {e!r} not found in\n{out}")
            checks = []
            cpp = None
        if cpp:
            rc, out = run([FAUST, *inc, path])
            if rc != 0:
                problems.append("faust C++:\n" + shorten(out))
            else:
                for e in cpp_expect:
                    if not re.search(e, out, re.MULTILINE):
                        problems.append(f"cpp-expect {e!r} not found in the generated C++")
                for e in cpp_absent:
                    if re.search(e, out, re.MULTILINE):
                        problems.append(f"cpp-absent {e!r} found in the generated C++")
        if cpp is not None and probe:
            rc, out = run([FAUSTPROBE, "--double", *inc, "-n", "1", "--in", "zero", "--quiet", path])
            if rc != 0:
                problems.append("faustprobe (compile):\n" + out)
        for c in checks:
            rc, out = run([FAUSTPROBE, *inc, *c["args"], path], cwd=os.path.dirname(path))
            what = " ".join(c["args"])
            if c["fails"] and rc == 0:
                problems.append(f"check-fails {what}: succeeded")
            elif not c["fails"] and rc != 0:
                problems.append(f"check {what}: exit status {rc}\n{shorten(out)}")
            for e in c["expect"]:
                if not re.search(e, out, re.MULTILINE):
                    problems.append(f"check {what}: {e!r} not found in\n{shorten(out)}")
        if problems:
            failures += 1
            print(f"FAIL  {rel}")
            for p in problems:
                print("    " + p.replace("\n", "\n    ").rstrip())
        else:
            note = "" if probe else ", C++ only"
            print(f"ok    {rel} ({len(checks)} check{'s' if len(checks) != 1 else ''}{note})")
    print(f"\n{count - failures}/{count} programs checked")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
