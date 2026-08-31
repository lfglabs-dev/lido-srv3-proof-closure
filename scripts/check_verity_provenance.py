#!/usr/bin/env python3
"""Fail-closed agreement check for every canonical Verity revision surface."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from bisect import bisect_left
from pathlib import Path
from typing import NoReturn


VERITY_REPOSITORY = "https://github.com/lfglabs-dev/verity.git"
FULL_REVISION = re.compile(r"[0-9a-f]{40}")


def fail(message: str) -> NoReturn:
    raise ValueError(message)


def strict_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            fail(f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def load_json(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=strict_object)
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"{path} must contain one JSON object")
    return value


def _escaped_at(text: str, i: int) -> bool:
    """CommonMark §2.4: a character preceded by an odd backslash run is literal."""
    num_bs = 0
    p = i - 1
    while p >= 0 and text[p] == "\\":
        num_bs += 1
        p -= 1
    return num_bs % 2 == 1


# CommonMark leaf-block starters that interrupt a paragraph without a blank line.
# Only unambiguous forms are listed: list items (whose interruption rules are
# conditional) and setext underlines (which depend on the preceding line) are
# deliberately omitted.  Omitting a boundary can only leave a link formed that
# CommonMark does not form, which over-suppresses; it can never expose content.
_ATX_HEADING = re.compile(r"^ {0,3}#{1,6}(?:[ \t]|$)")
_THEMATIC_BREAK = re.compile(r"^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$")
_BLOCK_QUOTE = re.compile(r"^ {0,3}>")
_BLOCK_QUOTE_PREFIX = re.compile(r"^ {0,3}(?:>[ \t]?)+")


def _block_quote_split(line: str) -> tuple[int, str]:
    """Return the block-quote nesting depth of ``line`` and its content."""
    marker = _BLOCK_QUOTE_PREFIX.match(line)
    if marker is None:
        return 0, line
    return marker.group(0).count(">"), line[marker.end():]


def _crosses_block_boundary(text: str, i: int) -> bool:
    """True when the newline at ``i`` separates two CommonMark leaf blocks.

    Block-quote markers are stripped from both lines first, because a ``>``
    marker only starts a new block quote when it is *deeper* than the one
    already open: at equal depth it continues the block, and at lower depth (or
    with no marker at all) the line is a lazy continuation of the same
    paragraph.  Treating every ``>`` line as a new block cleared label openers
    mid-paragraph, so ``> [outer\\n> ](url "…")`` formed no link and a Verity row
    hidden in its multiline title was wrongly exposed as a canonical pin.

    The remaining tests run against the content after the markers.  A blank line
    always ends a block, and so does a line holding only block-quote markers.  An
    ATX heading or thematic break is a one-line leaf block, so a newline ending
    one is a boundary even when the next line is ordinary text; conversely those
    forms begin a new leaf block, so a newline preceding one is a boundary too.
    """
    end = text.find("\n", i + 1)
    following = text[i + 1:] if end < 0 else text[i + 1:end]
    ended = text[text.rfind("\n", 0, i) + 1:i]
    ended_depth, ended_content = _block_quote_split(ended)
    following_depth, following_content = _block_quote_split(following)
    if following_content.strip(" \t") == "":
        return True
    if _ATX_HEADING.match(ended_content) or _THEMATIC_BREAK.match(ended_content):
        return True
    if following_depth > ended_depth:
        return True
    return bool(
        _ATX_HEADING.match(following_content)
        or _THEMATIC_BREAK.match(following_content)
    )


# GFM §4.10 tables.  A delimiter cell is a run of '-' with optional alignment colons.
_TABLE_DELIMITER_CELL = re.compile(r"^[ \t]*:?-+:?[ \t]*$")
_LIST_ITEM = re.compile(r"^ {0,3}(?:[-+*]|\d{1,9}[.)])(?:[ \t]|$)")


def _unescaped_pipes(line: str) -> list[int]:
    """Offsets within ``line`` of the ``|`` characters that delimit GFM cells."""
    return [k for k, ch in enumerate(line) if ch == "|" and not _escaped_at(line, k)]


def _indent_width(line: str) -> int:
    """Columns of leading whitespace, expanding tabs to the next four-column stop."""
    width = 0
    for ch in line:
        if ch == " ":
            width += 1
        elif ch == "\t":
            width += 4 - (width % 4)
        else:
            break
    return width


def _table_cells(line: str) -> list[str]:
    """Split a GFM table row into cells; leading and trailing pipes are optional.

    A row indented four or more columns is an indented chunk, not table markup,
    so it yields no cells.  Stripping the indentation unconditionally let a line
    such as ``    | --- | --- |`` pass as a delimiter row, conjuring a table that
    GFM does not render; the phantom cell and row separators then cleared a live
    link opener, so the link never formed and a Verity row hidden inside its
    multiline title was exposed as a canonical pin.
    """
    if _indent_width(line) >= 4 or not _unescaped_pipes(line):
        return []
    body = line.strip(" \t")
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|") and not _escaped_at(body, len(body) - 1):
        body = body[:-1]
    cells: list[str] = []
    start = 0
    for k in _unescaped_pipes(body):
        cells.append(body[start:k])
        start = k + 1
    cells.append(body[start:])
    return cells


def _ends_table(line: str) -> bool:
    """True when ``line`` cannot continue a GFM table body.

    GFM §4.10 breaks a table body at the first blank line or at the start of
    another block-level structure, and nowhere else.  In particular an ordinary
    line carrying no pipe does *not* end the table: it renders as a further row
    whose single cell is padded out.  Requiring a pipe therefore ended the region
    early while GFM kept parsing rows, and the newlines inside those excluded
    rows were never recorded as separators, so a label opener on one of them
    stayed live across a real row boundary and formed a link GFM does not form.
    Recording only the newline that closed the region could not fix that, because
    an opener may sit any number of rows past the early end.

    The conditions below are exactly the block starters that do break a table:
    a blank line, four columns of indentation (an indented chunk), an ATX
    heading, a thematic break, a block quote and a list item.
    """
    return (
        line.strip(" \t") == ""
        or _indent_width(line) >= 4
        or bool(_ATX_HEADING.match(line))
        or bool(_THEMATIC_BREAK.match(line))
        or bool(_BLOCK_QUOTE.match(line))
        or bool(_LIST_ITEM.match(line))
    )


def _table_separators(text: str) -> list[int]:
    """Ascending offsets of the GFM table cell and row separators in ``text``.

    GFM splits a table row into cells before inline parsing, so a link label,
    destination or title may not span a ``|`` cell separator nor the newline
    between two rows.  Recognition is conservative — a header row plus a
    delimiter row with the same cell count is required — so a construct that is
    not certainly a table leaves inline parsing unchanged.

    The newline that *closes* the region is recorded too, not only the ones
    between rows.  The region ends where GFM breaks the table, so that newline
    separates the table from the next leaf block and no inline may span it.
    Omitting it let a final body row that drops its trailing pipe leave an
    opener such as ``[outer`` live across the boundary, so a following
    ``](url "…`` formed a link that GFM never forms and hid a rendered Verity
    row inside its apparent title.
    """
    lines: list[tuple[int, str, int]] = []
    offset = 0
    for raw in text.splitlines(keepends=True):
        line = raw.rstrip("\n").rstrip("\r")
        lines.append((offset, line, offset + len(raw) - 1 if raw.endswith("\n") else -1))
        offset += len(raw)
    separators: list[int] = []
    row = 0
    while row + 1 < len(lines):
        columns = len(_table_cells(lines[row][1]))
        delimiter = _table_cells(lines[row + 1][1])
        if (
            columns == 0
            or _ends_table(lines[row][1])
            or len(delimiter) != columns
            or not all(_TABLE_DELIMITER_CELL.match(cell) for cell in delimiter)
        ):
            row += 1
            continue
        end = row + 2
        while end < len(lines) and not _ends_table(lines[end][1]):
            end += 1
        for index in range(row, end):
            start, line, newline = lines[index]
            separators.extend(start + k for k in _unescaped_pipes(line))
            if newline >= 0:
                separators.append(newline)
        row = end
    return separators


def _separator_in(separators: list[int], low: int, high: int) -> bool:
    """True when any recorded separator offset lies in ``[low, high)``."""
    k = bisect_left(separators, low)
    return k < len(separators) and separators[k] < high


def _strip_html_comments(text: str) -> str:
    """Remove HTML comments, skipping backtick code spans (CommonMark §6.1).

    A literal ``<!--`` inside a code span such as ``Literal `<!--` marker`` is code
    content, not an HTML comment opener; the active rendered row following it must
    not be suppressed.  Multiline code spans (opener and closer on different lines)
    have their interior suppressed so that a Verity row inside the span cannot be
    exposed to the caller's regex.

    CommonMark §2.4 backslash escapes: a backtick preceded by an odd number of
    backslashes is a literal character, not a code-span delimiter.  Escaped
    backticks such as ``\\`<!--\\`` do not form a code span, so the ``<!--``
    between them is correctly recognised as an HTML comment opener.

    The same §2.4 rule applies to ``<``: a ``<`` preceded by an odd number of
    backslashes is literal text, so ``\\<!--`` must NOT be treated as an HTML
    comment opener.  The preceding backslash run is counted before entering the
    comment branch, identical to the handling for escaped backticks.

    CommonMark §6.6 inline HTML tags: when scanning an open/close tag, a ``<``
    appearing in attribute position (outside a quoted value) means the tag is not
    a valid CommonMark inline tag.  The scanner aborts and falls back to emitting
    only the initial ``<`` so that subsequent constructs (e.g. ``<!--``) are
    re-scanned and handled correctly.  A quoted attribute value whose closing
    quote is never found before end of text is also treated as invalid: the tag
    is aborted and subsequent content (including a canonical Verity row) is
    re-scanned and emitted normally, matching Markdown's literal rendering of the
    broken construct.

    CommonMark inline links: a ``](`` only opens a link when an unescaped ``[``
    label is actually open, so ``[`` openers are tracked on a stack and both
    brackets are checked for §2.4 escape state before the destination/title
    scanner runs.  A bare ``](``, an escaped ``\\](``, or a ``](`` whose only
    candidate opener is an escaped ``\\[`` forms no link, and an unescaped ``]``
    consumes its opener whether or not a link is formed; in each case the
    intervening text stays visible exactly as CommonMark renders it.

    Inlines are parsed independently within each block, so pending label openers
    are cleared as the scan crosses a leaf-block boundary.  A blank line ends a
    block; so do the nonblank transitions recognised by _crosses_block_boundary
    (ATX heading, thematic break, deeper block quote).  An unmatched ``[`` in an
    earlier block therefore cannot be consumed by a ``](`` in a later one; the
    later text is not a link and any Verity row inside its apparent title stays
    visible.  No valid link spans a block boundary, so clearing there cannot
    expose genuine link metadata.

    GFM applies the same rule one level finer inside a table: a row is split into
    cells before its inlines are parsed, so no link may span a ``|`` cell
    separator or the newline between two rows.  Openers are cleared at those
    separators too, and a link whose destination or title would reach across one
    is not formed — the ``]`` is re-emitted so that a genuinely rendered Verity
    row on a later table row is never suppressed by an unterminated title in an
    earlier cell.

    Links may not contain links, but they may contain images.  Openers therefore
    record whether they are image (``![``) or link (``[``) openers: forming a link
    deactivates every still-open outer *link* opener, while forming an image
    deactivates nothing.  In ``[outer [inner](x)](url "…")`` the inner link
    deactivates the outer opener and the second ``](`` stays literal, whereas in
    ``[outer ![inner](x)](url "…")`` the outer link is valid and its title is
    still suppressed.  A deactivated opener is consumed by its ``]`` but forms no
    link.

    When a ``](`` does open a link, the link destination and optional title are
    scanned.  The title interior (between
    quote or parenthesis delimiters) is suppressed — only newlines are preserved —
    so that a Verity row placed inside a multiline link title cannot match as a
    rendered row.  CommonMark §2.4 backslash escapes inside the title are honoured:
    a ``\\"`` or ``\\'`` is title content, not the closing delimiter, so the scan
    continues past it.  An unterminated title (no closing delimiter before EOF) or
    a link missing its closing ``)`` is not a valid CommonMark link; suppression is
    deferred: the ``]`` is re-emitted and ``(`` re-scanned, leaving any Verity row
    that follows visible to the regex.

    Line-boundary invariant: every stripped region (HTML comment, multiline code
    span, link title interior) is replaced by exactly as many ``\\n`` characters
    as the region contained.  This ensures that content on different physical
    source lines remains on different lines in the output and cannot be
    concatenated by stripping into a synthesized ``| Verity | pin |`` row that
    does not exist in the rendered Markdown.
    """
    result: list[str] = []
    # Each entry is (is_image, active).  An opener deactivated by a nested link
    # still consumes its ']' but can no longer form a link.  Image openers ('![')
    # are tracked separately because links may contain images.
    open_labels: list[tuple[bool, bool]] = []
    table_separators = _table_separators(text)
    i = 0
    n = len(text)
    while i < n:
        if text[i] == "`":
            # CommonMark §2.4: a backtick preceded by an odd number of backslashes
            # is a literal character, not a code-span delimiter.  Count consecutive
            # preceding backslashes; if the count is odd, the backtick is escaped.
            num_bs = 0
            p = i - 1
            while p >= 0 and text[p] == "\\":
                num_bs += 1
                p -= 1
            if num_bs % 2 == 1:
                result.append("`")
                i += 1
                continue
            j = i
            while j < n and text[j] == "`":
                j += 1
            run_len = j - i
            k = j
            while k < n:
                if text[k] == "`":
                    lo = k
                    while lo < n and text[lo] == "`":
                        lo += 1
                    if lo - k == run_len:
                        if "\n" not in text[j:k]:
                            result.append(text[i:lo])
                        else:
                            # Multiline code span: suppress the interior but preserve
                            # physical line boundaries so that content on different
                            # physical lines cannot be concatenated by span removal.
                            result.append("\n" * text[i:lo].count("\n"))
                        i = lo
                        break
                    k = lo
                else:
                    k += 1
            else:
                result.append(text[i:j])
                i = j
        elif text[i : i + 4] == "<!--":
            # CommonMark §2.4: a '<' preceded by an odd number of backslashes is
            # escaped (literal '<'); '<!--' is then NOT an HTML comment opener and
            # must not consume subsequent content.
            num_bs = 0
            p = i - 1
            while p >= 0 and text[p] == "\\":
                num_bs += 1
                p -= 1
            if num_bs % 2 == 1:
                result.append("<")
                i += 1
            else:
                end = text.find("-->", i + 4)
                if end >= 0:
                    # Preserve physical line boundaries: replace the stripped comment
                    # with the same number of newlines it contained so that content on
                    # different physical lines is not concatenated by comment removal.
                    result.append("\n" * text[i : end + 3].count("\n"))
                    i = end + 3
                else:
                    break
        elif text[i] == "<" and i + 1 < n and (text[i + 1].isalpha() or text[i + 1] == "/"):
            # CommonMark §6.6 inline HTML open/close tag: scan through attributes,
            # suppressing any quoted attribute value whose content spans multiple lines.
            # A Verity row placed inside a multiline quoted attribute (e.g.
            # <span title="\n| Verity |…\n">) is raw HTML, not rendered table content.
            j = i + 1
            while j < n and (text[j].isalnum() or text[j] in "-:_/"):
                j += 1
            tag_out: list[str] = [text[i:j]]
            valid = True
            while j < n:
                if text[j] in ('"', "'"):
                    q = text[j]
                    j += 1
                    qs = j
                    while j < n and text[j] != q:
                        j += 1
                    content = text[qs:j]
                    if j < n:
                        j += 1  # skip closing quote
                        tag_out.append(q + ("" if "\n" in content else content) + q)
                    else:
                        # Unterminated quoted attribute: not a valid CommonMark §6.6
                        # inline tag.  Subsequent content (e.g. a canonical Verity row)
                        # must not be suppressed; abort and re-scan from the '<'.
                        valid = False
                        break
                elif text[j] == ">":
                    tag_out.append(">")
                    j += 1
                    break
                elif text[j] == "<":
                    # '<' in attribute position is not valid CommonMark §6.6 inline-tag
                    # grammar; abort so the '<' and any following '<!--' are re-scanned.
                    valid = False
                    break
                else:
                    tag_out.append(text[j])
                    j += 1
            if valid:
                result.extend(tag_out)
                i = j
            else:
                result.append("<")
                i += 1
        elif text[i] == "[" and not _escaped_at(text, i):
            # Only an unescaped '[' opens a link label.  Openers consumed by an
            # earlier branch (code span, HTML comment, tag, link body) never reach
            # here, matching CommonMark's rule that they open no label.
            # A '[' directly preceded by an unescaped '!' opens an image, not a link.
            open_labels.append((i > 0 and text[i - 1] == "!" and not _escaped_at(text, i - 1), True))
            result.append("[")
            i += 1
        elif text[i] in ("\n", "|") and (
            _separator_in(table_separators, i, i + 1)
            or (text[i] == "\n" and _crosses_block_boundary(text, i))
        ):
            # CommonMark parses inlines independently within each block, and GFM
            # parses each table cell independently within a row.  A label opener
            # left unmatched before either kind of boundary cannot be consumed by
            # a '(' after it, so pending openers are cleared at both.
            open_labels.clear()
            result.append(text[i])
            i += 1
        elif text[i] == "]" and not _escaped_at(text, i) and open_labels:
            # An unescaped ']' consumes its opener whether or not an inline link is
            # formed, so a later '](' left without an opener stays literal text.
            # An inactive opener (one deactivated by a nested link) is consumed too,
            # but forms no link: its ']' stays literal.
            opener_is_image, opener_active = open_labels.pop()
            if not opener_active:
                result.append("]")
                i += 1
                continue
            if i + 1 >= n or text[i + 1] != "(":
                result.append("]")
                i += 1
                continue
            # CommonMark inline link ](destination "title"): suppress title
            # interior while preserving physical line boundaries so a Verity row
            # embedded in a multiline link title cannot match as a rendered row.
            # All output is buffered; only committed to result when the full link
            # syntax (destination + optional title + closing ')') is validated so
            # that an unterminated title or missing ')' leaves content visible.
            link_buf: list[str] = ["]("]
            j = i + 2
            # Pass through leading whitespace (preserving newlines)
            while j < n and text[j] in (" ", "\t", "\n"):
                link_buf.append(text[j])
                j += 1
            # Destination: <...> or undelimited (no spaces, balanced parens)
            if j < n and text[j] == "<":
                link_buf.append("<")
                j += 1
                while j < n and text[j] not in (">", "\n"):
                    link_buf.append(text[j])
                    j += 1
                if j < n and text[j] == ">":
                    link_buf.append(">")
                    j += 1
            else:
                depth = 0
                while j < n:
                    c = text[j]
                    if depth == 0 and (c in (" ", "\t", "\n") or c == ")"):
                        break
                    if c == "(":
                        depth += 1
                    elif c == ")":
                        depth -= 1
                    link_buf.append(c)
                    j += 1
            # Whitespace between destination and optional title
            while j < n and text[j] in (" ", "\t", "\n"):
                link_buf.append(text[j])
                j += 1
            # Optional title: suppress interior, preserve newlines only.
            # CommonMark §6.3 admits three title forms ("…", '…', (…)); §2.4 makes a
            # backslash-escaped delimiter title content rather than the closer, so an
            # escaped quote or paren cannot prematurely end the scan.  No title is
            # formed when it is unterminated, when it spans a blank line, or when a
            # parenthesized title holds an unescaped '('.  Each of those sets
            # title_valid=False so the ']' is re-emitted and '(' re-scanned, leaving
            # the subsequent content visible exactly as CommonMark renders it.
            title_valid = True
            if j < n and text[j] in ('"', "'", "("):
                opener = text[j]
                closer = ")" if opener == "(" else opener
                link_buf.append(opener)
                j += 1
                while j < n:
                    ch = text[j]
                    if ch == "\\":
                        # §2.4: skip backslash and the escaped character; an escaped
                        # delimiter is title content, not the closer.
                        j += 1
                        if j < n:
                            if text[j] == "\n":
                                link_buf.append("\n")
                                # §6.3: escaping the newline must not skip the
                                # blank-line check; a blank line still voids the
                                # title even when the preceding line ends in '\'.
                                k = j + 1
                                while k < n and text[k] in (" ", "\t"):
                                    k += 1
                                if k >= n or text[k] == "\n":
                                    title_valid = False
                                    break
                            j += 1
                        continue
                    if ch == closer:
                        link_buf.append(closer)
                        j += 1
                        break
                    if ch == "(" and opener == "(":
                        # §6.3: an unescaped '(' may not appear in a parenthesized
                        # title, so the link is not formed.
                        title_valid = False
                        break
                    if ch == "\n":
                        link_buf.append("\n")
                        k = j + 1
                        while k < n and text[k] in (" ", "\t"):
                            k += 1
                        if k >= n or text[k] == "\n":
                            # §6.3: a title may not contain a blank line.
                            title_valid = False
                            break
                    j += 1
                else:
                    title_valid = False
            if not title_valid:
                result.append("]")
                i += 1
                continue
            # Skip trailing whitespace before closing ')'
            while j < n and text[j] in (" ", "\t"):
                link_buf.append(text[j])
                j += 1
            # Closing ')': only commit link_buf if found and the whole construct
            # stays inside one GFM table cell; otherwise re-emit ']'.  A link that
            # would span a cell or row separator is not formed by GFM, so its
            # apparent title must stay visible rather than suppress a rendered row.
            if j < n and text[j] == ")" and not _separator_in(table_separators, i, j):
                link_buf.append(")")
                j += 1
                result.extend(link_buf)
                i = j
                # Links may not contain links, but they may contain images, so only
                # a formed link deactivates outer openers, and only the link ones.
                if not opener_is_image:
                    open_labels = [(img, act and img) for img, act in open_labels]
            else:
                result.append("]")
                i += 1
        else:
            result.append(text[i])
            i += 1
    return "".join(result)


# CommonMark §4.6 HTML block openers and their end-condition patterns (Types 1, 3–6).
# Type 2 (<!-- … -->) is handled inline by _strip_html_comments; only the block forms
# that _strip_html_comments does not cover need the line-by-line pass below.
_HTML1 = re.compile(
    r"^ {0,3}<(script|pre|style|textarea)(?:[\s>]|$)", re.IGNORECASE
)
_HTML1_END: dict[str, re.Pattern[str]] = {
    "script": re.compile(r"</script>", re.IGNORECASE),
    "pre": re.compile(r"</pre>", re.IGNORECASE),
    "style": re.compile(r"</style>", re.IGNORECASE),
    "textarea": re.compile(r"</textarea>", re.IGNORECASE),
}
_HTML5 = re.compile(r"^ {0,3}<!\[CDATA\[")   # checked before Type 4 (<![)
_HTML5_END = re.compile(r"\]\]>")
_HTML3 = re.compile(r"^ {0,3}<\?")
_HTML3_END = re.compile(r"\?>")
_HTML4 = re.compile(r"^ {0,3}<![A-Z]")
_HTML4_END = re.compile(r">")
_HTML6 = re.compile(
    r"^ {0,3}</?(?:"
    r"address|article|aside|base|basefont|blockquote|body|caption|center|"
    r"col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|"
    r"figure|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|"
    r"hr|html|iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|"
    r"ol|optgroup|option|p|param|search|section|summary|table|tbody|td|"
    r"tfoot|th|thead|title|tr|track|ul"
    r")(?:[\s>]|/>|$)",
    re.IGNORECASE,
)
# Type 7: any other open/close tag on a line by itself (blank-line-terminated).
# Uses the full CommonMark §4.6 attribute grammar so that quoted attribute values
# containing ">" are recognised (e.g. title="a > b").  Attribute values may be
# double-quoted ("[^"]*"), single-quoted ('[^']*'), or unquoted (no whitespace,
# quotes, =, <, >, or backtick).
_HTML7 = re.compile(
    r"^ {0,3}"
    r"</?[A-Za-z][A-Za-z0-9-]*"
    r'(?:\s+[A-Za-z_:][A-Za-z0-9_.:-]*(?:\s*=\s*(?:[^"\'=<>`\x00-\x1f\s]+|"[^"]*"|\'[^\']*\'))?)*'
    r"\s*/?>[ \t]*$"
)


def _strip_non_rendered(text: str) -> str:
    """Remove CommonMark fenced code blocks, HTML blocks, then HTML comments.

    Processing order: fenced code blocks (§4.5) → HTML blocks (§4.6) → HTML
    comments (§4.6 Type 2, handled inline by _strip_html_comments).  Each layer
    is stripped before the next so that a ``<!--`` inside a fence is not treated
    as a comment opener, and HTML block contents are suppressed before comment
    scanning.

    Fenced-block rules (CommonMark §4.5):
    - opener: 0–3 spaces of indentation, then 3+ identical `` ` `` or ``~`` chars
    - closer: same character, at least as many chars as the opener, optional trailing space
    - unclosed fence: extends to EOF
    For backtick openers whose info string contains a backtick, CommonMark treats the
    run as a code-span opener (§6.1) rather than a fence opener.  Code-span closers
    must have the same exact length as their opener (not merely ≥), and may appear
    anywhere on a line (not only occupying a whole line), so the fence ``{N,}``
    closer rule and the whole-line anchor both do not apply.  If no exact-length
    closer is found before EOF the code span is unmatched, the opener is literal,
    and all enclosed lines are restored as rendered content.

    HTML block rules (CommonMark §4.6, Types 1, 3–7):
    - Type 1: ``<script|pre|style|textarea>`` … ``</tag>``
    - Type 3: ``<?`` … ``?>``
    - Type 4: ``<!UPPER`` … ``>``
    - Type 5: ``<![CDATA[`` … ``]]>``
    - Type 6: block-level open/close tag … blank line
    - Type 7: any other open/close tag alone on a line … blank line
    The opener line and all lines up to and including the end-condition line are
    suppressed.  For blank-line-terminated blocks (Types 6–7) the blank line itself
    is not part of the block; CommonMark defines a blank line as containing only
    spaces and tabs, not merely the empty string.  Type 2 (``<!-- … -->``) is
    handled separately by _strip_html_comments, which correctly skips code-span
    content, including multiline code spans whose interior spans multiple lines.

    Removing a block leaves a blank line in its place, because the later passes
    read only the stripped text and would otherwise see content from either side
    of the block as adjacent.  That synthetic adjacency was exploitable: a fence
    between a table and a paragraph made the paragraph look like more table rows,
    whose newlines then cleared a ``[`` opener, leaving a multiline link title
    unsuppressed so that a lone canonical Verity line inside it counted as
    rendered.  The blank line restores the boundary GFM has there.

    The boundary is emitted for fenced code blocks and HTML Types 1 and 3–6,
    which can all interrupt a paragraph, so a boundary is always faithful.  It is
    *not* emitted for Type 7, which cannot interrupt a paragraph (§4.6): mid
    paragraph GFM sees no block at all, and a boundary there would wrongly split
    an inline context that GFM keeps together.  Code spans get none either, being
    inline rather than blocks.
    """
    out: list[str] = []
    in_fence = False
    fence_char = ""
    fence_min_len = 0
    is_code_span = False
    code_span_buffer: list[str] = []
    in_html_block = False
    html_block_end: "re.Pattern[str] | None" = None  # None = blank-line-terminated (Type 6)
    for line in text.splitlines(keepends=True):
        stripped = line.rstrip("\r\n")
        if in_fence:
            if is_code_span:
                # CommonMark §6.1: the closer is an exact-length backtick run and
                # may appear anywhere on the line, not only as a whole-line match.
                closes = re.search(
                    r"(?<!"
                    + re.escape(fence_char)
                    + r")"
                    + re.escape(fence_char)
                    + r"{"
                    + str(fence_min_len)
                    + r"}(?!"
                    + re.escape(fence_char)
                    + r")",
                    stripped,
                )
                if closes:
                    remainder = line[closes.end():]
                    if remainder.strip("\r\n"):
                        out.append(remainder)
                    in_fence = False
                    is_code_span = False
                    code_span_buffer = []
                else:
                    code_span_buffer.append(line)
            else:
                if re.match(
                    r"^ {0,3}" + re.escape(fence_char) + r"{" + str(fence_min_len) + r",}[ ]*$",
                    stripped,
                ):
                    in_fence = False
        elif in_html_block:
            if html_block_end is None:
                # Type 6/7: blank-line-terminated; blank line ends the block but is
                # not itself part of it.  CommonMark defines a blank line as one
                # containing only spaces and tabs (not merely the empty string).
                if not stripped.strip():
                    in_html_block = False
                    out.append(line)
            elif html_block_end.search(stripped):
                # Types 1, 3–5: closing line is consumed by the block.
                in_html_block = False
        else:
            m = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)", stripped)
            if m:
                fence_char = m.group(1)[0]
                fence_min_len = len(m.group(1))
                # Backtick opener with a backtick in its info string is not a valid
                # fence opener (§4.5); it forms a code span (§6.1) whose closer must
                # be the exact same backtick-run length, not merely ≥.
                is_code_span = fence_char == "`" and "`" in m.group(2)
                if is_code_span:
                    # §6.1: if the exact-length closer already appears on the opener
                    # line (in the info string / remaining text), the code span opens
                    # and closes on the same line; treat the line as rendered content.
                    closes_on_opener = re.search(
                        r"(?<!" + re.escape(fence_char) + r")"
                        + re.escape(fence_char) + r"{" + str(fence_min_len) + r"}(?!"
                        + re.escape(fence_char) + r")",
                        m.group(2),
                    )
                    if closes_on_opener:
                        out.append(line)
                        is_code_span = False
                    else:
                        code_span_buffer = [line]
                        in_fence = True
                else:
                    out.append("\n")
                    in_fence = True
            else:
                # CommonMark §4.6 HTML block detection (Types 1, 3–7).
                # Opener line is always suppressed; if the end condition is also met
                # on the opener line the block closes immediately without entering
                # the in_html_block state.
                m1 = _HTML1.match(stripped)
                if m1:
                    tag = m1.group(1).lower()
                    end_re = _HTML1_END[tag]
                    out.append("\n")
                    if not end_re.search(stripped):
                        in_html_block = True
                        html_block_end = end_re
                elif _HTML5.match(stripped):
                    out.append("\n")
                    if not _HTML5_END.search(stripped):
                        in_html_block = True
                        html_block_end = _HTML5_END
                elif _HTML3.match(stripped):
                    out.append("\n")
                    if not _HTML3_END.search(stripped):
                        in_html_block = True
                        html_block_end = _HTML3_END
                elif _HTML4.match(stripped):
                    out.append("\n")
                    if not _HTML4_END.search(stripped):
                        in_html_block = True
                        html_block_end = _HTML4_END
                elif _HTML6.match(stripped):
                    out.append("\n")
                    in_html_block = True
                    html_block_end = None
                elif _HTML7.match(stripped):
                    in_html_block = True
                    html_block_end = None
                else:
                    out.append(line)
    # Unmatched code span: the opener was literal in CommonMark; restore all lines.
    if in_fence and is_code_span:
        out.extend(code_span_buffer)
    return _strip_html_comments("".join(out))


