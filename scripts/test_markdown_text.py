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
    # A full or collapsed reference link names a definition in its second
    # group, which renders as nothing; recognising only the `(` form left the
    # whole sentence standing in `[details][…]` as if a reader met it.
    (f"[details][{HIDDEN}]", "details"),
    (f"[{HIDDEN}][]", HIDDEN),
    (f"[details][{HIDDEN}] and [more][{HIDDEN}]", "details and more"),
    # A shortcut reference renders its own label, so there is nothing to remove.
    (f"[{HIDDEN}]", f"[{HIDDEN}]"),
)

# `rendered_text` goes one construct further: inline HTML is markup, and an
# attribute is never shown.  Character references are decoded, because `&#84;`
# is punctuation to a pattern and a letter to a reader.
RENDERED_CASES = (
    (f'<span title="{HIDDEN}">visible</span>', "visible"),
    (f"<img alt='{HIDDEN}' src='x.png'>", ""),
    (f'<a href="u" data-note="{HIDDEN}">shown</a>', "shown"),
    (f"prose {HIDDEN} prose", f"prose {HIDDEN} prose"),
    ("&#84;opUpGateway", "TopUpGateway"),
    # Prose carrying a bare `<` is not a tag; a loose `<[^>]*>` would eat to the
    # next `>` and delete text a reader sees.
    (f"a < b and {HIDDEN} > c", f"a < b and {HIDDEN} > c"),
)


# Thread r3909473219: removing a tag is not removing an element.  A required
# taxonomy claim written into `<script>…</script>` reached this view intact
# while a browser drew none of it, so the gate it feeds reported a pairing that
# was published to nobody.  The body of a non-rendered element is removed with
# its tags, and the controls beside each case pin the boundary of that rule:
# over-reading it would delete text a reader is plainly shown, and no edit to
# the document could then satisfy the gate.
NON_RENDERED_CASES = (
    # One entry per element the reducer holds to be non-rendered, so an element
    # the suite never exercises cannot carry a claim the day it is used.
    (f"<script>{HIDDEN}</script>", ""),
    (f"<style>/* {HIDDEN} */</style>", ""),
    (f"<template>{HIDDEN}</template>", ""),
    (f"<textarea>{HIDDEN}</textarea>", ""),
    (f"<title>{HIDDEN}</title>", ""),
    (f'<iframe src="x">{HIDDEN}</iframe>', ""),
    (f"<noembed>{HIDDEN}</noembed>", ""),
    (f"<noframes>{HIDDEN}</noframes>", ""),
    # The open tag is a tag, not a bare name: attributes, an ignored solidus and
    # either casing all still open the element.
    (f'<script type="text/javascript">{HIDDEN}</script>', ""),
    (f"<SCRIPT>{HIDDEN}</SCRIPT>", ""),
    (f"<script/>{HIDDEN}</script>", ""),
    (f'<script data-note="a>b">{HIDDEN}</script>', ""),
    (f'<script>{HIDDEN}</script foo="bar">', ""),
    # An element that never closes runs to the end of the text, which is what a
    # browser shows of it: nothing.
    (f"<script>{HIDDEN}", ""),
    (f"<script data-note='unterminated {HIDDEN}", ""),
    # `template` content is ordinary markup, so an inner opener opens a real
    # element and the outer body runs past the inner close.  Stopping at the
    # first `</template>` left the sentence after it standing.
    (f"<template><template>inner</template>{HIDDEN}</template>", ""),
    # The body is removed before the link pass, so link syntax inside it cannot
    # rewrite the boundary that decides what is deleted.
    (f"<script>[{HIDDEN}](target)</script>", ""),
    (f'<script>[note]: target "{HIDDEN}"</script>', ""),
    # The three shapes that put a sentence behind an end tag a scan stops at,
    # and the reason the span runs to the *last* close instead of the first.
    # A raw-text child carries the outer end tag as text, not as a tag:
    # `</template>` here is script content and closes no template.
    (f"<template><script>x</template>{HIDDEN}</script>", ""),
    # A comment inside the body does the same.
    (f"<template><!-- </template> -->{HIDDEN}</template>", ""),
    # And HTML's own script double-escape runs past an end tag that looks like
    # the close.
    (f"<script><!--<script>x</script>-->{HIDDEN}</script>", ""),
    # Two elements of the same name therefore bind one span, and the prose
    # between them is read as hidden.  That is the cost of the rule, and it is
    # the direction that reports a claim missing rather than present.
    (f"<script>a</script> {HIDDEN} <script>b</script>", ""),

    # --- controls: every case below is text a reader is shown -----------------
    # The span is bounded: prose before the open tag and after the close is on
    # the page and must survive.
    (f"{HIDDEN} <script>note</script>", HIDDEN),
    (f"<script>note</script> {HIDDEN}", HIDDEN),
    # Two different names bound their own spans and do not join.
    (f"<script>a</script> {HIDDEN} <style>b</style>", HIDDEN),
    # The name may not run on -- `<scriptx>` and `<script-note>` are other
    # elements entirely, and their bodies render.
    (f"<scriptx>{HIDDEN}</scriptx>", HIDDEN),
    (f"<script-note>{HIDDEN}</script-note>", HIDDEN),
    # `xmp` and `plaintext` are in GFM's tagfilter but a browser paints their
    # bodies, so they are deliberately not on the list.
    (f"<xmp>{HIDDEN}</xmp>", HIDDEN),
    (f"<plaintext>{HIDDEN}", HIDDEN),
    # A rendered element's body is content; only its tags and attributes are not.
    (f'<span title="markup">{HIDDEN}</span>', HIDDEN),
    # And the element names in ordinary prose open nothing.
    (f"a script or style template for {HIDDEN}",
     f"a script or style template for {HIDDEN}"),
)


def check_non_rendered():
    concealed = shown = 0
    for source, expected in NON_RENDERED_CASES:
        actual = " ".join(markdown_text.rendered_text(source).split())
        if actual != " ".join(expected.split()):
            raise SystemExit(
                f"markdown text: rendered_text({source!r})\n  = {actual!r}\n"
                f"  want {expected!r}")
        if HIDDEN in actual:
            shown += 1
        else:
            concealed += 1
    if concealed < 22 or shown < 9:
        raise SystemExit(f"markdown text: implausible non-rendered case split "
                         f"({concealed} concealed, {shown} shown)")
    # Every element on the list must be exercised, so one added later arrives
    # with its adversarial case already demanded.
    for name in markdown_text.NON_RENDERED_ELEMENTS:
        if not any(f"<{name}" in source for source, _ in NON_RENDERED_CASES):
            raise SystemExit(f"markdown text: no case hides a claim in <{name}>")
    return concealed, shown


def check_rendered():
    for source, expected in RENDERED_CASES:
        actual = " ".join(markdown_text.rendered_text(source).split())
        if actual != " ".join(expected.split()):
            raise SystemExit(
                f"markdown text: rendered_text({source!r})\n  = {actual!r}\n"
                f"  want {expected!r}")


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
    check_rendered()
    buried, drawn = check_non_rendered()
    print(f"markdown text reducer ok: {len(CASES)} pinned cases, {concealed} shapes that "
          f"publish the sentence to no reader and {shown} that do; "
          f"{len(RENDERED_CASES)} inline-HTML cases where an attribute is markup and "
          f"a bare `<` is not a tag; {len(NON_RENDERED_CASES)} element-body cases over "
          f"{len(markdown_text.NON_RENDERED_ELEMENTS)} non-rendered elements, {buried} "
          f"bodies a reader never meets and {drawn} controls a reader plainly does")


if __name__ == "__main__":
    main()
