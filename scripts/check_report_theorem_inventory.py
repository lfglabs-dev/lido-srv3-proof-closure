#!/usr/bin/env python3
"""Bind the P-ALLOC-1 report's theorem inventory to Lean and to the registry.

The report is a reader-facing surface: a theorem that exists in the guarantee
module but is missing from the inventory reads as if the guarantee had fewer
moving parts than it has, and an inventory row that claims REGISTERED without a
matching `audit/guarantees.yaml` theorem overstates what the published CHECKED
cells assert.  Both directions fail closed here.
"""

import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEAN = ROOT / "LidoSRv3/Audit/Guarantees/PAlloc1.lean"
REPORT = ROOT / "report/P-ALLOC-1.md"
REGISTRY = ROOT / "audit/guarantees.yaml"
GUARANTEE_ID = "P-ALLOC-1"
NAMESPACE = "LidoSRv3.Audit.Guarantees.PAlloc1."
# Registry field -> the plane label an inventory row registered against it must print.
PLANES = {"abstract": "Abstract", "verity": "Verity"}
# A theorem may span both planes, but no registry field records that: `abstract`
# and `verity` each name one theorem for one plane.  The composite label is
# therefore printable by an unregistered row only, and it is not a spelling of
# either plane — checking containment made it one, since it has both labels
# inside it.
COMPOSITE_PLANE = "Abstract and Verity (composite)"
PLANE_COLUMNS = tuple(PLANES.values()) + (COMPOSITE_PLANE,)
REGISTRATION = re.compile(r"^REGISTERED as `(?P<plane>[a-z]+)\.theorem`$")
# The Registered column publishes exactly two markers, and a reader reads the
# cell, not the checker's parse of it.  Skipping every cell that did not start
# with `REGISTERED` treated an unrecognized spelling as a silent "no claim", so
# a row could print a lookalike — lowercase `registered` is the plain case — and
# be read as promoted while this gate stayed green and the registry recorded
# nothing.  The unregistered marker is therefore matched exactly and
# case-sensitively as the whole cell, and anything that is neither marker is
# rejected rather than skipped.
UNREGISTERED = "unregistered"

# A declaration name is not always ASCII.  Lean identifiers allow letter-like
# characters (Greek, Coptic, Latin-1/Extended-A, script and double-struck),
# subscript alphanumerics, `!`/`?`, «guillemet-escaped» atoms, and `.`-joined
# compound names.  An `[A-Za-z0-9_']+` capture does not recognize such a
# declaration at all, so `theorem αUndisclosed` read as no declaration and the
# inventory could omit an ordinary Lean theorem while this gate still reported
# success.  The ranges below are transcribed from the pinned toolchain's
# `Init/Meta/Defs.lean` (`isIdFirst`, `isIdRest`, `isLetterLike`,
# `isSubScriptAlnum`, `idBeginEscape`/`idEndEscape`) so the inventory reads the
# same identifiers Lean does.
LETTER_LIKE = ((0x3B1, 0x3C9), (0x391, 0x3A9), (0x3CA, 0x3FB), (0x1F00, 0x1FFE),
               (0x2100, 0x214F), (0x1D49C, 0x1D59F), (0xC0, 0xFF), (0x100, 0x17F))
# Lean excludes these from the letter-like ranges: they are notation, not names.
LETTER_LIKE_HOLES = (0x3BB, 0x3A0, 0x3A3, 0xD7, 0xF7)  # λ, Π, Σ, ×, ÷
SUBSCRIPT_ALNUM = ((0x2080, 0x2089), (0x2090, 0x209C), (0x1D62, 0x1D6A), (0x2C7C, 0x2C7C))


def _without(ranges, holes):
    kept = []
    for low, high in ranges:
        start = low
        for hole in sorted(h for h in holes if low <= h <= high):
            if hole > start:
                kept.append((start, hole - 1))
            start = hole + 1
        if start <= high:
            kept.append((start, high))
    return kept


