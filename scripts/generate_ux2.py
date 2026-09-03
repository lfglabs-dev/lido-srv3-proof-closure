#!/usr/bin/env python3
"""Generate and check the UX2 per-guarantee display artifacts in `audit/ux2/`.

One JSON record per canonical guarantee, derived only from checked-in inputs:
the assurance registry (`audit/guarantees.yaml`), the source map, the
assumption registry, the README headline boundary, the pinned toolchain, and
the exact Lean declaration of each registered theorem. A record carries what a
reader needs to see one guarantee on its own: the registry wording, the two
registered theorems with their role, plane, file, line span and statement text,
the assumptions with their recorded risk, the open fidelity gaps, the pinned
source spans, and the model-vs-deployed boundary.

`generate` writes the records; `check` re-derives them and fails closed on any
difference, so a record can never say more than the registry and the Lean
sources say. Presentation prose (names, plain English, mathematics) is not
generated here: it lives with the consumer and must cite these records.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import NoReturn

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_metadata  # noqa: E402  (sibling module, located above)
import check_proof_escapes  # noqa: E402  (sibling module, located above)

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = "lido-srv3-ux2-guarantee-v1"
INDEX_SCHEMA = "lido-srv3-ux2-index-v1"
OUTPUT = Path("audit/ux2")
LEAN_ROOT = Path("LidoSRv3/Audit")
LEAN_INPUTS = ("LidoSRv3.lean", "lakefile.lean", "lake-manifest.json", "lean-toolchain")
ROLES = {
    "abstract": "registered abstract Lean parent (audit/guarantees.yaml abstract.theorem)",
    "verity": "registered Verity Executable Contract parent (audit/guarantees.yaml verity.theorem)",
}
THEOREM_COMPONENT = r"(?:«[^»\n]*»|[^\s.«»:({\[\])}⟩]+)"
THEOREM_NAME = rf"{THEOREM_COMPONENT}(?:\.{THEOREM_COMPONENT})*"
DECLARATION = re.compile(
    # Commands are separated by Lean whitespace, not necessarily newlines.
    # Attribute groups may repeat before a single declaration.
    r"(?<!\S)(?:@\[[^\]]*\][ \t]*)*"
    r"(?:(?:private|protected|noncomputable|unsafe|partial|nonrec)[ \t]+)*"
    rf"(theorem|lemma)\s+({THEOREM_NAME})", re.MULTILINE)
MODIFIER_RUN = re.compile(
    r"(?:(?:private|protected|noncomputable|unsafe|partial|nonrec)\s+)*\Z")
# A scope name may follow Lean whitespace (including comments stripped to blank
# lines), but an unnamed scope must not consume the next command as a split-line
# name.  Commands may share a physical line, so scope commands are matched at a
# Lean whitespace boundary rather than only as a whole line.  A qualified scope
# name is a dotted sequence of Lean identifier components; each component may
# be guillemet-escaped and therefore contain whitespace.
SCOPE_COMPONENT = r"(?:«[^»\n]*»|[^\s.«»]+)"
COMMAND_KEYWORD = (
    r"namespace|section|mutual|end|theorem|lemma|def|abbrev|opaque|"
    r"structure|class|inductive|instance|example|macro|syntax|elab|open|"
    r"variable|attribute|set_option|deriving"
)
# A hash command can follow an unnamed `end` on the same line.  It is a new
# command, not the optional name of that `end`.
HASH_COMMAND = r"#[A-Za-z_][A-Za-z0-9_']*"
SCOPE = re.compile(
    r"(?<!\S)(namespace|section|mutual|end)(?![\w'])"
    rf"(?:\s+(?!(?:{COMMAND_KEYWORD}|{HASH_COMMAND})(?:\s|$))"
    rf"({SCOPE_COMPONENT}(?:\.{SCOPE_COMPONENT})*))?")
OPENERS = "([{⟨"
BINDER = re.compile(r"(?:let|have)\b")
WHERE = re.compile(r"where\b")
MATCH = re.compile(r"match\b")
# Equation-style theorem proofs begin their clauses with a depth-zero `|` at
# the start of a subsequent logical line.  It ends the declaration signature
# just as `:=` and `where` do.
ESCAPED_IDENTIFIER = re.compile(r"«[^»\n]*»")
# A quotation can either spell its syntax category (`` `(command | ...)``) or
# inherit it from a command macro's expected result (`` `(theorem ...)``).
# Both begin with the same backtick-parenthesis token sequence, and neither
# form contains active commands for this source scanner to index.
COMMAND_QUOTATION_OPENER = re.compile(r"`\s*\(")
CLOSERS = ")]}⟩"


def fail(message: str) -> NoReturn:
    raise SystemExit(f"ux2 artifact error: {message}")


def load_json(root: Path, relative: str) -> dict:
    return json.loads((root / relative).read_text(encoding="utf-8"))


class Scope:
    """Track Lean `namespace`/`section`/`end` nesting while scanning one file."""

    def __init__(self) -> None:
        self.stack: list[tuple[str, str]] = []

    def enter(self, kind: str, name: str | None) -> None:
        self.stack.append((kind, name or ""))

    def leave(self, name: str | None) -> None:
        if not self.stack:
            fail("`end` without an open namespace or section")
        kind, opened = self.stack.pop()
        if name is not None and name != opened:
            fail(f"`end {name or ''}` closes `{kind} {opened}`")

    def prefix(self) -> str:
        parts = [name for kind, name in self.stack if kind == "namespace"]
        return ".".join(parts)


def statement_end(text: str, start: int) -> int:
    """Offset of the `:=` that ends the signature after `start`.

    That is the first `:=` at bracket depth zero which does not belong to a
    `let` or `have` binding written inside the statement itself (each such
    binder at depth zero that itself binds with `:=` consumes the next
    depth-zero `:=`; a do-notation `let x ← …` consumes nothing), or a
    depth-zero `where` opening a structure-instance proof, or a top-level
    equation clause.
    """
    depth = 0
    pending = 0
    # A result type may itself contain nested top-level `match ... with`
    # expressions. Their arms use the same `|` token as equation-style theorem
    # bodies. Each match has an independent layout boundary, so a stack is
    # required: a nested match must not replace its enclosing match's column.
    # `None` means a `match` is awaiting its first arm; an integer is that
    # match's arm column. Keeping frames rather than one scalar preserves the
    # enclosing match when a nested result match finishes.
    result_match_arm_columns: list[int | None] = []
    index = start
    while index < len(text) - 1:
        char = text[index]
        if char in OPENERS:
            depth += 1
        elif char in CLOSERS:
            depth -= 1
        elif depth == 0 and text.startswith(":=", index):
            if pending == 0:
                return index
            pending -= 1
        elif depth == 0 and word_at(text, index, WHERE):
            return index
        elif depth == 0 and word_at(text, index, MATCH):
            result_match_arm_columns.append(None)
        # `|>` and `<|` are application operators, not match/equation-arm
        # delimiters.  The latter's pipe is one offset after the operator
        # begins, so test both spellings at the current pipe position.
        elif (depth == 0 and char == "|" and not text.startswith("|>", index)
              and not (index and text[index - 1] == "<")):
            column = index - text.rfind("\n", 0, index) - 1
            # A dedented pipe has left one or more nested result matches. Do
            # this before classifying the pipe so the outer match's layout is
            # restored after an inner match ends.
            while (result_match_arm_columns and result_match_arm_columns[-1] is not None
                   and column < result_match_arm_columns[-1]):
                result_match_arm_columns.pop()
            if result_match_arm_columns and result_match_arm_columns[-1] is None:
                # The first arm may share the `match ... with` line. It is
                # still a result-type arm, even though an equation clause may
                # also start on the theorem signature line when no match is
                # active.
                result_match_arm_columns[-1] = column
            elif result_match_arm_columns:
                # This is another arm of the innermost surviving result match.
                pass
            elif equation_clause_at(text, index):
                # Return the preceding newline so the declaration's source
                # span ends on its signature line, rather than on the first
                # body arm. A same-line first equation arm instead ends at
                # the pipe itself, retaining the signature that precedes it.
                line_start = text.rfind("\n", 0, index)
                return index if line_start < start else line_start
        elif depth == 0 and word_at(text, index, BINDER) and binds_with_walrus(text, index):
            pending += 1
            index += 3
        index += 1
    fail("theorem statement never reaches `:=` or `where`")


def equation_clause_at(text: str, index: int) -> bool:
    """Whether `index` is the pipe beginning a top-level equation clause."""
    # A pattern may span physical lines before its arrow.  Search its balanced
    # text, stopping at the next arm or declaration boundary rather than
    # assuming `=>` is on the pipe line (or immediately after it).
    depth = 0
    for cursor in range(index + 1, len(text) - 1):
        char = text[cursor]
        if char in OPENERS:
            depth += 1
        elif char in CLOSERS:
            depth -= 1
        elif depth == 0 and text.startswith("=>", cursor):
            return True
        elif depth == 0 and ((char == "|" and not text.startswith("|>", cursor)
                             and not (cursor and text[cursor - 1] == "<"))
                             or text.startswith(":=", cursor)
                             or word_at(text, cursor, WHERE)):
            return False
    return False


def binds_with_walrus(text: str, start: int) -> bool:
    """Whether the `let`/`have` at `start` binds with `:=` rather than `←`.

    A do-notation bind such as `let x ← act` carries no `:=`, so it must not
    consume the signature's own `:=`; the first depth-zero `:=` or `←` after
    the binder decides.
    """
    depth = 0
    for index in range(start, len(text) - 1):
        char = text[index]
        if char in OPENERS:
            depth += 1
        elif char in CLOSERS:
            depth -= 1
        elif depth == 0 and text.startswith(":=", index):
            return True
        elif depth == 0 and char == "←":
            return False
    return False


def word_at(text: str, index: int, word: re.Pattern) -> bool:
    """True when `word` starts at `index` as a whole word, not inside an identifier."""
    match = word.match(text, index)
    if match is None:
        return False
    before = text[index - 1] if index else ""
    after = text[match.end()] if match.end() < len(text) else ""
    return not before.isalnum() and before not in "_.'«" and after not in "'»"


# An apostrophe is legal inside an ordinary Lean identifier (`foo'a'`), so a
# character-shaped suffix must not be mistaken for a character literal there.
CHAR_LITERAL = re.compile(r"(?<![\w'])'(?:\\.|[^\\'\n])'(?!\w)")


def mask_character_literals(text: str) -> str:
    """Blank Lean character literals while retaining their source offsets."""
    return CHAR_LITERAL.sub(lambda match: " " * len(match.group()), text)


def mask_escaped_identifiers(text: str) -> str:
    """Blank guillemet identifiers for structural scans while retaining offsets."""
    return ESCAPED_IDENTIFIER.sub(lambda match: " " * len(match.group()), text)


def mask_command_quotations(text: str) -> str:
    """Blank parenthesized syntax quotations while retaining source offsets.

    An explicit or inferred-category quoted command is syntax data, not a
    declaration in the surrounding module. Its parentheses are balanced
    independently, so masking the whole quotation prevents declaration and
    scope regexes from interpreting its contents as active Lean commands.
    """
    masked = list(text)
    # Parentheses in escaped identifiers are identifier content, not quotation
    # delimiters.  Keep offsets by scanning an equally sized masked view.
    structural = mask_escaped_identifiers(text)
    index = 0
    while index < len(text):
        opener = COMMAND_QUOTATION_OPENER.match(structural, index)
        if opener is None:
            index += 1
            continue
        # The opening parenthesis ends the opener, regardless of whitespace
        # after the backtick or whether a category was written explicitly.
        end = opener.end()
        depth = 1
        while end < len(text) and depth:
            depth += (structural[end] == "(") - (structural[end] == ")")
            end += 1
        if depth:
            fail("unterminated command quotation")
        for offset in range(index, end):
            if masked[offset] != "\n":
                masked[offset] = " "
        index = end
    return "".join(masked)


def is_attribute_block(text: str) -> bool:
    """Whether `text` is nothing but attribute groups such as `@[simp, reducible]`."""
    rest = text.strip()
    while rest:
        if not rest.startswith("@["):
            return False
        depth = 0
        for offset, char in enumerate(rest[1:], start=1):
            depth += (char == "[") - (char == "]")
            if depth == 0:
                rest = rest[offset + 1:].strip()
                break
        else:
            return False
    return True


def attribute_start(lines: list[str], declaration_line: int) -> int:
    """First line of the attribute block directly above a declaration.

    An attribute may span lines (`@[simp,` then `  reducible]`), so the block
    is the longest run of lines above the declaration that is nothing but
    attribute text; without one, the declaration line.
    """
    start = declaration_line
    candidate: list[str] = []
    for index in range(declaration_line - 1, -1, -1):
        line = lines[index].rstrip()
        if not line.strip() or line.endswith("-/"):
            break
        candidate.insert(0, line)
        block = "\n".join(candidate)
        doc_end = candidate[0].rfind("-/")
        if doc_end >= 0:
            block = candidate[0][doc_end + 2:] + ("\n" + "\n".join(candidate[1:])
                                                   if len(candidate) > 1 else "")
        if is_attribute_block(block):
            start = index
        elif "@[" in block:
            break
    return start


def doc_comment(lines: list[str], declaration_line: int, declaration_column: int) -> str:
    """The `/-- ... -/` block attached to a declaration, or an empty string.

    Lean permits a documentation block and its declaration to share a line.
    Limit that line to the text before the declaration so the existing balanced
    block scan can treat it like a directly preceding documentation line.
    """
    prefix = lines[declaration_line][:declaration_column]
    inline_prefix = prefix.rstrip()
    # Attributes may share the declaration line with its documentation block.
    # Peel only a complete suffix of attribute groups, so ordinary text between
    # a comment and declaration still prevents accidental attachment.
    attribute_offset = next(
        (offset for offset, char in enumerate(inline_prefix)
         if char == "@" and is_attribute_block(inline_prefix[offset:])
         and inline_prefix[:offset].rstrip().endswith("-/")),
        None)
    if inline_prefix.endswith("-/") or attribute_offset is not None:
        lines = [*lines]
        lines[declaration_line] = (
            inline_prefix if attribute_offset is None
            else inline_prefix[:attribute_offset].rstrip())
        index = declaration_line
    else:
        # The final line of a wrapped attribute can share the declaration line:
        #
        #   /-- docs -/ @[simp,
        #     grind] theorem declaration ...
        #
        # In that form neither the text above the declaration nor its same-line
        # prefix alone is an attribute block.  Find a documentation line whose
        # suffix, together with the intervening lines and that prefix, is one
        # complete attribute block, then leave the normal balanced-doc scan at
        # the documentation line.
        wrapped_attribute_start = None
        candidate = [prefix]
        for line_index in range(declaration_line - 1, -1, -1):
            line = lines[line_index].rstrip()
            if not line.strip():
                break
            candidate.insert(0, line)
            doc_end = line.rfind("-/")
            if doc_end < 0:
                continue
            attribute_text = line[doc_end + 2:] + (
                "\n" + "\n".join(candidate[1:]) if len(candidate) > 1 else "")
            if is_attribute_block(attribute_text):
                wrapped_attribute_start = line_index
            break
        if wrapped_attribute_start is not None:
            lines = [*lines]
            lines[wrapped_attribute_start] = lines[wrapped_attribute_start][:
                lines[wrapped_attribute_start].rfind("-/") + 2]
            index = wrapped_attribute_start
        else:
            attribute_line = attribute_start(lines, declaration_line)
            attribute_text = lines[attribute_line].rstrip()
            doc_end = attribute_text.rfind("-/")
            attribute_block = attribute_text[doc_end + 2:] + (
                "\n" + "\n".join(lines[attribute_line + 1:declaration_line])
                if attribute_line + 1 < declaration_line else "")
            if doc_end >= 0 and is_attribute_block(attribute_block):
                lines = [*lines]
                lines[attribute_line] = attribute_text[:doc_end + 2]
                index = attribute_line
            else:
                index = attribute_line - 1
    # Lean treats whitespace and ordinary comments alike between a documentation
    # block and its declaration.  Skip blank lines and ordinary comments,
    # leaving the documentation block itself for the balanced scan below.
    while index >= 0:
        line = lines[index].strip()
        if not line or line.startswith("--"):
            index -= 1
            continue
        # A closing block-comment delimiter may itself be followed by a line
        # comment.  That trailing comment is whitespace to Lean for purposes
        # of attaching the documentation block.
        if re.search(r"-/\s*(?:--.*)?$", line):
            comment_end = index
            comment_start = None
            depth = 0
            while index >= 0:
                for marker in reversed(list(re.finditer(r"/-|-/", lines[index]))):
                    if marker.group() == "-/":
                        depth += 1
                    else:
                        depth -= 1
                        if depth == 0:
                            comment_start = marker.start()
                            break
                if depth == 0:
                    break
                index -= 1
            if (index >= 0 and comment_start is not None
                    and lines[index][comment_start:].startswith("/-")
                    and not lines[index][comment_start:].startswith("/--")):
                before_comment = lines[index][:comment_start].rstrip()
                if before_comment:
                    # An ordinary comment can follow a documentation block on
                    # the same line.  Keep scanning that preceding text rather
                    # than discarding the whole physical line.
                    lines = [*lines]
                    lines[index] = before_comment
                    continue
                index -= 1
                continue
            # The balanced scan below expects its closing delimiter at the
            # physical end of the line.  A trailing line comment is separate
            # Lean whitespace, so remove it from the local scan view.
            lines = [*lines]
            lines[comment_end] = re.sub(r"(?<=-/)\s*--.*$", "", lines[comment_end]).rstrip()
            index = comment_end
        break
    if index < 0 or not lines[index].rstrip().endswith("-/"):
        return ""
    stop = index
    depth = 0
    while index >= 0:
        line = lines[index]
        for marker in reversed(list(re.finditer(r"/-|-/", line))):
            if marker.group() == "-/":
                depth += 1
                continue
            depth -= 1
            if depth == 0:
                # A documentation comment can follow a completed command on
                # the same physical line. The declaration scanner has already
                # established the later theorem boundary; here the only
                # attachment requirement is that the immediately preceding
                # block is a documentation comment (with no intervening text
                # between it and the declaration/attributes).
                if not line[marker.start():].startswith("/--"):
                    return ""
                # A preceding command may share this physical line. Slice
                # from the documentation opener, so displayed documentation
                # never includes executable text before `/--`.
                return "\n".join([line[marker.start():], *lines[index + 1:stop + 1]])
            if depth < 0:
                return ""
        index -= 1
    return ""


def scan_file(root: Path, path: Path) -> dict[str, list[dict]]:
    """Map every fully qualified theorem in one file to its exact declaration."""
    text = path.read_text(encoding="utf-8")
    stripped = mask_character_literals(check_proof_escapes.strip_comments_and_strings(text))
    if stripped.count("\n") != text.count("\n"):
        fail(f"{path}: comment stripping changed the line structure")
    active = mask_command_quotations(stripped)
    structural = mask_escaped_identifiers(active)
    lines = text.splitlines()
    events = sorted(
        [(m.start(), "scope", m) for m in SCOPE.finditer(active)
         # Scope commands embedded in a guillemet identifier are identifier
         # text.  Keep matching against `active` to retain escaped scope names,
         # but require the keyword itself to survive the structural masking.
         if structural.startswith(m.group(1), m.start(1))]
        + [(offset, "theorem", m) for m in DECLARATION.finditer(active)
           # The identifier spelling is kept in `active`, but its structural
           # token must not have originated inside a guillemet identifier.
           if structural.startswith(m.group(1), m.start(1))
           for offset, private in [modifier_run(active, m)] if not private])
    scope = Scope()
    found: dict[str, dict] = {}
    for offset, kind, match in events:
        if kind == "scope":
            apply_scope(scope, match, active)
            continue
        start_line = stripped.count("\n", 0, offset)
        end = statement_end(structural, match.end())
        name = match.group(2)
        # `_root_.name` is an absolute Lean name, not a component beneath the
        # active namespace.  The display key must therefore match Lean's
        # resolved root-level declaration name.
        full = name[len("_root_."):] if name.startswith("_root_.") else \
            ".".join(part for part in (scope.prefix(), name) if part)
        found.setdefault(full, []).append({
            "module": module_name(root, path),
            "file": path.relative_to(root).as_posix(),
            "start_line": start_line + 1,
            "end_line": stripped.count("\n", 0, end) + 1,
            "doc": doc_comment(lines, start_line, offset - text.rfind("\n", 0, offset) - 1),
            "statement": text[offset:end].rstrip(),
        })
    return found


def modifier_run(stripped: str, match: re.Match) -> tuple[int, bool]:
    """Where the modifiers before this `theorem` begin, and whether they
    include `private`.

    Lean reads modifiers across newlines, so the run may sit on the lines
    above the keyword; the declaration then starts there, and its doc comment
    sits above the run. A private theorem gets an inaccessible name and can
    never be the registered declaration, so it must not be indexed under the
    public name it may share.
    """
    run = MODIFIER_RUN.search(stripped, 0, match.start(1))
    return run.start(), "private" in run.group().split()


def apply_scope(scope: Scope, match: re.Match, text: str) -> None:
    keyword, name = match.group(1), match.group(2)
    if keyword == "end":
        # A close label can only name the scope currently on top of the stack.
        # If the apparent label differs and more non-whitespace follows on the
        # same physical line, it is the first word of the next Lean command:
        #
        #   namespace Outer; end universe u
        #
        # `universe u` (and command forms such as `export …` or `include …`)
        # must not be made into an `end universe` merely because this scanner
        # does not enumerate every Lean command keyword.  A lone differing
        # label still remains an error, preserving fail-closed validation of
        # malformed closes such as `namespace A; end B`.
        if (name is not None and scope.stack and name != scope.stack[-1][1]
                and re.search(r"[^\n\S]*\S", text[match.end(2):])):
            name = None
        scope.leave(name)
    else:
        # `mutual` has no scope name.  Its following declaration can be on the
        # next line, and must never become an apparent name for stack matching.
        scope.enter(keyword, None if keyword == "mutual" else name)


def module_name(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()[:-5].replace("/", ".")


def declarations(root: Path) -> dict[str, list[dict]]:
    index: dict[str, list[dict]] = {}
    for path in sorted((root / LEAN_ROOT).rglob("*.lean")):
        for full, records in scan_file(root, path).items():
            index.setdefault(full, []).extend(records)
    return index


def theorem_record(index: dict[str, list[dict]], plane: str, claim: dict) -> dict:
    name = claim["theorem"]
    records = index.get(name, [])
    if len(records) != 1:
        fail(f"{name}: expected exactly one declaration, found {len(records)}")
    return {"plane": plane, "role": ROLES[plane], "status": claim["status"],
            "name": name, **records[0]}


def readme_boundary(root: Path) -> list[str]:
    """Visible sentences of the README headline blockquote, one per item."""
    text = (root / "README.md").read_text(encoding="utf-8")
    match = audit_metadata.README_HEADLINE_BLOCK.match(text)
    if match is None:
        fail("README has no headline blockquote to derive the boundary from")
    items: list[str] = []
    for raw in match.group("block").splitlines():
        line = raw[1:].strip()
        if not line:
            continue
        if line.startswith("- ") or line.startswith("###") or not items:
            items.append(line.lstrip("#- ").strip())
        else:
            items[-1] = f"{items[-1]} {line}"
    return [re.sub(r"\*\*|`", "", item) for item in items]


def assumption_rows(index: dict[str, dict], ids: list[str]) -> list[dict]:
    rows = []
    for identifier in ids:
        row = index.get(identifier)
        if row is None:
            fail(f"assumption {identifier} is not in audit/assumptions.yaml")
        rows.append({key: row[key] for key in
                     ("id", "severity", "risk", "justification", "violation_impact",
                      "validation", "removal_path")})
    return rows


def span_rows(source_map: dict, identifier: str) -> list[dict]:
    targets = [t for t in source_map["targets"] if t["id"] == identifier]
    if len(targets) != 1:
        fail(f"{identifier}: expected one source-map target, found {len(targets)}")
    return [{key: span[key] for key in
             ("path", "function", "start_line", "end_line", "source_sha", "permalink")}
            for span in targets[0]["spans"]]


def kill_line_modules(command: str) -> list[str]:
    return [word for word in command.split() if word.startswith("LidoSRv3.Tests.")]


def build_record(row: dict, position: int, context: dict) -> dict:
    return {
        "schema": SCHEMA,
        "id": row["id"],
        "position": position,
        "summary": row["summary"],
        "classification": row["classification"],
        "next_gate": row["next_gate"],
        "roadmap_priority": row["roadmap_priority"],
        "theorems": [theorem_record(context["declarations"], plane, row[plane])
                     for plane in ("abstract", "verity")],
        "kill_lines": {"modules": kill_line_modules(row["reproduction"]["command"]),
                       "reproduction": row["reproduction"]},
        "assumptions": assumption_rows(context["assumptions"], row["assumptions"]),
        "fidelity": {"covered": row["fidelity"]["covered"],
                     "missing": row["fidelity"]["missing"],
                     "open_gap_count": len(row["fidelity"]["missing"])},
        "source_spans": span_rows(context["source_map"], row["id"]),
        "boundary": {"model_not_deployment": context["boundary"],
                     "not_covered": row["fidelity"]["missing"]},
    }


def canonical_rows(registry: dict) -> list[dict]:
    rows = registry["guarantees"][:len(audit_metadata.CANONICAL_IDS)]
    if [row["id"] for row in rows] != audit_metadata.CANONICAL_IDS:
        fail("registry canonical rows differ from CANONICAL_IDS")
    return rows


def render(record: dict) -> str:
    return json.dumps(record, indent=2, ensure_ascii=False) + "\n"


def git_blob(data: bytes) -> bytes:
    return hashlib.sha1(b"blob %d\0" % len(data) + data).digest()


def git_file_mode(path: Path) -> bytes:
    """Git's regular-file mode for `path`, based on its executable bit."""
    return b"100755" if path.stat().st_mode & 0o111 else b"100644"


