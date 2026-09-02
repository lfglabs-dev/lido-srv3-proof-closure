#!/usr/bin/env python3
r"""Reduce Markdown to the text a reader is actually shown.

A link's destination and title render as nothing: only its label is printed.  A
gate that searches raw Markdown for a required sentence therefore accepts one
hidden in a title, and a gate that searches for a banned one misses it there.

Removing that metadata with ``\[([^\[\]]*)\]\([^)]*\)`` stopped at the first
``)``, and a CommonMark destination may carry balanced parentheses: in
``[details](foo(bar) "not about a deployed contract; 67 in total")`` the pattern
consumed ``foo(bar`` and left the title standing as ordinary text, so a headline
that renders only the word "details" satisfied a check for both qualifications.
The destination and title are scanned here instead, honouring balanced
parentheses, backslash escapes and all three title delimiters.

An element body is the same hiding place one construct along.  Deleting the
tags of ``<script>TopUpGateway CLValidatorVerifier</script>`` and keeping their
body left a pairing no browser draws standing in this view as ordinary prose,
so ``rendered_text`` removes such an element whole -- see
``NON_RENDERED_ELEMENTS`` for which bodies a reader is not shown, and why.

Every pass only deletes characters that render as nothing, so a qualification
can vanish from this view but can never be invented in it: the failure direction
is a real disclosure reported missing, never a missing one reported present.
Where the scan cannot find a close, no link is formed and the text is left
exactly as it is -- which is also what CommonMark does with it.  An unclosed
non-rendered element runs the other way, to the end of the text, because that is
what a browser does with it and it is the same safe direction.
"""

from __future__ import annotations

import re
from functools import lru_cache
from html import unescape

# `[label]: destination "title"` is metadata; it renders as nothing at all.  The
# leading `>` markers are matched so a definition inside a block quote is
# removed too, which is where a headline qualification would be hidden.
LINK_REFERENCE_DEFINITION = re.compile(
    r"^(?:[^\S\n]*>)*[^\S\n]* {0,3}\[(?:[^\[\]\n]|\\.)*\][^\S\n]*:[^\n]*\n?",
    re.MULTILINE,
)

# A complete HTML tag, spelled tightly enough that ordinary prose carrying a
# `<` is not mistaken for one: a name, then attributes, then the close.  A loose
# `<[^>]*>` would eat from `a < b` to the next `>` and delete text a reader sees.
HTML_ATTRIBUTE = (
    r"""(?:\s+[A-Za-z_:][A-Za-z0-9_.:-]*"""
    r"""(?:\s*=\s*(?:[^\s"'=<>`]+|'[^']*'|"[^"]*"))?)"""
)
INLINE_HTML_TAG = re.compile(
    rf"<[A-Za-z][A-Za-z0-9-]*{HTML_ATTRIBUTE}*\s*/?>|</[A-Za-z][A-Za-z0-9-]*\s*>")

# Removing a tag is not removing an element: `<script>TopUpGateway
# CLValidatorVerifier</script>` published its pairing to no reader at all, and
# deleting only the two tags left the body standing as if it were prose, so a
# gate reading this view still found the pairing a browser never draws.  The
# body of such an element goes with its tags.
#
# Membership follows the same one-sided rule as the rest of this module: an
# element is on the list when there is a rendering in which a reader does not
# meet its body as page prose, and off it only when every rendering shows that
# body.  `script` and `style` are raw text a browser never paints, `title` is
# document metadata, `template` content is inert by specification,
# `iframe`/`noembed`/`noframes` bodies are fallback shown only where the embed
# is not, and a `textarea` body is a form control's editable default rather
# than published prose.
#
# That GFM's tagfilter escapes several of them -- so GitHub prints `<script>`
# and its body as ordinary characters -- does not take one off the list.  It
# means only that the deletion is sometimes unnecessary, and an unnecessary
# deletion reports a claim missing.  `xmp` and `plaintext` are the two the rule
# excludes, because no rendering hides them: the tagfilter escapes them and a
# browser that honours them paints their bodies as preformatted text, so
# deleting one could only drop text a reader is plainly shown.
#
# The one place this still reads more than it should is a code span or fence
# quoting one of these openers: `<script>` written to be *read* opens a span
# here.  That too costs a required claim reported missing, which an author sees
# and rewords -- never a missing claim reported present -- and neither surface
# this reducer is asked about quotes one.
NON_RENDERED_ELEMENTS = (
    "script",
    "style",
    "textarea",
    "title",
    "template",
    "iframe",
    "noembed",
    "noframes",
)