def _character_class(ranges):
    return "".join(rf"\U{low:08X}-\U{high:08X}" for low, high in ranges)


_LETTER_LIKE = _without(LETTER_LIKE, LETTER_LIKE_HOLES)
ID_FIRST = "A-Za-z_" + _character_class(_LETTER_LIKE)
ID_REST = "A-Za-z0-9_'!?" + _character_class(_LETTER_LIKE + list(SUBSCRIPT_ALNUM))
# `idBeginEscape`/`idEndEscape`.  The lexical pass below has to agree with this
# spelling exactly: whatever the declaration parser accepts as an escaped atom,
# the comment scanner must read as a name rather than as code.
ESCAPE_BEGIN = "«"
ESCAPE_END = "»"
ATOM = rf"(?:[{ID_FIRST}][{ID_REST}]*|{ESCAPE_BEGIN}[^{ESCAPE_END}\n]*{ESCAPE_END})"
IDENT = rf"{ATOM}(?:\.{ATOM})*"

# Markdown renders a row by its pipes, not by its padding: `| `n`| 1 | ... |` and
# `|  `n`  |  1  | ... |` publish the same table to a reader.  Keying on one exact
# whitespace layout meant a row that renders identically was not seen by this
# gate at all, so a false claim could be printed beside the correct row and
# escape both the cell checks and the duplicate check.  Delimiters are matched
# with tolerant padding instead, and `[^|\n]` keeps a cell from spanning lines so
# a row is still one physical line.
CELL = r"[ \t]*\|[ \t]*"
# A block only starts where Markdown lets one start: at most three spaces of
# indentation, and no tab, since a tab advances to column four.  Accepting any
# leading whitespace read a row out of an indented code block, which renders as
# literal text rather than as a table, so a row a reader never meets still
# counted toward the inventory.
ROW = re.compile(
    rf"^ {{0,3}}\|[ \t]*`(?P<name>{IDENT})`{CELL}(?P<line>\d+){CELL}"
    rf"(?P<plane>[^|\n]*?){CELL}(?P<registered>[^|\n]*?){CELL}"
    rf"(?P<role>[^|\n]*?)[ \t]*\|[ \t]*$",
    re.MULTILINE,
)

# Code fences and HTML comments publish nothing: a reader meets the literal
# characters of a fenced block and meets no part of a comment at all.  A closing
# fence repeats the opening character at least as many times, and a backtick
# fence carries no backtick in its info string.
FENCE_OPEN = re.compile(r"^ {0,3}(?P<seq>`{3,}|~{3,})(?P<info>.*)$")
FENCE_CLOSE = re.compile(r"^ {0,3}(?P<seq>`{3,}|~{3,})[ \t]*$")
COMMENT_OPEN = "<!--"
COMMENT_CLOSE = "-->"

# A comment is only one of CommonMark's seven HTML blocks, and every one of them
# is a non-Markdown region: its lines are passed through as raw HTML, so a pipe
# line inside one is printed as literal text rather than parsed as a row of the
# theorem table.  Recognizing comments alone left every other construct able to
# carry a row that satisfied this gate while the rendered inventory silently
# omitted the theorem — wrapping a required row in `<div>` and `</div>` was
# enough.  All seven start conditions are read here.
#
# Condition 6's tag list is the union of the names the CommonMark revisions give
# it — `search` arrived and `source` left between 0.30 and 0.31.2, and `meta` is
# the spelling `scripts/check_verity_provenance.py` already masks — so a name any
# of them treats as a block still masks here.  Widening it is the safe direction:
# masking a line that in fact renders can only hide a row, which surfaces as a
# declared theorem the inventory omits, while missing a block spelling is what
# lets an unrendered row count.
HTML_BLOCK_NAMES = (
    "address|article|aside|base|basefont|blockquote|body|caption|center|col|"
    "colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|"
    "form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hr|html|iframe|legend|li|"
    "link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|option|p|param|search|"
    "section|source|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul"
)
# Condition 1's elements carry raw text to their own closing tag rather than to
# a blank line, so they are matched before the condition-6 names they overlap.
HTML_RAW_TEXT_NAMES = "script|pre|style|textarea"
HTML_ATTRIBUTE = (
    r"""(?:[ \t]+[A-Za-z_:][A-Za-z0-9_.:-]*"""
    r"""(?:[ \t]*=[ \t]*(?:[^ \t"'=<>`]+|'[^']*'|"[^"]*"))?)"""
)
HTML_TAG = (rf"(?:<[A-Za-z][A-Za-z0-9-]*{HTML_ATTRIBUTE}*[ \t]*/?>"
            rf"|</[A-Za-z][A-Za-z0-9-]*[ \t]*>)")
