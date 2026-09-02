#!/usr/bin/env python3
"""Negative regressions for the UX2 per-guarantee artifact generator."""

from __future__ import annotations

import contextlib
import io
import json
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import check_proof_escapes  # noqa: E402  (sibling module, located above)
import generate_ux2  # noqa: E402  (sibling module, located above)

FILES = (
    "README.md",
    "lean-toolchain",
    "audit/guarantees.yaml",
    "audit/source-map.yaml",
    "audit/assumptions.yaml",
)


def invoke(root: Path, mode: str) -> tuple[bool, str]:
    """Run the generator in-process and report (succeeded, printed text)."""
    out = io.StringIO()
    argv = sys.argv
    sys.argv = ["generate_ux2.py", mode, "--root", str(root)]
    try:
        with contextlib.redirect_stdout(out):
            generate_ux2.main()
        return True, out.getvalue()
    except SystemExit as stop:
        return False, f"{stop}"
    finally:
        sys.argv = argv


def expect(root: Path, mode: str, succeeds: bool, diagnostic: str = "") -> None:
    ok, text = invoke(root, mode)
    if ok != succeeds:
        raise SystemExit(f"unexpected {mode} result ({ok}): {text}")
    if diagnostic and diagnostic not in text:
        raise SystemExit(f"missing diagnostic {diagnostic!r}: {text}")


def copy_tree(destination: Path) -> None:
    for relative in FILES:
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, target)
    shutil.copytree(ROOT / "LidoSRv3/Audit/Guarantees", destination / "LidoSRv3/Audit/Guarantees")
    shutil.copytree(ROOT / "audit/ux2", destination / "audit/ux2")


def rewrite(path: Path, old: str, new: str) -> str:
    original = path.read_text(encoding="utf-8")
    if old not in original:
        raise SystemExit(f"fixture {path.name} lost {old!r}")
    path.write_text(original.replace(old, new, 1), encoding="utf-8")
    return original


def check_artifact_drift(fixture: Path) -> None:
    record = fixture / "audit/ux2/P-ALLOC-1.json"
    original = rewrite(record, '"position": 1', '"position": 11')
    expect(fixture, "check", False, "differs from the registry and Lean sources")
    record.write_text(original, encoding="utf-8")

    bogus = fixture / "audit/ux2/P-BOGUS.json"
    bogus.write_text("{}\n", encoding="utf-8")
    expect(fixture, "check", False, "artifacts no registry row derives")
    bogus.unlink()

    record.unlink()
    expect(fixture, "check", False, "P-ALLOC-1.json is missing")
    expect(fixture, "generate", True, "generated 12 files")
    expect(fixture, "check", True, "11 guarantee records match")


def check_registry_binding(fixture: Path) -> None:
    registry = fixture / "audit/guarantees.yaml"
    original = rewrite(registry, "PAlloc1.checked_execute", "PAlloc1.checked_execute_gone")
    expect(fixture, "check", False, "expected exactly one declaration, found 0")
    registry.write_text(original, encoding="utf-8")

    duplicate = fixture / "LidoSRv3/Audit/Guarantees/Duplicate.lean"
    duplicate.write_text(
        "namespace LidoSRv3.Audit.Guarantees.PAlloc1\n"
        "theorem checked_execute : True := trivial\n"
        "end LidoSRv3.Audit.Guarantees.PAlloc1\n", encoding="utf-8")
    expect(fixture, "check", False, "expected exactly one declaration, found 2")
    duplicate.unlink()

    data = json.loads(registry.read_text(encoding="utf-8"))
    data["guarantees"][0], data["guarantees"][1] = data["guarantees"][1], data["guarantees"][0]
    registry.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    expect(fixture, "check", False, "differ from CANONICAL_IDS")
    registry.write_text(original, encoding="utf-8")

    original = rewrite(registry, '"A-VERITY-SCAFFOLD"', '"A-NOT-A-REGISTERED-ASSUMPTION"')
    expect(fixture, "check", False, "is not in audit/assumptions.yaml")
    registry.write_text(original, encoding="utf-8")

    source_map = fixture / "audit/source-map.yaml"
    original = rewrite(source_map, '"id": "P-ALLOC-1"', '"id": "P-ALLOC-1-RENAMED"')
    expect(fixture, "check", False, "expected one source-map target, found 0")
    source_map.write_text(original, encoding="utf-8")

    readme = fixture / "README.md"
    original = rewrite(readme, "\n> ### These are proofs", "\n### These are proofs")
    expect(fixture, "check", False, "no headline blockquote")
    readme.write_text(original, encoding="utf-8")


