#!/usr/bin/env python3
r"""Pinned cases for the shared cmark-gfm table reader.

Every expectation below was read off cmark-gfm -- the renderer GitHub runs --
and frozen here so the reader cannot drift away from it without a failure.  The
three cases the reader deliberately declines are marked as such and carry the
rendered result beside the declined one, so a decline can never be mistaken for
agreement and widening one later is a visible edit rather than a silent one.

The suite runs with no third-party dependency.  When `cmarkgfm` happens to be
importable it is also used as a live oracle over the same corpus and over the
repository's own published Markdown surfaces, which is how the frozen values
were obtained in the first place; when it is not, the frozen values stand on
their own and the run says so rather than quietly skipping.
"""

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import gfm_table  # noqa: E402  (sibling module, located above)

# (name, source, interrupting, tables the reader must return, tables cmark-gfm
# renders).  The last two differ only where the reader declines a form it does
# not read faithfully; a decline is always the empty list, because declining
# half a table is not one of its options.
CASES = (
    ("plain",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n",
     False, [(2, 1)], [(2, 1)]),
    # The certified defect: an escaped pipe is a `|` character that delimits no
    # cell, so this header declares two cells under a three-cell delimiter and
    # cmark-gfm renders no table whatsoever.  Counting `|` characters made the
    # two agree.
    ("escaped pipe in the header, delimiter widened to match the characters",
     "| A \\| Z | B |\n| --- | --- | --- |\n| 1 | 2 |\n",
     False, [], []),
    ("the same header at its own true width",
     "| A \\| Z | B |\n| --- | --- |\n| 1 | 2 |\n",
     False, [(2, 1)], [(2, 1)]),
    # cmark-gfm's table scanner reads `\|` as an escape without counting the
    # backslashes in front of it, so a doubled backslash does not restore the
    # cell boundary the way CommonMark inline parsing would.
    ("a doubled backslash still escapes the pipe",
     "| A \\\\| Z | B |\n| --- | --- |\n| 1 | 2 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("so the same header declares no one-column table",
     "| A \\\\| Z | B |\n| --- |\n| 1 |\n",
     False, [], []),
    ("nor does a tripled one",
     "| A \\\\\\| Z | B |\n| --- |\n| 1 |\n",
     False, [], []),
    ("an escaped pipe inside a body cell keeps the row's width",
     "| A | B |\n| --- | --- |\n| 1 \\| x | 2 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("the outer pipes are optional",
     "A | B\n--- | ---\n1 | 2\n",
     False, [(2, 1)], [(2, 1)]),
    ("and a one-column table needs no pipe at all",
     "text\n:---\nrow\n",
     False, [(1, 1)], [(1, 1)]),
    ("a setext underline is resolved before any table",
     "A\n---\nB\n",
     False, [], []),
    ("an empty delimiter cell underlines nothing",
     "| A | B |\n|   |   |\n| 1 | 2 |\n",
     False, [], []),
    ("alignment colons are part of a valid delimiter",
     "| A | B |\n| :--- | ---: |\n| 1 | 2 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("three columns of indentation is ordinary block markup",
     "   | A | B |\n  | --- | --- |\n | 1 | 2 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("the fourth makes an indented chunk",
     "| A | B |\n    | --- | --- |\n| 1 | 2 |\n",
     False, [], []),
    # Where the body stops is the other half of the certified defect: a row
    # moved below the table is not in it, and a line that carries no pipe has
    # not left it.
    ("a line carrying no pipe is a further row",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\nplain\n| 3 | 4 |\n",
     False, [(2, 3)], [(2, 3)]),
    ("a blank line ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("an ATX heading ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n## h\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("a thematic break ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n***\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("a block quote ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n> q\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("a list item ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n- i\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("a code fence ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n```\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("an HTML block ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n<div>\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    # A table row is not a paragraph, so HTML block condition 7 -- a complete
    # tag alone on its line -- starts a block here even though it may not
    # interrupt a paragraph.
    ("a lone complete tag ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n<span>\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("an HTML comment ends the body",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n<!-- c -->\n| 3 | 4 |\n",
     False, [(2, 1)], [(2, 1)]),
    ("a backtick fence carrying a backtick in its info string opens nothing",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n``a`b\n| 3 | 4 |\n",
     False, [(2, 3)], [(2, 3)]),
    ("a lone pipe declares no cell, so it underlines nothing",
     "|\n| --- |\n| 1 |\n",
     False, [], []),
    ("and stops the body where it stands",
     "| A |\n| --- |\n| 1 |\n|\n| 2 |\n",
     False, [(1, 1)], [(1, 1)]),
    # One attempt per paragraph: a widened delimiter does not merely drop its
    # own table, it spends the paragraph's only attempt.
    ("a paragraph gets one attempt",
     "A | B\n--- | --- | ---\nC | D\n--- | ---\n1 | 2\n",
     False, [], []),
    ("and a blank line restores it",
     "A | B\n--- | --- | ---\n\nC | D\n--- | ---\n1 | 2\n",
     False, [(2, 1)], [(2, 1)]),
    ("cells are split before inline parsing, so a code span does not hold a pipe",
     "| A `x | y` B | C |\n| --- | --- | --- |\n| 1 | 2 | 3 |\n",
     False, [(3, 1)], [(3, 1)]),
    ("two tables separated by a blank line",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n\n| C | D |\n| --- | --- |\n| 3 | 4 |\n",
     False, [(2, 1), (2, 1)], [(2, 1), (2, 1)]),
    ("a second header inside a body is just another row",
     "| A | B |\n| --- | --- |\n| 1 | 2 |\n| A | B |\n| --- | --- |\n| 3 | 4 |\n",
     False, [(2, 4)], [(2, 4)]),
    # The three declines.  Each is a table cmark-gfm renders and this reader
    # will not read, because reading it means reconstructing a container prefix
    # or the block that opened a paragraph.  Declining makes a caller report the
    # table missing and fail closed; reporting one that renders as paragraph
    # text is the failure the module exists to remove.
    ("declined: a table indented inside a list item",
     "- item\n\n  | A | B |\n  | --- | --- |\n  | 1 | 2 |\n",
     False, [], [(2, 1)]),
    ("declined: a table inside a block quote",
     "> | A | B |\n> | --- | --- |\n> | 1 | 2 |\n",
     False, [], [(2, 1)]),
    ("declined: a table interrupting a paragraph",
     "prose\n| A | B |\n| --- | --- |\n| 1 | 2 |\n",
     False, [], [(2, 1)]),
    ("read when the caller asks for interrupting tables",
     "prose\n| A | B |\n| --- | --- |\n| 1 | 2 |\n",
     True, [(2, 1)], [(2, 1)]),
)

# The published surfaces the gates read, so a reader change that would move a
# real table is caught against the documents it actually reads.
SURFACES = ("README.md", "report/P-ALLOC-1.md", "proofs/LOCKFILE.md", "audit/STATUS.md")


def fail(message):
    raise SystemExit(f"gfm_table: {message}")


def shape(tables):
    return [(t.columns, len(t.rows)) for t in tables]


def check_frozen():
    for name, source, interrupting, expected, _rendered in CASES:
        actual = shape(gfm_table.find_tables(source, interrupting=interrupting))
        if actual != expected:
            fail(f"{name}: reader returned {actual}, pinned {expected}\n{source!r}")


def check_offsets():
    """The body window a caller slices must be the table's own rows."""
    source = ("intro\n\n| A | B |\n| --- | --- |\n| 1 | 2 |\n| 3 | 4 |\n\n"
              "| 5 | 6 |\n")
    tables = gfm_table.find_tables(source)
    if len(tables) != 1:
        fail(f"offset fixture read {len(tables)} tables, expected one")
    table = tables[0]
    body = source[table.body_start:table.body_end]
    if body != "| 1 | 2 |\n| 3 | 4 |\n":
        fail(f"body window is {body!r}; the row below the blank line is not in the table")
    if source[table.start:table.end] != ("| A | B |\n| --- | --- |\n"
                                         "| 1 | 2 |\n| 3 | 4 |\n"):
        fail("the table window does not cover exactly its header, delimiter and rows")
    if [row.text for row in table.rows] != ["| 1 | 2 |", "| 3 | 4 |"]:
        fail(f"row texts are {[row.text for row in table.rows]}")
    if [cell.strip() for cell in table.rows[0].cells] != ["1", "2"]:
        fail(f"row cells are {table.rows[0].cells}")
    empty = gfm_table.find_tables("| A | B |\n| --- | --- |\n")
    if not empty or empty[0].body_start != empty[0].body_end:
        fail("a table with no body row must report an empty body window")


def check_cells():
    """The cell split itself, where the certified defect lives."""
    for line, expected in (
        ("| a | b |", ["a", "b"]),
        (r"| a \| b |", [r"a \| b"]),
        (r"| a \\| b |", [r"a \\| b"]),
        (r"a\|b", [r"a\|b"]),
        ("a|b", ["a", "b"]),
        ("|", []),
        ("   |   ", []),
        ("||", [""]),
        ("| |", [""]),
        ("    | a | b |", []),
        ("plain text", ["plain text"]),
        ("", []),
    ):
        actual = [cell.strip() for cell in gfm_table.split_cells(line)]
        if actual != [cell.strip() for cell in expected]:
            fail(f"split_cells({line!r}) = {actual}, expected {expected}")


def differential():
    """Use cmark-gfm as a live oracle when it is installed."""
    if importlib.util.find_spec("cmarkgfm") is None:
        return ("no cmark-gfm installed; the pinned expectations above are the "
                "renderer's own answers, recorded when they were taken")
    import re

    import cmarkgfm

    def rendered(source):
        html = cmarkgfm.github_flavored_markdown_to_html(source)
        out = []
        for table in re.findall(r"<table>(.*?)</table>", html, re.S):
            head = re.search(r"<thead>(.*?)</thead>", table, re.S)
            body = re.search(r"<tbody>(.*?)</tbody>", table, re.S)
            out.append((len(re.findall(r"<th[ >]", head.group(0))) if head else 0,
                        body.group(0).count("<tr>") if body else 0))
        return out

    for name, source, interrupting, _expected, pinned in CASES:
        actual = rendered(source)
        if actual != pinned:
            fail(f"{name}: cmark-gfm now renders {actual}, pinned {pinned}\n{source!r}")
    for relative in SURFACES:
        source = (ROOT / relative).read_text(encoding="utf-8")
        mine = shape(gfm_table.find_tables(source))
        theirs = rendered(source)
        pool = list(theirs)
        for columns, rows in mine:
            for index, (their_columns, their_rows) in enumerate(pool):
                if their_columns == columns and rows <= their_rows:
                    pool.pop(index)
                    break
            else:
                fail(f"{relative}: the reader reports a {columns}-column table with "
                     f"{rows} row(s) that cmark-gfm does not render; it renders {theirs}")
        if mine != theirs:
            fail(f"{relative}: reader reports {mine}, cmark-gfm renders {theirs}")
    return (f"cross-checked live against cmark-gfm on {len(CASES)} cases and "
            f"{len(SURFACES)} published surfaces")


def main():
    check_frozen()
    check_offsets()
    check_cells()
    declined = sum(1 for *_, expected, rendered_ in CASES if expected != rendered_)
    print(f"gfm table reader ok: {len(CASES)} pinned cmark-gfm cases "
          f"({declined} deliberately declined), body-window offsets, and the cell "
          f"split; {differential()}")


if __name__ == "__main__":
    main()