# Conditions 6 and 7 run to the next blank line; blanking that line is a no-op,
# so an inclusive end pattern spells both endings with one rule.
HTML_BLOCK_BLANK_END = re.compile(r"^[ \t]*$")
HTML_BLOCK_STARTS = (
    (re.compile(rf"^ {{0,3}}<(?:{HTML_RAW_TEXT_NAMES})(?:[ \t]|>|$)", re.IGNORECASE),
     re.compile(rf"</(?:{HTML_RAW_TEXT_NAMES})>", re.IGNORECASE)),
    (re.compile(r"^ {0,3}<\?"), re.compile(r"\?>")),
    (re.compile(r"^ {0,3}<!\[CDATA\["), re.compile(r"\]\]>")),
    # CommonMark 0.30 requires an uppercase letter here and 0.31.2 any ASCII
    # letter; the wider spelling masks a declaration either version accepts.
    (re.compile(r"^ {0,3}<![A-Za-z]"), re.compile(r">")),
    (re.compile(rf"^ {{0,3}}</?(?:{HTML_BLOCK_NAMES})(?:[ \t]|/?>|$)", re.IGNORECASE),
     HTML_BLOCK_BLANK_END),
)
# Condition 7 is a complete tag alone on its line.  It is the one start that may
# not interrupt a paragraph, so it opens a block only after a blank line; a
# pipe line following a tag that opened no block is a paragraph continuation
# rather than a table row either way.
HTML_BLOCK_BARE_TAG = re.compile(rf"^ {{0,3}}{HTML_TAG}[ \t]*$")

# The inventory a reader meets is the `## Theorems` section: that heading is what
# introduces the table as every theorem the module declares, and what explains
# what a REGISTERED cell asserts.  Scanning the whole document instead counted a
# row wherever it happened to sit, so a row moved out of that section — filed
# under `## Resolution`, say — still satisfied the inventory while the published
# table a reader reads had silently dropped it.  Rows are read from the section
# body, and a row printed outside it is rejected rather than quietly counted
# toward the section it is no longer in.
SECTION = re.compile(r"^## Theorems$(?P<body>.*?)(?=^## |\Z)", re.MULTILINE | re.DOTALL)

