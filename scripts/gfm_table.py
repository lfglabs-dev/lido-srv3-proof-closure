#!/usr/bin/env python3
r"""One cmark-gfm-faithful reader for the Markdown tables the gates read.

Three published surfaces are checked by asking the same two questions of a
Markdown file: *does this block render as a table at all*, and *which lines are
the rows inside it*.  Each gate answered them with its own approximation, and
the approximations agreed on the same mistake: cells were counted by counting
``|`` characters.

GFM splits a row into cells before any inline parsing, at the pipes that are
not escaped, and a pipe carried inside a cell is written ``\|``.  So a header
that prints one escaped pipe declares one cell *fewer* than its character count
suggests, and GFM renders no table whatsoever when the delimiter row does not
carry exactly as many cells as the header.  A header with one ``\|`` under a
delimiter row widened by one column therefore satisfied ``count("|")`` equality
in every gate while cmark-gfm -- the renderer GitHub runs -- printed the whole
block as a paragraph of literal text.  The gate reported the rows; the reader
met none of them.

Escaping here follows cmark-gfm's table scanner rather than CommonMark's
backslash-parity rule, because the table scanner is what decides where cells
begin.  Its cell pattern accepts ``\|`` as cell content, so *any* pipe written
directly after a backslash is content and not a boundary: ``\\|`` renders one
cell, not two, even though CommonMark inline parsing would read the first
backslash as escaping the second.  Reading parity here would have counted two
cells where the renderer counts one -- the same false agreement, one level down.

The same faithfulness applies to where a table stops.  GFM breaks the body at
the first blank line or at the start of another block-level structure, and
nowhere else: an ordinary line carrying no pipe is a further row rather than
the end of the table.  Reading rows from "the section" instead of from the
table let a row moved below a blank line -- still inside the section, no longer
inside the table -- go on being counted while the rendered table had dropped it.
``ends_table`` spells the block starters that really do break a table, so the
row window a caller gets is the window a reader is shown.

The reader is deliberately one-sided.  Every table it reports is one cmark-gfm
renders, with the same columns and the same body rows; two forms it cannot read
faithfully -- a header or delimiter row carrying leading whitespace, and a table
nested inside a list item or block quote, whose container prefix it does not
strip -- are declined rather than guessed at.  Declining is the safe direction:
a gate that cannot see the table it was told to check reports it missing and
fails closed, while reporting a table that renders as paragraph text is exactly
the failure this module exists to remove.

Every function here is a reader.  Nothing in this module decides policy; the
gates that import it do.
"""

from __future__ import annotations

import re
from typing import NamedTuple

# Tabs advance to the next four-column stop when CommonMark measures indentation.
TAB_STOP = 4

# GFM 4.10: a delimiter cell is a run of '-' with optional alignment colons.
# An empty cell is not one, so `|     |     |` underlines nothing and the block
# it sits under renders as paragraph text.
DELIMITER_CELL = re.compile(r"^[ \t]*:?-+:?[ \t]*$")

_ATX_HEADING = re.compile(r"^ {0,3}#{1,6}(?:[ \t]|$)")
_THEMATIC_BREAK = re.compile(
    r"^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$")
_BLOCK_QUOTE = re.compile(r"^ {0,3}>")
_LIST_ITEM = re.compile(r"^ {0,3}(?:[-+*]|\d{1,9}[.)])(?:[ \t]|$)")
# A line of `-` or `=` alone underlines the paragraph above it as a setext
# heading, and cmark-gfm resolves that before it looks for a table: `A` over
# `---` is an `<h2>`, not a one-column table.  A delimiter row carrying a colon
# or a pipe is not a setext underline, so a real table keeps rendering.
_SETEXT_UNDERLINE = re.compile(r"^ {0,3}(?:=+|-+)[ \t]*$")

