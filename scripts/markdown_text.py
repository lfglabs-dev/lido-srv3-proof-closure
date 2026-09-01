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

Every pass only deletes characters that render as nothing, so a qualification
can vanish from this view but can never be invented in it: the failure direction
is a real disclosure reported missing, never a missing one reported present.
Where the scan cannot find a close, no link is formed and the text is left
exactly as it is -- which is also what CommonMark does with it.
"""

from __future__ import annotations

import re

# `[label]: destination "title"` is metadata; it renders as nothing at all.  The
# leading `>` markers are matched so a definition inside a block quote is
# removed too, which is where a headline qualification would be hidden.
LINK_REFERENCE_DEFINITION = re.compile(
    r"^(?:[^\S\n]*>)*[^\S\n]* {0,3}\[(?:[^\[\]\n]|\\.)*\][^\S\n]*:[^\n]*\n?",
    re.MULTILINE,
)

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