# A top-level declaration is not always a bare `theorem` in column zero.  Lean
# accepts leading whitespace, attribute blocks, visibility/reducibility
# modifiers, and `lemma` as an alias for `theorem`; every one of those is
# ordinary formatting rather than an exotic spelling.  Matching only the bare
# form would let any of them hide a declaration from the inventory while this
# gate still reported success, so the whole prefix is parsed.  Widening only
# ever finds more declarations to demand rows for, so it cannot loosen the gate.
# `\s+` after the keyword keeps `theorem_like_name` from matching, and
# `-- theorem ...` still cannot, since `--` is neither attribute nor modifier.
#
# Only these three elaborate in front of a `theorem` under the pinned toolchain,
# so only these can hide a declaration that Lean actually accepts.
MODIFIERS_ON_THEOREM = ("private", "protected", "nonrec")
# Lean parses or rejects the rest at the declaration itself rather than at the
# prefix (`'unsafe' theorems are not allowed`, `'partial' theorems are not
# allowed`, `'theorem' subsumes 'noncomputable'`; `scoped`/`local` prefix other
# commands entirely).  They stay in the table because matching a prefix Lean
# would reject only ever demands an extra inventory row and never hides one, and
# because the set is a toolchain detail that may widen.
MODIFIERS_REJECTED_ON_THEOREM = ("scoped", "local", "noncomputable", "unsafe", "partial")
MODIFIERS = MODIFIERS_ON_THEOREM + MODIFIERS_REJECTED_ON_THEOREM
DECL = re.compile(
    r"^[ \t]*"
    r"(?:@\[[^\]]*\][ \t]*)*"
    rf"(?:(?:{'|'.join(MODIFIERS)})[ \t]+)*"
    rf"(?:theorem|lemma)\s+(?P<name>{IDENT})",
    re.MULTILINE,
)

# A declaration's name is its leaf, not its identity: `namespace A` and
# `namespace B` can each declare `collision`, and Lean knows them apart as
# `A.collision` and `B.collision`.  Recording leaves alone let the second
# silently overwrite the first, so one row could stand for two distinct declared
# theorems and the inventory could omit one while this gate reported success.
# The scope commands are tracked here so every theorem is inventoried under the
# fully qualified name Lean gives it.  A `section` opens a scope that closes like
# any other but contributes nothing to a name.
SCOPE = re.compile(
    rf"^[ \t]*(?P<kind>namespace|section|end)"
    rf"(?:[ \t]+(?P<label>{IDENT}))?[ \t]*(?:--[^\n]*)?$",
    re.MULTILINE,
)


def fail(message):
    raise SystemExit(f"report theorem inventory: {message}")


def _comment_spans(line, open_comment):
    """Whether `line` carries comment text, and whether one stays open past it."""
    touched = open_comment
    position = 0
    while True:
        if open_comment:
            close = line.find(COMMENT_CLOSE, position)
            if close == -1:
                return True, True
            open_comment = False
            position = close + len(COMMENT_CLOSE)
        else:
            opened = line.find(COMMENT_OPEN, position)
            if opened == -1:
                return touched, False
            touched = True
            open_comment = True
            position = opened + len(COMMENT_OPEN)


def mask_non_rendered(text):
    """Blank the lines Markdown does not render, preserving every offset.

    A row inside a code fence is printed as literal characters, a row inside an
    HTML comment is printed not at all, and a row inside any other HTML block is
    passed through as raw HTML rather than parsed as a table row.  None of the
    three is a claim a reader ever meets.  Reading the raw file let any of them
    stand in for the published table: the inventory could satisfy this gate with
    a row no reader can see while the rendered table silently omitted the
    theorem, and a `## Theorems` heading quoted inside a fence could relocate the
    section itself.

    Whole lines are blanked rather than the exact spans.  Blanking only the
    characters of `<!--x-->| ... |` would leave a line that opens with a pipe
    and invent a row Markdown renders as raw HTML — the one direction that
    loosens the gate.  Line-at-a-time masking can only ever hide a row, which
    surfaces as a declared theorem the inventory omits.
    """
    lines = text.splitlines(keepends=True)
    fence = None
    html_block = None
    open_comment = False
    previous_blank = True
    for index, raw in enumerate(lines):
        line = raw.rstrip("\n").rstrip("\r")
        masked = False
        if open_comment or COMMENT_OPEN in line:
            masked, open_comment = _comment_spans(line, open_comment)
        elif fence is not None:
            masked = True
            closing = FENCE_CLOSE.match(line)
            if (closing and closing.group("seq")[0] == fence[0]
                    and len(closing.group("seq")) >= fence[1]):
                fence = None
        elif html_block is not None:
            masked = True
            if html_block.search(line):
                html_block = None
        else:
            opening = FENCE_OPEN.match(line)
            if opening and not (opening.group("seq")[0] == "`"
                                and "`" in opening.group("info")):
                fence = (opening.group("seq")[0], len(opening.group("seq")))
                masked = True
            else:
                for start, end in HTML_BLOCK_STARTS:
                    if start.match(line):
                        masked = True
                        html_block = None if end.search(line) else end
                        break
                else:
                    if previous_blank and HTML_BLOCK_BARE_TAG.match(line):
                        masked = True
                        html_block = HTML_BLOCK_BLANK_END
        if masked:
            lines[index] = "".join(" " if c not in "\r\n" else c for c in raw)
        previous_blank = not line.strip()
    return "".join(lines)