# CommonMark's seven HTML block start conditions.  A table row is not a
# paragraph, so condition 7 -- the lone complete tag, which may not interrupt a
# paragraph -- still starts a block here and still breaks the table; cmark-gfm
# ends a table body on `<span>` alone on a line exactly as it does on `<div>`.
_HTML_RAW_TEXT_NAMES = "script|pre|style|textarea"
_HTML_BLOCK_NAMES = (
    "address|article|aside|base|basefont|blockquote|body|caption|center|col|"
    "colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|"
    "form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hr|html|iframe|legend|li|"
    "link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|option|p|param|search|"
    "section|source|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul"
)
_HTML_ATTRIBUTE = (
    r"""(?:[ \t]+[A-Za-z_:][A-Za-z0-9_.:-]*"""
    r"""(?:[ \t]*=[ \t]*(?:[^ \t"'=<>`]+|'[^']*'|"[^"]*"))?)"""
)
_HTML_TAG = (rf"(?:<[A-Za-z][A-Za-z0-9-]*{_HTML_ATTRIBUTE}*[ \t]*/?>"
             rf"|</[A-Za-z][A-Za-z0-9-]*[ \t]*>)")
_HTML_BLOCK_START = re.compile(
    rf"^ {{0,3}}(?:"
    rf"<(?:{_HTML_RAW_TEXT_NAMES})(?:[ \t]|>|$)"
    rf"|<\?"
    rf"|<!(?:--|\[CDATA\[|[A-Za-z])"
    rf"|</?(?:{_HTML_BLOCK_NAMES})(?:[ \t]|/?>|$)"
    rf"|{_HTML_TAG}[ \t]*$"
    rf")",
    re.IGNORECASE,
)

# The same start conditions again, paired with what closes each region, for the
# interior scan.  `ends_table` refuses to continue a table across the line that
# *opens* a literal region; these pairs are what stop a table being read out of
# the interior of one.
_FENCE_OPEN = re.compile(r"^ {0,3}(?P<seq>`{3,}|~{3,})(?P<info>.*)$")
_FENCE_CLOSE = re.compile(r"^ {0,3}(?P<seq>`{3,}|~{3,})[ \t]*$")
_HTML_BLOCK_BLANK_END = re.compile(r"^[ \t]*$")
_HTML_BLOCK_STARTS = (
    (re.compile(rf"^ {{0,3}}<(?:{_HTML_RAW_TEXT_NAMES})(?:[ \t]|>|$)", re.IGNORECASE),
     re.compile(rf"</(?:{_HTML_RAW_TEXT_NAMES})>", re.IGNORECASE)),
    (re.compile(r"^ {0,3}<\?"), re.compile(r"\?>")),
    (re.compile(r"^ {0,3}<!\[CDATA\["), re.compile(r"\]\]>")),
    (re.compile(r"^ {0,3}<!--"), re.compile(r"-->")),
    (re.compile(r"^ {0,3}<![A-Za-z]"), re.compile(r">")),
    (re.compile(rf"^ {{0,3}}</?(?:{_HTML_BLOCK_NAMES})(?:[ \t]|/?>|$)", re.IGNORECASE),
     _HTML_BLOCK_BLANK_END),
)
_HTML_BLOCK_BARE_TAG = re.compile(rf"^ {{0,3}}{_HTML_TAG}[ \t]*$")

# Conditions 1-6 only: the HTML block starts that may interrupt a paragraph.
# Condition 7 may not, which is why it is tested against the paragraph state in
# `_literal_lines` rather than listed here.
_HTML_BLOCK_INTERRUPTING = re.compile(
    rf"^ {{0,3}}(?:"
    rf"<(?:{_HTML_RAW_TEXT_NAMES})(?:[ \t]|>|$)"
    rf"|<\?"
    rf"|<!(?:--|\[CDATA\[|[A-Za-z])"
    rf"|</?(?:{_HTML_BLOCK_NAMES})(?:[ \t]|/?>|$)"
    rf")",
    re.IGNORECASE,
)


class Row(NamedTuple):
    """One physical line of a rendered table, with its offsets in the source."""

    start: int          # offset of the first character of the line
    end: int            # offset just past the line's newline (or end of text)
    text: str           # the line without its newline
    cells: tuple[str, ...]


class Table(NamedTuple):
    """A block cmark-gfm renders as a table, located in the source text."""

    header: Row
    delimiter: Row
    rows: tuple[Row, ...]

    @property
    def columns(self) -> int:
        """Cells the header declares, which is what the delimiter must match."""
        return len(self.header.cells)

    @property
    def start(self) -> int:
        return self.header.start

    @property
    def body_start(self) -> int:
        """Where the first body row begins: just past the delimiter row."""
        return self.delimiter.end

    @property
    def body_end(self) -> int:
        """Just past the last body row; equal to ``body_start`` when there is none."""
        return self.rows[-1].end if self.rows else self.delimiter.end

    @property
    def end(self) -> int:
        return self.body_end