# `<scriptx>` is a different element, so the name may not run on.  An open tag
# is not scanned for quoting: an attribute value carrying `>` closes the tag
# early here, which only moves the start of a span that is deleted either way.
# An open tag with no `>` at all reaches `\Z`, because a browser reads the rest
# of the document as part of that tag and shows none of it.
_NAME_END = r"(?![A-Za-z0-9-])"
_OPEN_TAG = rf"<{{name}}{_NAME_END}[^>]*(?:>|\Z)"
_CLOSE_TAG = rf"</{{name}}{_NAME_END}[^>]*>"


@lru_cache(maxsize=None)
def _openers(names: tuple) -> re.Pattern[str]:
    """One pattern matching the open tag of any element in ``names``."""
    return re.compile(_OPEN_TAG.format(name=f"(?P<name>{'|'.join(names)})"),
                      re.IGNORECASE)


@lru_cache(maxsize=None)
def _closer(name: str) -> re.Pattern[str]:
    """The end tag of an element named ``name``."""
    return re.compile(_CLOSE_TAG.format(name=name), re.IGNORECASE)


def non_rendered_spans(text: str, elements=None) -> list[tuple[int, int]]:
    """Half-open ``(start, stop)`` slices whose characters render as nothing.

    Each slice runs from an open tag to the *last* end tag of the same name,
    or to the end of the text where there is none, and then grows until nothing
    opened inside it reaches past it.  Spans never overlap and are returned in
    source order, so a caller may delete them or blank them in place.

    Taking the last end tag rather than the first is deliberate, and it is the
    only reading that keeps this pass one-sided.  Where an element's body ends
    is not something a regular scan can decide faithfully: a `template` holds
    ordinary markup and nests, a comment or a raw-text child inside one carries
    an outer end tag as text rather than as a tag, and HTML's own script
    double-escape lets `<script><!--<script>x</script>-->` run past an end tag
    that looks like the close.  Each of those hid a sentence behind an end tag
    the scan stopped at.  A maximal span cannot do that: a body can never
    partly survive, only more than a body be removed.  What that costs is two
    elements of the same name binding one span together, so prose between them
    is read as hidden -- a claim reported missing, which fails closed, and
    which no surface read here exercises.

    ``elements`` defaults to ``NON_RENDERED_ELEMENTS``, which answers the
    membership question for a Markdown page.  A caller reading a different
    surface passes its own names, because the answer is not the same
    everywhere: in SVG a ``<title>`` is the hover tooltip a reader is shown,
    not the document metadata it is in an HTML ``<head>``.
    """
    names = tuple(NON_RENDERED_ELEMENTS if elements is None
                  else (name.lower() for name in elements))
    if not names:
        return []
    end = len(text)
    openers = list(_openers(names).finditer(text))
    if not openers:
        return []
    # An element's end tag, if it has one, is the last of its name in the whole
    # text; anything earlier cannot close a body that starts after it.  Looking
    # each name up once keeps this pass linear -- rescanning per open tag made
    # a document of five thousand elements take eighteen seconds.
    final = {}
    for name in names:
        found = list(_closer(name).finditer(text))
        final[name] = found[-1] if found else None

    def reach(match) -> int:
        """Where the element opened by ``match`` can no longer be running."""
        close = final[match.group("name").lower()]
        return close.end() if close is not None and close.start() >= match.end() else end

    spans: list[tuple[int, int]] = []
    index = 0
    while index < len(openers):
        stop = reach(openers[index])
        # An element opened *inside* this one is inside its body, so the body
        # cannot end before that element does: `<template><script>x</template>`
        # closes no template a browser recognises, because the `</template>` is
        # script text.  The span absorbs each open tag it covers, and the test
        # is re-read as it grows, so one absorbed late is absorbed too.
        following = index + 1
        while following < len(openers) and openers[following].start() < stop:
            stop = max(stop, reach(openers[following]))
            following += 1
        spans.append((openers[index].start(), stop))
        index = following
    return spans


def strip_non_rendered_elements(text: str, elements=None) -> str:
    """``text`` with every non-rendered element collapsed to a single space."""
    out: list[str] = []
    cursor = 0
    for start, stop in non_rendered_spans(text, elements):
        out.append(text[cursor:start])
        out.append(" ")
        cursor = stop
    out.append(text[cursor:])
    return "".join(out)


# An inline link may not span a blank line, so a scan that reaches one has not
# found a link and must not consume the text past it.
_BLANK_LINE = re.compile(r"\n[ \t]*\n")

# A label may nest brackets and a destination may nest parentheses, so one pass
# can expose another link that was inside a label.  The loop is bounded because
# each pass that changes anything deletes at least one character.
_MAX_PASSES = 8