def strip_block_comments(text):
    """Blank Lean block comments, preserving every newline and column.

    Lean block comments nest, so `/-.*?-/` closes an outer comment at the first
    inner `-/` and hands the rest of that comment back as source: a prose line
    beginning `theorem ...` inside it is then demanded as an inventory row for a
    theorem Lean never declares, failing the gate on valid source.  Depth is
    tracked here instead.

    `/-` only opens a comment where code is actually being read.  Inside a `--`
    line comment, a string literal, or a «guillemet-escaped» identifier it is
    ordinary text, and treating one as an opener would blank the real
    declarations that follow — the failure direction that matters, since it
    hides theorems rather than inventing them.
    """
    out = []
    index = 0
    depth = 0
    end = len(text)
    while index < end:
        pair = text[index:index + 2]
        if depth:
            if pair in ("/-", "-/"):
                depth += 1 if pair == "/-" else -1
                out.append("  ")
                index += 2
                continue
            # Blanking the body to spaces rather than dropping it keeps every
            # declaration at the line and column it occupies on disk.
            out.append("\n" if text[index] == "\n" else " ")
            index += 1
        elif pair == "/-":
            depth = 1
            out.append("  ")
            index += 2
        elif pair == "--":
            # Lean separates a keyword from its name by whitespace, and a line
            # comment is whitespace to the parser: `theorem -- why\n  name` is
            # one ordinary declaration.  Copying the comment text through left
            # `-- why` sitting between the keyword and the name, so `DECL` could
            # not match across it and the declaration stayed out of the
            # inventory while this gate reported success.  The body is blanked
            # to spaces instead, which keeps every column and the terminating
            # newline, still refuses to let a `/-` inside a comment open one,
            # and cannot invent a declaration: `-- theorem x` blanks away too.
            while index < end and text[index] != "\n":
                out.append(" ")
                index += 1
        elif text[index] == ESCAPE_BEGIN:
            # `«…»` escapes an atom, so its contents are a name rather than
            # code: `theorem «undisclosed /- name»` declares one ordinary
            # theorem and opens no comment.  Lexing the `/-` anyway made a
            # valid module read as an unterminated comment, and a later `-/`
            # inside another escaped atom would rebalance the depth and blank
            # the real declarations in between instead.  The escape cannot span
            # a newline, so an unclosed `«` is ordinary text and must advance by
            # one rather than swallow the rest of the file.
            close = text.find(ESCAPE_END, index + 1)
            newline = text.find("\n", index + 1)
            if close != -1 and (newline == -1 or close < newline):
                out.append(text[index:close + 1])
                index = close + 1
            else:
                out.append(text[index])
                index += 1
        elif text[index] == '"':
            out.append(text[index])
            index += 1
            while index < end:
                if text[index] == "\\" and index + 1 < end:
                    out.append(text[index:index + 2])
                    index += 2
                    continue
                out.append(text[index])
                index += 1
                if text[index - 1] == '"':
                    break
        else:
            out.append(text[index])
            index += 1
    if depth:
        fail(f"{LEAN.relative_to(ROOT)} has an unterminated block comment; the "
             "declarations after it cannot be read, so the inventory cannot be checked")
    return "".join(out)