def indent_width(line: str) -> int:
    """Columns of leading whitespace, expanding tabs to the next four-column stop."""
    width = 0
    for char in line:
        if char == " ":
            width += 1
        elif char == "\t":
            width += TAB_STOP - (width % TAB_STOP)
        else:
            break
    return width


def unescaped_pipes(line: str) -> list[int]:
    r"""Offsets of the ``|`` characters that delimit cells in ``line``.

    A pipe written directly after a backslash is cell content: that is what the
    ``\|`` escape is, and cmark-gfm's scanner reads it without counting the
    backslashes in front of it.  Parity is deliberately not consulted -- see the
    module docstring -- because a reader meets whatever cmark-gfm prints.
    """
    return [k for k, char in enumerate(line)
            if char == "|" and (k == 0 or line[k - 1] != "\\")]


def split_cells(line: str) -> list[str]:
    """Split a GFM table row into its cells; the outer pipes are optional.

    A line indented four or more columns is an indented chunk rather than table
    markup, so it yields no cells: reading ``    | --- | --- |`` as a delimiter
    row conjures a table cmark-gfm does not render.  A line with no unescaped
    pipe at all yields one cell, not none -- cmark-gfm renders a one-column
    table from a plain header line over a lone ``:---`` delimiter, and a gate
    that cannot see a table cannot see the rows a reader meets inside it.
    """
    if indent_width(line) >= 4:
        return []
    body = line.strip(" \t")
    if body == "" or body == "|":
        # A lone pipe opens a cell and closes nothing: cmark-gfm's row scanner
        # consumes it as the leading delimiter and finds no cell after it, so
        # the line declares zero columns and can underline or be underlined by
        # nothing.  Returning one empty cell instead invented a one-column
        # table out of a line that renders as the character `|`.
        return []
    if not unescaped_pipes(body):
        return [body]
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]
    cells: list[str] = []
    start = 0
    for k in unescaped_pipes(body):
        cells.append(body[start:k])
        start = k + 1
    cells.append(body[start:])
    return cells


def is_delimiter_row(cells: list[str]) -> bool:
    """Whether ``cells`` are all hyphen runs, i.e. underline a header."""
    return bool(cells) and all(DELIMITER_CELL.match(cell) for cell in cells)


def ends_table(line: str) -> bool:
    """True when ``line`` cannot continue a GFM table body.

    GFM breaks a table body at the first blank line or at the start of another
    block-level structure, and nowhere else.  In particular an ordinary line
    carrying no pipe does *not* end the table: cmark-gfm renders it as a further
    row whose single cell is padded out.  The conditions below are the block
    starters that really do break one -- blank line, indented chunk, ATX
    heading, thematic break, block quote, list item, code fence and every HTML
    block start -- each confirmed against cmark-gfm.
    """
    return (
        line.strip(" \t") == ""
        or indent_width(line) >= 4
        or bool(_ATX_HEADING.match(line))
        or bool(_THEMATIC_BREAK.match(line))
        or bool(_BLOCK_QUOTE.match(line))
        or bool(_LIST_ITEM.match(line))
        or _opens_fence(line)
        or bool(_HTML_BLOCK_START.match(line))
    )


def _opens_fence(line: str) -> bool:
    """Whether ``line`` opens a fenced code block.

    A backtick fence may not carry a backtick in its info string, so a line such
    as ```` ````x` ```` opens nothing and is ordinary content.  Reading every run
    of three backticks as a fence ended a table body one row early, which lost a
    row a reader is shown.
    """
    opening = _FENCE_OPEN.match(line)
    return bool(opening) and not (opening.group("seq")[0] == "`"
                                  and "`" in opening.group("info"))


def _closes_paragraph(line: str) -> bool:
    """Whether ``line`` cannot continue the paragraph above it.

    Deliberately *not* ``ends_table``.  Four columns of indentation end a table
    body but do not end a paragraph -- an indented chunk cannot interrupt one,
    so the line is a lazy continuation.  Reading it as a paragraph break reset
    the one-attempt-per-paragraph state and reopened a table inside a paragraph
    cmark-gfm had already given up on.
    """
    return (
        line.strip(" \t") == ""
        or bool(_ATX_HEADING.match(line))
        or bool(_THEMATIC_BREAK.match(line))
        or bool(_BLOCK_QUOTE.match(line))
        or bool(_LIST_ITEM.match(line))
        or _opens_fence(line)
        or bool(_HTML_BLOCK_INTERRUPTING.match(line))
    )