def git_tree(directory: Path) -> bytes | None:
    """The Git tree object id of a directory, computed without a Git object store.

    Git records no empty directory, so a directory with no file below it
    yields `None` and is left out of its parent, exactly as `git mktree` on the
    committed tree leaves it out. A symlink is refused: Git and the receipt
    would bind only its link text while Lean reads its target, so the tree id
    could no longer attest what the scanner and the proof read.
    """
    entries = []
    for child in directory.iterdir():
        if child.is_symlink():
            fail(f"{child} is a symlink; the checked Lean inputs must be regular files")
        if child.is_dir():
            subtree = git_tree(child)
            if subtree is not None:
                entries.append((child.name + "/", b"40000", child.name, subtree))
        else:
            entries.append((child.name, git_file_mode(child), child.name, git_blob(child.read_bytes())))
    if not entries:
        return None
    entries.sort(key=lambda entry: entry[0])
    body = b"".join(mode + b" " + name.encode("utf-8") + b"\0" + digest
                    for _, mode, name, digest in entries)
    return hashlib.sha1(b"tree %d\0" % len(body) + body).digest()


def lean_source_tree(root: Path) -> str:
    """Git tree id of the checked Lean inputs, the same virtual tree
    `scripts/verified_source_tree.sh` hashes and `make prove` records in the
    proof receipt, so a consumer can bind a copy of the records to the exact
    proof revision it displays through that receipt.

    The `LidoSRv3` entry itself must be a real directory: Git records a
    symlinked root as a `120000` blob holding the link text, never as the
    `040000` tree of its target, so hashing through the link would attest a
    tree the receipt cannot contain."""
    for name in LEAN_INPUTS:
        if (root / name).is_symlink():
            fail(f"{name} is a symlink; the checked Lean inputs must be regular files")
        if not (root / name).is_file():
            fail(f"missing Lean input {name}")
    lean_dir = root / "LidoSRv3"
    if lean_dir.is_symlink():
        fail("LidoSRv3 is a symlink; the checked Lean inputs must be a regular directory")
    if not lean_dir.is_dir():
        fail("missing Lean input LidoSRv3/")
    subtree = git_tree(lean_dir)
    if subtree is None:
        fail("LidoSRv3/ holds no Lean input")
    entries = [("LidoSRv3/", b"40000", "LidoSRv3", subtree)]
    entries += [(name, git_file_mode(root / name), name, git_blob((root / name).read_bytes()))
                for name in LEAN_INPUTS]
    entries.sort(key=lambda entry: entry[0])
    body = b"".join(mode + b" " + name.encode("utf-8") + b"\0" + digest
                    for _, mode, name, digest in entries)
    return hashlib.sha1(b"tree %d\0" % len(body) + body).hexdigest()


