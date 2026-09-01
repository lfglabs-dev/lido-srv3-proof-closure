#!/usr/bin/env python3
r"""Pinned cases for the shared link-metadata reducer.

Every case is a fixed string with a fixed expected reduction.  The rejecting
half is what a gate must no longer find -- a sentence carried where a reader
never meets it -- and the accepting half is what it must still find, because a
reducer that deletes visible text would reject a document a reader plainly sees
and no edit could satisfy the gate.
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import markdown_text  # noqa: E402  (sibling module, located above)

HIDDEN = "not about a deployed contract"

# (source, expected reduction).  The sentence must survive exactly where a
# reader is shown it, and must not survive anywhere else.
CASES = (
    # A destination and a title render as nothing, in each title delimiter.
    (f'[details](target "{HIDDEN}")', "details"),
    (f"[details](target '{HIDDEN}')", "details"),
    (f"[details](target ({HIDDEN}))", "details"),
    # The certified shape: a destination may carry balanced parentheses, so a
    # pattern that stopped at the first `)` left the title behind as text.
    (f'[details](foo(bar) "{HIDDEN}")', "details"),
    (f'[details](foo(bar(baz)) "{HIDDEN}")', "details"),
    # And an angle-bracketed destination holds its parentheses literally, so
    # counting them there found no close and left the title behind too.
    (f'[details](<foo(bar> "{HIDDEN}")', "details"),
    (f'[details](<foo bar> "{HIDDEN}")', "details"),
    # A title may hold the delimiter of another kind, and an escaped one of its
    # own, without ending early.
    (f"""[details](target "{HIDDEN} ' )")""", "details"),
    (f'[details](target "{HIDDEN} \\" still title")', "details"),
    # A label may nest a link, so one pass can expose another.
    (f'[outer [inner](u "{HIDDEN}") label](v)', "outer inner label"),
    # A reference definition renders as nothing at the start of its own line,
    # inside a block quote as well.
    (f'[note]: http://example.com "{HIDDEN}"\n', ""),
    (f'> [note]: http://example.com "{HIDDEN}"\n', ""),
    # An image's alt text is shown; its destination and title are not.
    (f'![alt text](img.png "{HIDDEN}")', "!alt text"),
    # What a reader is shown must survive: the label, and any text beside it.
    (f"[{HIDDEN}](target)", HIDDEN),
    (f'[{HIDDEN}](foo(bar) "hidden")', HIDDEN),
    (f'The evidence is {HIDDEN}. [see](foo(bar) "hidden")',
     "The evidence is not about a deployed contract. see"),
    # No link forms without a close, so CommonMark shows the characters and so
    # does this reducer.
    (f'[details](foo "{HIDDEN}', f'[details](foo "{HIDDEN}'),
    (f'[details](foo\n\n{HIDDEN}', f'[details](foo\n\n{HIDDEN}'),
    (f'[details]\n\n(target "{HIDDEN}")', f'[details]\n\n(target "{HIDDEN}")'),
    # A definition written mid-sentence is not a definition; it is literal text.
    (f'prose [note]: target "{HIDDEN}"\n', f'prose [note]: target "{HIDDEN}"\n'),
    # An escaped bracket opens no label.
    (f'\\[details](target "{HIDDEN}")', f'\\[details](target "{HIDDEN}")'),
    # Text with no link at all is returned unchanged.
    (f"plain {HIDDEN} prose", f"plain {HIDDEN} prose"),
)


def main():
    concealed = 0
    for source, expected in CASES:
        actual = markdown_text.visible_text(source)
        if actual != expected:
            raise SystemExit(
                f"markdown text: visible_text({source!r})\n  = {actual!r}\n  want {expected!r}")
        if HIDDEN in source and HIDDEN not in actual:
            concealed += 1
    shown = sum(1 for source, _ in CASES if HIDDEN in markdown_text.visible_text(source))
    if concealed < 12 or shown < 6:
        raise SystemExit(f"markdown text: implausible case split "
                         f"({concealed} concealed, {shown} shown)")
    print(f"markdown text reducer ok: {len(CASES)} pinned cases, {concealed} shapes that "
          f"publish the sentence to no reader and {shown} that do")


if __name__ == "__main__":
    main()