def _lines(text: str) -> list[Row]:
    rows: list[Row] = []
    offset = 0
    for raw in text.splitlines(keepends=True):
        line = raw.rstrip("\n").rstrip("\r")
        rows.append(Row(offset, offset + len(raw), line, ()))
        offset += len(raw)
    return rows


def _literal_lines(lines: list[Row]) -> list[bool]:
    """Which lines carry no Markdown: fenced code and raw-HTML block interiors.

    Both regions are printed as characters rather than parsed, so a pipe inside
    one is never a cell boundary.  ``ends_table`` already refuses to continue a
    table across the line that *opens* either region; tracking the region itself
    is what stops a table being read out of its interior.
    """
    literal = [False] * len(lines)
    fence: tuple[str, int] | None = None
    html_end: re.Pattern[str] | None = None
    # HTML block condition 7 -- a complete tag alone on its line -- is the one
    # start that may not interrupt a paragraph.  Testing "the line above was
    # blank" read an indented code chunk, a heading and a list marker as
    # paragraph text, so a `</script>` under one of them was left as ordinary
    # content while cmark-gfm opened a raw-HTML block there and printed
    # everything below it verbatim.
    paragraph = False
    for index, row in enumerate(lines):
        line = row.text
        if fence is not None:
            literal[index] = True
            closing = _FENCE_CLOSE.match(line)
            if (closing and closing.group("seq")[0] == fence[0]
                    and len(closing.group("seq")) >= fence[1]):
                fence = None
        elif html_end is not None:
            literal[index] = True
            if html_end.search(line):
                html_end = None
        else:
            opening = _FENCE_OPEN.match(line)
            if opening and not (opening.group("seq")[0] == "`"
                                and "`" in opening.group("info")):
                fence = (opening.group("seq")[0], len(opening.group("seq")))
                literal[index] = True
            else:
                for start, end in _HTML_BLOCK_STARTS:
                    if start.match(line):
                        literal[index] = True
                        html_end = None if end.search(line) else end
                        break
                else:
                    if not paragraph and _HTML_BLOCK_BARE_TAG.match(line):
                        literal[index] = True
                        html_end = _HTML_BLOCK_BLANK_END
        paragraph = not (literal[index] or ends_table(line))
    return literal


def mask_literal_regions(text: str) -> str:
    """Blank literal regions, preserving offsets and line endings."""
    lines = _lines(text)
    literal = _literal_lines(lines)
    return "".join(
        "".join(" " if char not in "\r\n" else char
                for char in text[row.start:row.end])
        if hidden else text[row.start:row.end]
        for row, hidden in zip(lines, literal)
    )