def generate(root: Path) -> dict[str, str]:
    registry = load_json(root, "audit/guarantees.yaml")
    source_map = load_json(root, "audit/source-map.yaml")
    assumptions = load_json(root, "audit/assumptions.yaml")
    context = {
        "declarations": declarations(root),
        "assumptions": {row["id"]: row for row in assumptions["assumptions"]},
        "source_map": source_map,
        "boundary": readme_boundary(root),
    }
    rows = canonical_rows(registry)
    files = {f"{row['id']}.json": render(build_record(row, position, context))
             for position, row in enumerate(rows, start=1)}
    files["index.json"] = render({
        "schema": INDEX_SCHEMA,
        "pinned_source": source_map["pinned_source"],
        "verity_commit": audit_metadata.PINNED["verity"][1],
        "lean_toolchain": (root / "lean-toolchain").read_text(encoding="utf-8").strip(),
        "lean_source_tree": lean_source_tree(root),
        "boundary": context["boundary"],
        "guarantees": [{"id": row["id"], "file": f"{row['id']}.json"} for row in rows],
    })
    return files


def check(root: Path, files: dict[str, str]) -> None:
    output = root / OUTPUT
    present = {path.name for path in output.glob("*.json")} if output.is_dir() else set()
    stale = sorted(present - set(files))
    if stale:
        fail(f"{OUTPUT} has artifacts no registry row derives: {', '.join(stale)}")
    for name, expected in files.items():
        path = output / name
        if not path.is_file():
            fail(f"{OUTPUT / name} is missing; run `scripts/generate_ux2.py generate`")
        if path.read_text(encoding="utf-8") != expected:
            fail(f"{OUTPUT / name} differs from the registry and Lean sources; "
                 "run `scripts/generate_ux2.py generate`")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("generate", "check"))
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    root = args.root.resolve()
    files = generate(root)
    if args.mode == "check":
        check(root, files)
        print(f"ux2 artifacts ok: {len(files) - 1} guarantee records match the registry "
              "and the Lean declarations")
        return
    (root / OUTPUT).mkdir(parents=True, exist_ok=True)
    for path in (root / OUTPUT).glob("*.json"):
        if path.name not in files:
            path.unlink()
    for name, text in files.items():
        (root / OUTPUT / name).write_text(text, encoding="utf-8")
    print(f"generated {len(files)} files under {OUTPUT}")


if __name__ == "__main__":
    main()