def check(root: Path) -> str:
    lakefile = (root / "lakefile.lean").read_text(encoding="utf-8")
    requests = re.findall(
        r'^\s*require\s+verity\s+from\s+git\s*\n\s*"([^"\n]+)"@"([^"\n]+)"\s*$',
        lakefile,
        re.MULTILINE,
    )
    if len(requests) != 1:
        fail("lakefile.lean must contain exactly one canonical Verity git request")
    requested_repository, requested_revision = requests[0]
    if requested_repository != VERITY_REPOSITORY:
        fail(f"lakefile Verity repository differs: {requested_repository!r}")
    if FULL_REVISION.fullmatch(requested_revision) is None:
        fail(f"lakefile Verity request is not an exact 40-hex revision: {requested_revision!r}")

    manifest = load_json(root / "lake-manifest.json")
    packages = manifest.get("packages")
    if not isinstance(packages, list):
        fail("lake-manifest.json packages must be a list")
    resolved = [package for package in packages if isinstance(package, dict) and package.get("name") == "verity"]
    if len(resolved) != 1:
        fail("lake-manifest.json must contain exactly one Verity package")
    package = resolved[0]
    expected_package = {
        "url": requested_repository,
        "type": "git",
        "rev": requested_revision,
        "inputRev": requested_revision,
        "inherited": False,
        "configFile": "lakefile.lean",
    }
    for key, expected in expected_package.items():
        if package.get(key) != expected:
            fail(f"lake-manifest Verity {key} {package.get(key)!r} differs from requested {expected!r}")

    lock = load_json(root / "audit/artifacts.lock.json")
    lock_pin = ((lock.get("pins") or {}).get("verity") if isinstance(lock.get("pins"), dict) else None)
    if lock_pin != {"repository": requested_repository, "commit": requested_revision}:
        fail("artifact-lock Verity pin differs from the lakefile request")

    audit_manifest = load_json(root / "verity/targets/audit-manifest.json")
    revisions = audit_manifest.get("source_revisions")
    audit_revision = revisions.get("verity") if isinstance(revisions, dict) else None
    if audit_revision != requested_revision:
        fail("audit-manifest Verity revision differs from the lakefile request")

    legacy_source_map = load_json(root / "verity/targets/source-map.json")
    source_revisions = legacy_source_map.get("source_revisions")
    source_map_revision = source_revisions.get("verity_commit") if isinstance(source_revisions, dict) else None
    if source_map_revision != requested_revision:
        fail("source-map Verity revision differs from the lakefile request")

    lockfile_text = (root / "proofs/LOCKFILE.md").read_text(encoding="utf-8")
    # Use [ \t]* instead of \s* so the match is confined to a single physical line;
    # \s* would match \n and allow stripped regions to be bridged across line boundaries.
    lockfile_matches = re.findall(r"^\|[ \t]*Verity[ \t]*\|[ \t]*`([0-9a-f]{40})`[ \t]*\|", _strip_non_rendered(lockfile_text), re.MULTILINE)
    if len(lockfile_matches) != 1:
        fail("proofs/LOCKFILE.md must contain exactly one Verity pin row")
    if lockfile_matches[0] != requested_revision:
        fail(f"proofs/LOCKFILE.md Verity pin {lockfile_matches[0]!r} differs from the lakefile request")

    checkout = root / ".lake/packages/verity"
    if not checkout.is_dir():
        fail(f"resolved Verity checkout {checkout} not found")
    result = subprocess.run(
        ["git", "-C", str(checkout), "rev-parse", "HEAD"],
        text=True, capture_output=True, check=False,
    )
    if result.returncode != 0 or FULL_REVISION.fullmatch(result.stdout.strip()) is None:
        fail("could not read an exact resolved Verity checkout revision")
    checkout_revision = result.stdout.strip()
    if checkout_revision != requested_revision:
        fail(f"resolved Verity checkout revision {checkout_revision!r} differs from requested {requested_revision!r}")
    dirty = subprocess.run(
        ["git", "-C", str(checkout), "status", "--porcelain", "--untracked-files=all"],
        text=True, capture_output=True, check=False,
    )
    if dirty.returncode != 0 or dirty.stdout:
        fail("resolved Verity checkout is dirty or unreadable")
    return requested_revision


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    try:
        revision = check(args.root.resolve())
    except (OSError, ValueError) as exc:
        print(f"Verity provenance check failed: {exc}", file=sys.stderr)
        return 1
    print(revision)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