def find_tables(text: str, *, interrupting: bool = False) -> list[Table]:
    """Every block of ``text`` cmark-gfm renders as a table, in source order.

    Recognition is the renderer's own: a header row, then a delimiter row whose
    cell count equals the header's, then body rows until the table breaks.  The
    cell counts must be *equal* -- a delimiter row one column wider drops the
    whole block to paragraph text, which is exactly what an escaped pipe in the
    header buys an author whose gate counts characters instead of cells.

    A paragraph gets one attempt.  cmark-gfm marks a paragraph as visited as
    soon as a delimiter-shaped line inside it fails to match the width of the
    line above, and never opens a table in that paragraph again, so a widened
    delimiter does not merely drop its own table: it also stops any later
    header/delimiter pair in the same paragraph from becoming one.

    ``interrupting`` selects which way to be wrong where the two are exclusive.
    A table may legitimately interrupt a paragraph -- cmark-gfm takes the
    paragraph's last line as the header -- but reading one means reconstructing
    what opened that paragraph, and the residual disagreements this reader has
    with cmark-gfm are all of that shape.  Left false, a header that does not
    begin its own block is declined, which cost nothing in 200k differentially
    fuzzed documents; that is what a caller asking *which rows does this
    published table print* wants, because declining makes the gate report the
    table missing and fail closed.  Set true by a caller asking *where does GFM
    place its cell and row separators*, where omitting a table omits separators
    and so leaves an inline construct joined that GFM may split -- the
    over-suppressing direction, which can hide a published row but can never
    invent one.
    """
    lines = _lines(text)
    literal = _literal_lines(lines)
    # Whether each line may sit inside a list item or a block quote.  A
    # container opens at its marker and keeps holding indented and blank lines
    # after it -- a blank line does not close a list -- so looking only at the
    # current chunk let an indented header two lines below a `- ` marker pose as
    # a top-level table.  A line that returns to column zero without a marker of
    # its own is outside again.  The rule is deliberately coarse: it can only
    # decline a table, never invent one.
    container = []
    inside = False
    for row in lines:
        if _BLOCK_QUOTE.match(row.text) or _LIST_ITEM.match(row.text):
            inside = True
        elif row.text.strip() and not row.text[:1].isspace():
            inside = False
        container.append(inside)
    # Where each paragraph begins: a table this reader will read must be a
    # paragraph's own first line, so the header is never a continuation whose
    # container it would have to reconstruct.
    begins_paragraph = [False] * len(lines)
    open_paragraph = False
    for position, row in enumerate(lines):
        if literal[position] or _closes_paragraph(row.text):
            open_paragraph = False
            continue
        begins_paragraph[position] = not open_paragraph
        open_paragraph = True
    tables: list[Table] = []
    index = 0
    burned = False
    while index + 1 < len(lines):
        header_line = lines[index].text
        delimiter_line = lines[index + 1].text
        # A blank line or any interrupting block start closes the paragraph,
        # and the next one starts with a fresh attempt.
        if literal[index] or _closes_paragraph(header_line):
            burned = False
            index += 1
            continue
        header_cells = split_cells(header_line)
        delimiter_cells = split_cells(delimiter_line)
        # A line of `-` or `=` directly under a paragraph line is that
        # paragraph's setext underline, and cmark-gfm resolves the heading
        # before it looks for a table: in `A` / `--` / `---:` the `--` becomes
        # an `<h2>` underline and never reaches the table scanner.  Reading it
        # as a header conjured a table out of a heading and a stray paragraph.
        underlines_heading = bool(index > 0 and _SETEXT_UNDERLINE.match(header_line)
                                  and not ends_table(lines[index - 1].text))
        delimits = bool(
            delimiter_cells
            and is_delimiter_row(delimiter_cells)
            and not literal[index + 1]
            and not ends_table(delimiter_line)
            and not _SETEXT_UNDERLINE.match(delimiter_line)
        )
        if underlines_heading or not delimits:
            index += 1
            continue
        # The paragraph is burned by the *attempt*, not by the match.  A line
        # that declares no cell at all -- a lone `|` -- is still the header
        # cmark-gfm measures the delimiter against, so a delimiter row under one
        # spends the paragraph's single attempt exactly as a mismatched width
        # does, and no later pair in that paragraph can open a table.
        if not header_cells or len(delimiter_cells) != len(header_cells):
            burned = True
            index += 1
            continue
        # A table that may sit inside a list item or a block quote is declined:
        # this reader does not strip a container prefix, so it cannot read one
        # faithfully.  Two views of "may" are taken together, because each
        # catches what the other misses: the running span, which keeps a list
        # open across the blank lines and indented lines that follow its marker,
        # and the current chunk back to the last blank line, which catches a
        # marker on a line the running span has already closed.  A header that
        # does not itself begin a block is declined for the same reason unless
        # the caller asks otherwise -- see ``interrupting`` above.
        chunk = index
        while chunk > 0 and lines[chunk - 1].text.strip():
            chunk -= 1
        if (burned
                or not (interrupting or begins_paragraph[index])
                or any(container[chunk:index + 2])):
            index += 1
            continue
        # A body line that declares no cell at all -- a lone `|`, or a line
        # indented into a code chunk -- is not a row: cmark-gfm stops the table
        # there rather than padding it out.  Counting it as a row credited the
        # inventory with a row a reader never meets.
        end = index + 2
        while (end < len(lines) and not ends_table(lines[end].text)
               and split_cells(lines[end].text)):
            end += 1
        tables.append(Table(
            header=lines[index]._replace(cells=tuple(header_cells)),
            delimiter=lines[index + 1]._replace(cells=tuple(delimiter_cells)),
            rows=tuple(line._replace(cells=tuple(split_cells(line.text)))
                       for line in lines[index + 2:end]),
        ))
        index = end
    return tables
