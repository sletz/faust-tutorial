#!/usr/bin/env python3
"""Build the mkdocs sources of the tutorial's web site in build/docs.

Usage
-----

    python3 scripts/build_docs.py

or, from the top of the repository, `make docs` (this script alone),
`make site` (this script, then `mkdocs build --strict` into site/) and
`make serve` (this script, then `mkdocs serve` at http://127.0.0.1:8000).
mkdocs.yml, at the top of the repository, holds the navigation, the theme and
the faust-web-component script (loaded from jsDelivr).

Environment:

    FAUST           the C++ Faust compiler that draws the diagrams (default `faust`)
    FAUSTLIBRARIES  the standard libraries (default ../../faustlibraries)

What it does
------------

The chapters stay plain Markdown that reads on GitHub, where each program is
a link to its file. For the site, the script writes build/docs (erased first):

    index.md            README.md
    PLAN.md             PLAN.md
    chapters/*.md       the chapters, with the programs inserted (below)
    examples/           a copy of examples/, so that the links still work,
                        plus one NAME-svg/ folder of diagrams per program
    css/                the contents of web/ (the style of the programs)
    scripts/check.py    linked to from appendix A

Every program a chapter links to (`](../examples/NN/name.dsp)`) is shown
once, at its first mention, as in faustdoc: its path, its block diagram
drawn by `faust -svg` (a link opens it at full size, where each box opens
its own diagram) and a <faust-editor> element, which compiles the program
with the Faust compiler built into faust-web-component and plays it in the
browser, with its controls. The program is shown without the checker's
directive lines (`// check:`, `// expect:`, ...; see scripts/check.py).

Where it goes:

- after the paragraph that cites it;
- or, when that paragraph is followed by a code block (the usual
  "([`name.dsp`](...)):" then the code), after that code block; when the
  code block is the whole program (comments and blank lines aside), the
  editor replaces it;
- after the whole list, when it is cited in a list (an exercise), since HTML
  inside a list item would break the list.

Three kinds of program are not simply run:

- `// cpp: no`: a faust-rs extension (fad, rad), which the C++ compiler of
  the browser does not know. Shown as code with a note, no diagram.
- a program that imports the tutorial's own library (tutorial.lib,
  tutorial_v2.lib): the browser only has the standard libraries. Shown with
  its diagram and as code, with a note.
- `// expect-error`: a program that must not compile. It gets an editor,
  which shows the error, and no diagram.

A program whose diagrams exceed MAX_SVG_BYTES (thousands of folded boxes,
one file each) keeps only its top-level diagram, without links.

The diagrams are drawn by the local C++ compiler with FAUSTLIBRARIES; the
editor compiles with the compiler and libraries bundled in
faust-web-component, which can be older.
"""

import html
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "build", "docs")
FAUST = os.environ.get("FAUST", "faust")
LIBS = os.path.abspath(os.environ.get("FAUSTLIBRARIES", os.path.join(ROOT, "..", "..", "faustlibraries")))

LINK = re.compile(r"\]\((\.\./examples/[^)\s]+\.dsp)\)")
DIRECTIVE = re.compile(r"^\s*//\s*(check|check-fails|expect|cpp-expect|cpp-absent)\s*:|"
                       r"^\s*//\s*(cpp: no|faust-rs: no|expect-error)")
LOCAL_LIB = re.compile(r'(library|import)\("tutorial[^"]*\.lib"\)')
LIST_ITEM = re.compile(r"^\s*([-*+]|\d+\.)\s")
MAX_SVG_BYTES = 2_000_000


def read(path):
    """The contents of a UTF-8 text file."""
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path, text):
    """Write text to path, creating its folders."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


# ---------------------------------------------------------------- programs

def program(dsp):
    """The program as shown on the page: without the checker's directives."""
    lines = [l for l in read(dsp).splitlines() if not DIRECTIVE.match(l)]
    text = "\n".join(lines).strip("\n")
    return re.sub(r"\n{3,}", "\n\n", text)


def kind(dsp):
    """How a program is shown: "run", "error", "faust-rs" or "local-lib" (see the module doc)."""
    src = read(dsp)
    if re.search(r"^\s*//\s*cpp: no", src, re.M):
        return "faust-rs"
    if re.search(r"^\s*//\s*expect-error", src, re.M):
        return "error"
    if LOCAL_LIB.search(src):
        return "local-lib"
    return "run"