def _matching_bracket(text: str, start: int) -> int:
    """Index of the ``]`` closing the label opened at ``start``, or -1."""
    depth = 0
    index = start
    end = len(text)
    while index < end:
        char = text[index]
        if char == "\\" and index + 1 < end:
            index += 2
            continue
        if char == "[":
            depth += 1
        elif char == "]":
            depth -= 1
            if depth == 0:
                return index
        elif char == "\n" and _BLANK_LINE.match(text, index):
            return -1
        index += 1
    return -1


def _closing_parenthesis(text: str, start: int) -> int:
    """Index just past the ``)`` closing the inline link opened at ``start``.

    ``start`` is the offset of the ``(``.  Parentheses nest, a backslash escapes
    the character after it, and a title in ``"``, ``'`` or ``(`` delimiters may
    hold unbalanced parentheses of its own, so each is tracked rather than
    counted.  Returns -1 when no close is reached before the paragraph ends,
    which is also when CommonMark forms no link.
    """
    index = start + 1
    depth = 1
    end = len(text)
    # A destination written `<…>` holds its parentheses literally, so the run to
    # the closing `>` is skipped before the balance is counted.  Counting inside
    # it left `[details](<foo(bar> "…")` looking unbalanced, so no link was
    # recognised and the title stayed in the text as if a reader saw it.
    while index < end and text[index] in " \t":
        index += 1
    if index < end and text[index] == "<":
        index += 1
        while index < end and text[index] not in ">\n":
            index += 2 if text[index] == "\\" and index + 1 < end else 1
        if index >= end or text[index] == "\n":
            return -1
        index += 1
    while index < end:
        char = text[index]
        if char == "\\" and index + 1 < end:
            index += 2
            continue
        if char in "\"'":
            index += 1
            while index < end:
                if text[index] == "\\" and index + 1 < end:
                    index += 2
                    continue
                if text[index] == char:
                    index += 1
                    break
                if text[index] == "\n" and _BLANK_LINE.match(text, index):
                    return -1
                index += 1
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index + 1
        elif char == "\n" and _BLANK_LINE.match(text, index):
            return -1
        index += 1
    return -1


def _strip_inline_links(text: str) -> str:
    out: list[str] = []
    index = 0
    end = len(text)
    while index < end:
        char = text[index]
        if char == "\\" and index + 1 < end:
            out.append(text[index:index + 2])
            index += 2
            continue
        if char == "[":
            close = _matching_bracket(text, index)
            if close != -1 and text[close + 1:close + 2] == "(":
                after = _closing_parenthesis(text, close + 1)
                if after != -1:
                    # The label is what a reader is shown; the destination and
                    # the title are not.
                    out.append(text[index + 1:close])
                    index = after
                    continue
            if close != -1 and text[close + 1:close + 2] == "[":
                # A full or collapsed reference link, `[label][ref]` or
                # `[label][]`.  The second group names a definition and renders
                # as nothing, so recognising only the `(` form left the whole
                # sentence hidden in `[details][not about a deployed contract;
                # 67 in total]` standing as if a reader met it.  CommonMark
                # allows no space between the two groups, so only an immediately
                # following `[` is one.
                reference = _matching_bracket(text, close + 1)
                if reference != -1:
                    out.append(text[index + 1:close])
                    index = reference + 1
                    continue
        out.append(char)
        index += 1
    return "".join(out)


def visible_text(text: str) -> str:
    """``text`` with the link metadata a reader never meets removed."""
    text = LINK_REFERENCE_DEFINITION.sub("", text)
    for _ in range(_MAX_PASSES):
        reduced = _strip_inline_links(text)
        if reduced == text:
            break
        text = reduced
    return text


def rendered_text(text: str) -> str:
    """``text`` reduced to what a reader is shown, inline HTML included.

    An attribute is markup, not content: `<span title="…">visible</span>` shows
    the word "visible" and nothing else, so prose checked as raw Markdown
    accepted a claim written into a `title=` and missed a banned one written
    there.  A body can be markup too: `<script>…</script>` shows nothing at all,
    so the non-rendered elements are removed whole before anything else reads
    the text -- ahead of the link pass, so that deleting a destination or a
    title can never move an element boundary.  Tags collapse to a space rather
    than to nothing, because two separately marked-up runs sit adjacent in the
    source without being one word on the page, and character references are
    decoded because `&#84;` is punctuation to a pattern and a letter to a
    reader.
    """
    return unescape(
        INLINE_HTML_TAG.sub(" ", visible_text(strip_non_rendered_elements(text))))