def check_lean_scanner(fixture: Path) -> None:
    """Scope tracking, doc comments, and statement slicing on a synthetic module."""
    module = fixture / "LidoSRv3/Audit/Guarantees/Synthetic.lean"
    module.write_text(
        "import LidoSRv3.Audit.Spec\n"
        "namespace Outer.Inner\n"
        "section Helpers\n"
        "/-- Doc for one. -/\n"
        "@[simp]\n"
        "theorem one (x : Nat := 3) : x = x := rfl\n"
        "end Helpers\n"
        "section\n"
        "theorem two : True := by\n"
        "  trivial\n"
        "end\n"
        "namespace Deep\n"
        "protected theorem three : True :=\n"
        "  trivial\n"
        "end Deep\n"
        "end Outer.Inner\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    expected = {
        "Outer.Inner.one": ("theorem one (x : Nat := 3) : x = x", "/-- Doc for one. -/", 6, 6),
        "Outer.Inner.two": ("theorem two : True", "", 9, 9),
        "Outer.Inner.Deep.three": ("protected theorem three : True", "", 13, 13),
    }
    if set(found) != set(expected):
        raise SystemExit(f"scanner resolved {sorted(found)}")
    for name, (statement, doc, start, end) in expected.items():
        (record,) = found[name]
        got = (record["statement"], record["doc"], record["start_line"], record["end_line"])
        if got != (statement, doc, start, end):
            raise SystemExit(f"{name}: scanner produced {got}")

    module.write_text("end Nothing\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "`end` without an open namespace")
    module.write_text("namespace A\nend B\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "`end B` closes `namespace A`")
    module.write_text("theorem open_ended (x : Nat) : x = x\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "never reaches `:=`")
    module.write_text("/-- orphan -/\n\ntheorem gap : True := trivial\n", encoding="utf-8")
    (record,) = generate_ux2.scan_file(fixture, module)["gap"]
    if record["doc"] != "":
        raise SystemExit("a doc comment separated by a blank line was attached")
    module.write_text("-- not a doc -/\ntheorem tail : True := trivial\n", encoding="utf-8")
    (record,) = generate_ux2.scan_file(fixture, module)["tail"]
    if record["doc"] != "":
        raise SystemExit("a line comment ending in -/ was read as a doc comment")
    module.write_text("theorem plain : True := trivial\n", encoding="utf-8")
    strip = check_proof_escapes.strip_comments_and_strings
    check_proof_escapes.strip_comments_and_strings = lambda source: source.replace("\n", " ")
    try:
        expect_scan_failure(fixture, module, "changed the line structure")
    finally:
        check_proof_escapes.strip_comments_and_strings = strip
    module.unlink()


def expect_scan_failure(fixture: Path, module: Path, diagnostic: str) -> None:
    try:
        generate_ux2.scan_file(fixture, module)
    except SystemExit as stop:
        if diagnostic not in f"{stop}":
            raise SystemExit(f"missing diagnostic {diagnostic!r}: {stop}")
        return
    raise SystemExit(f"scanner accepted a module that should fail: {diagnostic!r}")


def check_boundary_and_kill_lines(fixture: Path) -> None:
    readme = fixture / "README.md"
    original = rewrite(
        readme, "> - The subject is a **Lean model**", "> - The subject is a **Lean model**\n>   (continued)")
    items = generate_ux2.readme_boundary(fixture)
    if not any("(continued)" in item and "Lean model" in item for item in items):
        raise SystemExit("a wrapped blockquote bullet was not joined to its sentence")
    readme.write_text(original, encoding="utf-8")
    if generate_ux2.kill_line_modules("lake build LidoSRv3.Audit.Guarantees.PSsz1") != []:
        raise SystemExit("a reproduction without mutant modules reported kill-lines")


with tempfile.TemporaryDirectory() as tmp:
    fixture = Path(tmp)
    copy_tree(fixture)
    expect(fixture, "check", True, "11 guarantee records match")
    check_artifact_drift(fixture)
    check_registry_binding(fixture)
    check_lean_scanner(fixture)
    check_boundary_and_kill_lines(fixture)

print("ux2 artifact mutants ok: drift, stale, missing, unresolved/duplicate theorem, "
      "canonical order, unregistered assumption, missing source target, missing headline "
      "boundary, scope tracking, doc-comment and statement slicing")