def svg(dsp, rel):
    """Draw the block diagram of a program with `faust -svg`.

    dsp: absolute path of the program; rel: its path relative to the
    repository (examples/NN/name.dsp). The diagrams go to
    build/docs/examples/NN/name-svg/, whose process.svg is the top level.
    Returns the path of that process.svg relative to build/docs, or None
    when the compiler fails (the page then shows no diagram).
    """
    name = os.path.splitext(os.path.basename(dsp))[0]
    outdir = os.path.join(OUT, os.path.dirname(rel))
    target = os.path.join(outdir, name + "-svg")
    shutil.rmtree(target, ignore_errors=True)
    r = subprocess.run([FAUST, "-svg", "-I", LIBS, "-I", os.path.dirname(dsp), dsp, "-O", outdir],
                       capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(os.path.join(target, "process.svg")):
        shutil.rmtree(target, ignore_errors=True)
        return None
    # A program whose diagram unfolds into thousands of sub-diagrams (one
    # file per folded box) would weigh hundreds of megabytes: keep only its
    # top-level diagram, without the links to the boxes.
    files = os.listdir(target)
    size = sum(os.path.getsize(os.path.join(target, f)) for f in files)
    if size > MAX_SVG_BYTES:
        for f in files:
            if f != "process.svg":
                os.remove(os.path.join(target, f))
        top = os.path.join(target, "process.svg")
        write(top, re.sub(r'<a xlink:href="[^"]*">', "<a>", read(top)))
    # faust -svg also writes the C++ code of the program next to the diagram
    for f in os.listdir(outdir):
        if f.endswith(".cpp"):
            os.remove(os.path.join(outdir, f))
    return os.path.splitext(rel)[0] + "-svg/process.svg"


def normalise(code):
    """Code without comments and blank lines, to tell whether a block is the whole program."""
    out = []
    for l in code.splitlines():
        l = re.sub(r"//.*$", "", l).rstrip()
        if l.strip():
            out.append(l.strip())
    return "\n".join(out)


def embed(link, chapter_dir, svgs):
    """The HTML block that shows one program in a chapter.

    link: the link as written in the chapter (../examples/NN/name.dsp);
    chapter_dir: the folder of the chapter, to resolve it; svgs: the
    diagrams drawn by svg(), by path relative to the repository. Returns
    (html, code), code being the program as shown, for transform() to tell
    whether a code block of the chapter is the whole program.

    The block is <div class="faust-run"> (styled by web/css/faust-run.css)
    with the path, the diagram and either a <faust-editor> whose program is
    inside an HTML comment, as the component expects, or a <pre> with a note.
    """
    dsp = os.path.normpath(os.path.join(chapter_dir, link))
    rel = os.path.relpath(dsp, ROOT)
    k = kind(dsp)
    code = program(dsp)
    parts = ['<div class="faust-run">',
             f'<p class="faust-run-title"><a href="{html.escape(link)}">{html.escape(rel)}</a></p>']
    if k in ("run", "local-lib"):
        s = svgs.get(rel)
        if s:
            href = os.path.relpath(os.path.join(ROOT, s), chapter_dir)
            parts.append(f'<a href="{href}" target="_blank" title="open the diagram (its boxes can be opened)">'
                         f'<img class="faust-diagram" src="{href}" alt="block diagram of {html.escape(rel)}"></a>')
    if k in ("run", "error"):
        if k == "error":
            parts.append('<p class="faust-run-note">This program does not compile, on purpose: '
                         'the editor shows the error.</p>')
        parts.append("<faust-editor><!--")
        parts.append(code)
        parts.append("--></faust-editor>")
    else:
        note = ("It uses <code>fad</code> or <code>rad</code>, extensions of faust-rs that the "
                "C++ compiler of the browser does not know: run it with faust-rs or faustprobe."
                if k == "faust-rs" else
                "It imports the tutorial's own library, which the browser does not have: "
                "run it with a local compiler, next to that library.")
        parts.append(f'<p class="faust-run-note">{note}</p>')
        parts.append(f"<pre><code>{html.escape(code)}</code></pre>")
    parts.append("</div>")
    return "\n".join(parts), code


# ---------------------------------------------------------------- chapters

def blocks(text):
    """Split a chapter into Markdown blocks.

    A block is a fenced code block (kept whole, blank lines included) or a
    run of non-blank lines. Each is a dict: kind ("code", "heading", "list"
    or "para"), indent (True when its first line is indented: a continuation
    of a list item) and lines. Joining the blocks with blank lines gives the
    chapter back, blank lines normalised.
    """
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        if line.lstrip().startswith("```"):
            j = i + 1
            while j < len(lines) and not lines[j].lstrip().startswith("```"):
                j += 1
            out.append({"kind": "code", "indent": line != line.lstrip(), "lines": lines[i:j + 1]})
            i = j + 1
            continue
        j = i
        while j < len(lines) and lines[j].strip() and not lines[j].lstrip().startswith("```"):
            j += 1
        first = lines[i]
        k = "heading" if first.startswith("#") else "list" if LIST_ITEM.match(first) else "para"
        out.append({"kind": k, "indent": first != first.lstrip(), "lines": lines[i:j]})
        i = j
    return out


def in_list(b):
    """True for a list item, or for an indented block that continues one."""
    return b["kind"] == "list" or b["indent"]


def transform(text, chapter_dir, svgs):
    """Return a chapter with its programs inserted (see the module doc for where).

    Programs cited in a block wait in `pending` until the block after which
    they go (`flush_after`) has been copied; several programs cited together
    are inserted together, in the order of their citations.
    """
    bs = blocks(text)
    seen, pending, out = set(), [], []
    flush_after = None          # index of the block after which pending examples go

    for n, b in enumerate(bs):
        body = "\n".join(b["lines"])
        for link in LINK.findall(body):
            if link not in seen:
                seen.add(link)
                pending.append(link)
        if pending and flush_after is None:
            nxt = bs[n + 1] if n + 1 < len(bs) else None
            if b["kind"] == "para" and not b["indent"] and nxt and nxt["kind"] == "code" and not nxt["indent"]:
                flush_after = n + 1
            elif in_list(b):
                m = n
                while m + 1 < len(bs) and in_list(bs[m + 1]):
                    m += 1
                flush_after = m
            else:
                flush_after = n
        out.append(b)
        if flush_after == n:
            rendered = [embed(l, chapter_dir, svgs) for l in pending]
            if b["kind"] == "code":
                block_code = normalise("\n".join(b["lines"][1:-1]))
                if any(block_code and normalise(code) == block_code for _, code in rendered):
                    out.pop()
            out.extend({"kind": "html", "indent": False, "lines": [h]} for h, _ in rendered)
            pending, flush_after = [], None

    return "\n\n".join("\n".join(b["lines"]) for b in out) + "\n"


# ---------------------------------------------------------------- site

def main():
    """Write build/docs: copies, diagrams, pages; print a one-line summary."""
    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(OUT)
    shutil.copytree(os.path.join(ROOT, "examples"), os.path.join(OUT, "examples"))
    shutil.copytree(os.path.join(ROOT, "web"), OUT, dirs_exist_ok=True)
    # appendix A links to the checker
    os.makedirs(os.path.join(OUT, "scripts"))
    shutil.copy(os.path.join(ROOT, "scripts", "check.py"), os.path.join(OUT, "scripts"))

    svgs, failed = {}, []
    for d, _, files in sorted(os.walk(os.path.join(ROOT, "examples"))):
        for f in sorted(files):
            if f.endswith(".dsp"):
                dsp = os.path.join(d, f)
                rel = os.path.relpath(dsp, ROOT)
                if kind(dsp) in ("run", "local-lib"):
                    s = svg(dsp, rel)
                    if s:
                        svgs[rel] = s
                    else:
                        failed.append(rel)

    readme = read(os.path.join(ROOT, "README.md"))
    write(os.path.join(OUT, "index.md"), readme)
    write(os.path.join(OUT, "PLAN.md"), read(os.path.join(ROOT, "PLAN.md")))

    shown = 0
    chapters = os.path.join(ROOT, "chapters")
    for f in sorted(os.listdir(chapters)):
        if f.endswith(".md"):
            text = transform(read(os.path.join(chapters, f)), chapters, svgs)
            text = text.replace("](../README.md)", "](../index.md)")
            shown += text.count('<div class="faust-run">')
            write(os.path.join(OUT, "chapters", f), text)

    print(f"build/docs: {shown} programs shown, {len(svgs)} diagrams"
          + (f", no diagram for {', '.join(failed)}" if failed else ""))


if __name__ == "__main__":
    sys.exit(main())