def declared_theorems():
    # Comments wrap prose that can begin a line with "theorem", so blank them
    # out first while preserving line numbering.
    text = strip_block_comments(LEAN.read_text(encoding="utf-8"))
    found = {}
    # Lean separates the keyword from the name by whitespace, and a newline is
    # whitespace: `theorem\n  name` is one ordinary declaration.  Reading the
    # module a physical line at a time split exactly that form into two halves
    # that each matched nothing — the keyword line carries no name and the name
    # line carries no keyword — so the declaration stayed out of the inventory
    # while this gate reported success.  The stream is scanned instead, and a
    # declaration is recorded at the line its keyword opens, which is where the
    # single-line forms already sat.
    # Scope commands and declarations are replayed in source order so each
    # theorem is recorded under the name Lean gives it rather than under its
    # leaf.  The report names theorems relative to this module's own namespace,
    # which is the prefix its table header prints, so that prefix is dropped and
    # anything declared outside it keeps its fully qualified name.
    events = sorted(
        [(m.start(), "scope", m) for m in SCOPE.finditer(text)]
        + [(m.start(), "decl", m) for m in DECL.finditer(text)],
        key=lambda event: event[0],
    )
    scopes = []
    for position, kind, match in events:
        line = text.count("\n", 0, position) + 1
        if kind == "scope":
            command = match.group("kind")
            label = match.group("label")
            if command == "namespace":
                if not label:
                    fail(f"{LEAN.relative_to(ROOT)}:{line} opens a namespace with no name")
                scopes.append((label, label))
            elif command == "section":
                scopes.append((None, label))
            else:
                if not scopes:
                    fail(f"{LEAN.relative_to(ROOT)}:{line} closes a scope that was never "
                         "opened, so the names that follow cannot be qualified")
                _, opened = scopes.pop()
                # A bare `end` is valid Lean: it closes the nearest open scope
                # regardless of whether that scope was given a label.  Only
                # reject when an explicit label was supplied but does not match.
                if label is not None and label != opened:
                    open_scope = opened or "an anonymous scope"
                    fail(f"{LEAN.relative_to(ROOT)}:{line} closes {label} but "
                         f"{open_scope} is open; the names declared here would be "
                         "qualified under the wrong scope")
            continue
        qualified = ".".join([name for name, _ in scopes if name] + [match.group("name")])
        relative = qualified[len(NAMESPACE):] if qualified.startswith(NAMESPACE) else qualified
        if relative in found:
            fail(f"{LEAN.relative_to(ROOT)} declares {relative} at lines {found[relative]} "
                 f"and {line}; two declarations sharing one inventory name would let a "
                 "single row stand for both")
        found[relative] = line
    if scopes:
        fail(f"{LEAN.relative_to(ROOT)} leaves {len(scopes)} scope(s) open at end of file, "
             "so the declarations inside them cannot be qualified")
    return found


