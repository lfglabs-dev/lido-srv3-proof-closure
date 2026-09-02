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
DECLARATION = re.compile(
    r"^[ \t]*(?:@\[[^\]]*\][ \t]*)?(?:(?:private|protected|nonrec)[ \t]+)*"
    r"theorem[ \t]+([^\s:({\[]+)", re.MULTILINE)
SCOPE = re.compile(r"^[ \t]*(namespace|section|end)(?:[ \t]+([^\s]+))?[ \t]*$", re.MULTILINE)
OPENERS = "([{⟨"
BINDER = re.compile(r"(?:let|have)\b")
WHERE = re.compile(r"where\b")
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
        if (name or "") != opened:
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
    depth-zero `where` opening a structure-instance proof.
    """
    depth = 0
    pending = 0
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
        elif depth == 0 and word_at(text, index, BINDER) and binds_with_walrus(text, index):
            pending += 1
            index += 3
        index += 1
    fail("theorem statement never reaches `:=` or `where`")


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
    return bool(word.match(text, index)) and not text[index - 1].isalnum() \
        and text[index - 1] not in "_.'"


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
    for index in range(declaration_line - 1, -1, -1):
        line = lines[index].rstrip()
        if not line.strip() or line.endswith("-/"):
            break
        if is_attribute_block("\n".join(lines[index:declaration_line])):
            start = index
    return start


def doc_comment(lines: list[str], declaration_line: int) -> str:
    """The `/-- ... -/` block directly above a declaration, or an empty string."""
    index = attribute_start(lines, declaration_line) - 1
    if index < 0 or not lines[index].rstrip().endswith("-/"):
        return ""
    stop = index
    while index >= 0 and not lines[index].lstrip().startswith("/--"):
        index -= 1
    if index < 0:
        return ""
    return "\n".join(lines[index:stop + 1])


def scan_file(root: Path, path: Path) -> dict[str, list[dict]]:
    """Map every fully qualified theorem in one file to its exact declaration."""
    text = path.read_text(encoding="utf-8")
    stripped = check_proof_escapes.strip_comments_and_strings(text)
    if stripped.count("\n") != text.count("\n"):
        fail(f"{path}: comment stripping changed the line structure")
    lines = text.splitlines()
    events = sorted(
        [(m.start(), "scope", m) for m in SCOPE.finditer(stripped)]
        + [(m.start(), "theorem", m) for m in DECLARATION.finditer(stripped)])
    scope = Scope()
    found: dict[str, dict] = {}
    for offset, kind, match in events:
        if kind == "scope":
            apply_scope(scope, match)
            continue
        start_line = stripped.count("\n", 0, offset)
        end = statement_end(stripped, match.end())
        line_start = stripped.rfind("\n", 0, offset) + 1
        full = ".".join(part for part in (scope.prefix(), match.group(1)) if part)
        found.setdefault(full, []).append({
            "module": module_name(root, path),
            "file": path.relative_to(root).as_posix(),
            "start_line": start_line + 1,
            "end_line": stripped.count("\n", 0, end) + 1,
            "doc": doc_comment(lines, start_line),
            "statement": text[line_start:end].rstrip(),
        })
    return found


def apply_scope(scope: Scope, match: re.Match) -> None:
    keyword, name = match.group(1), match.group(2)
    if keyword == "end":
        scope.leave(name)
    else:
        scope.enter(keyword, name)


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


def git_tree(directory: Path) -> bytes | None:
    """The Git tree object id of a directory, computed without a Git object store.

    Git records no empty directory, so a directory with no file below it
    yields `None` and is left out of its parent, exactly as `git mktree` on the
    committed tree leaves it out.
    """
    entries = []
    for child in directory.iterdir():
        if child.is_dir():
            subtree = git_tree(child)
            if subtree is not None:
                entries.append((child.name + "/", b"40000", child.name, subtree))
        else:
            mode = b"100755" if child.stat().st_mode & 0o111 else b"100644"
            entries.append((child.name, mode, child.name, git_blob(child.read_bytes())))
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
    proof revision it displays through that receipt."""
    for name in LEAN_INPUTS:
        if not (root / name).is_file():
            fail(f"missing Lean input {name}")
    subtree = git_tree(root / "LidoSRv3")
    if subtree is None:
        fail("LidoSRv3/ holds no Lean input")
    entries = [("LidoSRv3/", b"40000", "LidoSRv3", subtree)]
    entries += [(name, b"100644", name, git_blob((root / name).read_bytes())) for name in LEAN_INPUTS]
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
    for name, text in files.items():
        (root / OUTPUT / name).write_text(text, encoding="utf-8")
    print(f"generated {len(files)} files under {OUTPUT}")


if __name__ == "__main__":
    main()