def main():
    lean = declared_theorems()
    if not lean:
        fail(f"no theorem declarations parsed from {LEAN.relative_to(ROOT)}")

    report = mask_non_rendered(REPORT.read_text(encoding="utf-8"))
    # A reader meets every row the table prints, but a name-indexed mapping keeps
    # only the last one: a repeated row was silently discarded rather than
    # checked, so an earlier copy claiming an unregistered theorem is REGISTERED,
    # citing a line the declaration is not on, or naming no recognized plane
    # stayed in the published inventory while the surviving copy kept this gate
    # green.  Every cell the gate reads is shadowed that way, so the repeat
    # itself is rejected before the matches are indexed at all.
    section = SECTION.search(report)
    if not section:
        fail(f"{REPORT.relative_to(ROOT)} has no `## Theorems` section, so the "
             "inventory a reader meets cannot be located")
    stray = sorted({m.group("name") for m in ROW.finditer(report)
                    if not section.start("body") <= m.start() < section.end("body")})
    if stray:
        fail(f"{REPORT.relative_to(ROOT)} prints inventory row(s) outside the "
             f"`## Theorems` section: {', '.join(stray)}; a row filed elsewhere is "
             "still a published claim, and the section is what a reader reads as the "
             "inventory")
    matches = list(ROW.finditer(section.group("body")))
    repeated = sorted(name for name, count in
                      Counter(m.group("name") for m in matches).items() if count > 1)
    if repeated:
        fail(f"{REPORT.relative_to(ROOT)} lists theorem(s) more than once: "
             f"{', '.join(repeated)}; every printed row is a published claim and "
             "must not be shadowed by whichever copy happens to come last")
    rows = {m.group("name"): m for m in matches}

    missing = sorted(set(lean) - set(rows))
    if missing:
        fail(f"{REPORT.relative_to(ROOT)} omits declared theorem(s): {', '.join(missing)}")
    extra = sorted(set(rows) - set(lean))
    if extra:
        fail(f"{REPORT.relative_to(ROOT)} lists theorem(s) absent from Lean: {', '.join(extra)}")

    for name, match in rows.items():
        if int(match.group("line")) != lean[name]:
            fail(f"{name} is declared at Lean line {lean[name]}, "
                 f"inventory says {match.group('line')}")
        plane = match.group("plane").strip()
        if plane not in PLANE_COLUMNS:
            fail(f"{name} has no recognized abstract/Verity plane: {plane!r}")

    row = next(g for g in json.loads(REGISTRY.read_text(encoding="utf-8"))["guarantees"]
               if g["id"] == GUARANTEE_ID)
    registered = {}
    for plane in PLANES:
        theorem = row[plane].get("theorem")
        if theorem and theorem.startswith(NAMESPACE):
            registered[plane] = theorem[len(NAMESPACE):]
    if not registered:
        fail(f"registry records no {NAMESPACE}* theorem for {GUARANTEE_ID}")

    # A REGISTERED cell does not just assert that some registry field names the
    # theorem; it prints which one.  Comparing unordered name sets read only half
    # of that claim, so swapping the two labels left the same set and this gate
    # stayed green while the inventory misidentified which theorem backs each
    # published CHECKED plane.  Each cell is bound to the field it names, and to
    # the plane column the same row prints.
    claimed = {}
    for name, match in rows.items():
        cell = match.group("registered").strip()
        if cell == UNREGISTERED:
            continue
        registration = REGISTRATION.match(cell)
        if not registration or registration.group("plane") not in PLANES:
            fail(f"{name} prints {cell!r} in the Registered column, which is neither the "
                 f"exact marker {UNREGISTERED!r} nor a registration: it names none of the "
                 f"registry fields {', '.join(f'`{p}.theorem`' for p in PLANES)}; the "
                 "column publishes one of two markers, and a lookalike reads to a "
                 "reader as a promotion the registry does not record")
        plane = registration.group("plane")
        if plane in claimed:
            fail(f"{name} and {claimed[plane]} both claim registry field "
                 f"`{plane}.theorem`, which records a single theorem")
        # The row must print the registered plane and nothing wider.  Containment
        # let the composite label stand in for either one, since both are spelled
        # inside it, so a row registered for one plane could publish a claim on
        # both while this gate stayed green.
        if match.group("plane").strip() != PLANES[plane]:
            fail(f"{name} is registered as `{plane}.theorem` but its inventory row "
                 f"prints plane {match.group('plane').strip()!r}, not "
                 f"{PLANES[plane]!r}; the row and its registration disagree about "
                 "which plane the theorem backs")
        claimed[plane] = name
    if claimed != registered:
        fail(f"inventory marks {sorted(claimed.items())} REGISTERED; "
             f"registry names {sorted(registered.items())}")

    print(f"report theorem inventory ok: {len(rows)} {GUARANTEE_ID} theorems, "
          f"{len(registered)} registered")


if __name__ == "__main__":
    sys.exit(main())
