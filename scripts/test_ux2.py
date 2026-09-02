#!/usr/bin/env python3
"""Negative regressions for the UX2 per-guarantee artifact generator."""

from __future__ import annotations

import contextlib
import io
import json
import shutil
import subprocess
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
    "lakefile.lean",
    "lake-manifest.json",
    "LidoSRv3.lean",
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
    shutil.copytree(ROOT / "LidoSRv3", destination / "LidoSRv3")
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
    expect(fixture, "generate", True, "generated 12 files")
    if bogus.exists():
        raise SystemExit("generation left a stale UX2 JSON artifact behind")

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
        "theorem four (x : Nat) : let y := x + 1; y = x + 1 := by\n"
        "  intro y; rfl\n"
        "theorem five (x : Nat) : have h : x = x := rfl; x = x := fun _ => rfl\n"
        "theorem six (outlet : Nat) (h : outlet.let = 1) : outlet = 1 := h\n"
        "structure Pair where\n  a : Nat\n  h : a = 1\n"
        "theorem seven : Pair where\n  a := 1\n  h := rfl\n"
        "theorem eight (nowhere : Nat) : nowhere = nowhere := rfl\n"
        "theorem nine : Id.run do let x ← pure True; return x := by decide\n"
        "theorem ten : (Id.run do let x ← pure 1; let y := x + 1; return y) = 2 := rfl\n"
        "/-- Doc for eleven. -/\n"
        "@[simp,\n"
        "  reducible]\n"
        "theorem eleven : True := trivial\n"
        "/-- Not for twelve. -/\n"
        "def helper : Nat := 1\n"
        "theorem twelve : helper = 1 := rfl\n"
        "/-- Doc for thirteen. -/\n"
        "protected\n"
        "theorem thirteen : True := trivial\n"
        "lemma fourteen : True := trivial\n"
        "theorem\n"
        "fifteen : True := trivial\n"
        "private theorem one : True := trivial\n"
        "@[simp] private theorem two : True := trivial\n"
        "private\ntheorem one : True := trivial\n"
        "@[simp]\nprivate noncomputable\ntheorem two : True := trivial\n"
        "end Outer.Inner\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if any(len(records) != 1 for records in found.values()):
        raise SystemExit("a private theorem was indexed under the public name it shares")
    expected = {
        "Outer.Inner.one": ("theorem one (x : Nat := 3) : x = x", "/-- Doc for one. -/", 6, 6),
        "Outer.Inner.two": ("theorem two : True", "", 9, 9),
        "Outer.Inner.Deep.three": ("protected theorem three : True", "", 13, 13),
        "Outer.Inner.four": ("theorem four (x : Nat) : let y := x + 1; y = x + 1", "", 16, 16),
        "Outer.Inner.five": ("theorem five (x : Nat) : have h : x = x := rfl; x = x", "", 18, 18),
        "Outer.Inner.six": ("theorem six (outlet : Nat) (h : outlet.let = 1) : outlet = 1", "", 19, 19),
        "Outer.Inner.seven": ("theorem seven : Pair", "", 23, 23),
        "Outer.Inner.eight": ("theorem eight (nowhere : Nat) : nowhere = nowhere", "", 26, 26),
        "Outer.Inner.nine": ("theorem nine : Id.run do let x ← pure True; return x", "", 27, 27),
        "Outer.Inner.ten": ("theorem ten : (Id.run do let x ← pure 1; let y := x + 1; return y) = 2", "", 28, 28),
        "Outer.Inner.eleven": ("theorem eleven : True", "/-- Doc for eleven. -/", 32, 32),
        "Outer.Inner.twelve": ("theorem twelve : helper = 1", "", 35, 35),
        "Outer.Inner.thirteen": ("protected\ntheorem thirteen : True", "/-- Doc for thirteen. -/", 37, 38),
        "Outer.Inner.fourteen": ("lemma fourteen : True", "", 39, 39),
        "Outer.Inner.fifteen": ("theorem\nfifteen : True", "", 40, 41),
    }
    if set(found) != set(expected):
        raise SystemExit(f"scanner resolved {sorted(found)}")
    for name, (statement, doc, start, end) in expected.items():
        (record,) = found[name]
        got = (record["statement"], record["doc"], record["start_line"], record["end_line"])
        if got != (statement, doc, start, end):
            raise SystemExit(f"{name}: scanner produced {got}")

    module.write_text(
        "namespace Outer\n"
        "mutual\n"
        "def mutual_helper : Nat := 1\n"
        "end\n"
        "theorem mutual_one : True := trivial\n"
        "/-- helper documentation that must not attach below. -/\n"
        "def helper : Nat := 1\n"
        "/- implementation note -/\n"
        "theorem plain : True := trivial\n"
        "theorem char_open : '(' = '(' := rfl\n"
        "variable («where» : Prop)\n"
        "theorem escaped_where : «where» → «where» := id\n"
        "variable («(» : Prop)\n"
        "theorem escaped_bracket : «(» := by assumption\n"
        "end\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    expected_edges = {
        "Outer.mutual_one": ("theorem mutual_one : True", ""),
        "Outer.plain": ("theorem plain : True", ""),
        "Outer.char_open": ("theorem char_open : '(' = '('", ""),
        "Outer.escaped_where": ("theorem escaped_where : «where» → «where»", ""),
        "Outer.escaped_bracket": ("theorem escaped_bracket : «(»", ""),
    }
    for name, (statement, doc) in expected_edges.items():
        (record,) = found[name]
        if (record["statement"], record["doc"]) != (statement, doc):
            raise SystemExit(f"{name}: scanner lost a valid Lean construct: {record}")

    module.write_text(
        "namespace Outer\n"
        "theorem foo'a' : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.foo'a'"}:
        raise SystemExit("scanner treated character-shaped identifier text as a character literal")

    module.write_text(
        "namespace Outer\n"
        "def quoted : Syntax := `(command|\n"
        "  theorem one : True := trivial)\n"
        "theorem one : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.one"} or found["Outer.one"][0]["statement"] != "theorem one : True":
        raise SystemExit("scanner indexed a theorem inside a command quotation")

    # Lean token whitespace is permitted before the command-category separator;
    # this must still be syntax data rather than a duplicate declaration.
    module.write_text(
        "namespace Outer\n"
        "def quoted : Syntax := `(command |\n"
        "  theorem one : True := trivial)\n"
        "theorem one : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.one"}:
        raise SystemExit("scanner indexed a theorem inside a spaced command quotation")

    module.write_text(
        "namespace Outer\n"
        "def quoted : Syntax := `(command|\n"
        "  theorem «)» : True := trivial\n"
        "  theorem one : True := trivial)\n"
        "theorem one : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.one"}:
        raise SystemExit("scanner balanced a command quotation on a parenthesis in an escaped identifier")

    # Tokens that resemble a command quotation inside a guillemet name are
    # identifier data, so they must not initiate quotation balancing.
    module.write_text(
        "namespace Outer\n"
        "theorem «foo `(command | bar» : True := trivial\n"
        "theorem active : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.«foo `(command | bar»", "Outer.active"}:
        raise SystemExit("scanner treated command-quotation text in an escaped identifier as syntax")

    module.write_text(
        "namespace\n"
        "Outer\n"
        "section\n"
        "-- an ordinary comment between the scope keyword and name\n"
        "Inner\n"
        "theorem split_scope : True := trivial\n"
        "end\n"
        "Inner\n"
        "end\n"
        "Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.split_scope"}:
        raise SystemExit(f"scanner lost a scope name separated by Lean whitespace: {found}")

    module.write_text(
        "namespace Outer\n"
        "section\n"
        "end\n"
        "end Outer\n", encoding="utf-8")
    if generate_ux2.scan_file(fixture, module) != {}:
        raise SystemExit("scanner treated an unnamed scope's closing `end` as its name")

    # No scope-command keyword may be consumed as the optional split-line name
    # of an unnamed scope.  In particular, an unnamed section may contain a
    # mutual block whose own `end` must close that block rather than underflow.
    module.write_text(
        "namespace Outer\n"
        "section\n"
        "mutual\n"
        "def mutual_helper : Nat := 1\n"
        "end\n"
        "theorem after_mutual : True := trivial\n"
        "end\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.after_mutual"}:
        raise SystemExit("scanner consumed `mutual` as an unnamed section's name")

    # Scope names use the same escaped-identifier tokenization as declarations:
    # whitespace inside guillemets belongs to the name, including at `end`.
    module.write_text(
        "namespace «Outer Space»\n"
        "section «Local Space»\n"
        "theorem within_escaped_scopes : True := trivial\n"
        "end «Local Space»\n"
        "end «Outer Space»\n"
        "theorem after_escaped_scopes : True := trivial\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"«Outer Space».within_escaped_scopes", "after_escaped_scopes"}:
        raise SystemExit("scanner did not parse escaped scope names containing whitespace")

    module.write_text("end Nothing\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "`end` without an open namespace")
    module.write_text("namespace A\nend B\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "`end B` closes `namespace A`")
    module.write_text("theorem open_ended (x : Nat) : x = x\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "never reaches `:=` or `where`")
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


def check_escaped_identifier_lexing(fixture: Path) -> None:
    """Comment/string delimiters in guillemet names remain Lean code."""
    strip = check_proof_escapes.strip_comments_and_strings
    escaped = 'theorem «helper /- -- -/ " name» : True := trivial\n'
    if strip(escaped) != escaped:
        raise SystemExit("comment/string masker altered a guillemet-escaped identifier")
    escaped_keyword = strip("theorem «sorry» : True := trivial\n", mask_escaped_identifiers=True)
    if any(pattern.search(escaped_keyword) for _, pattern in check_proof_escapes.ESCAPES):
        raise SystemExit("proof-escape matcher treated a guillemet name as a guarded keyword")
    character_then_axiom = strip(
        "def marker : Char := '«'\naxiom injected : False\n",
        mask_escaped_identifiers=True)
    if "axiom injected" not in character_then_axiom:
        raise SystemExit("a guillemet character literal hid a later proof escape")

    controls = (
        "theorem helper : True := trivial /- hidden -/\n",
        'theorem helper : "-- /- hidden -/" = "-- /- hidden -/" := rfl\n',
    )
    for source in controls:
        masked = strip(source)
        if any(marker in masked for marker in ("/-", "--", "hidden")):
            raise SystemExit(f"comment/string masker retained ordinary delimiter text: {masked!r}")

    module = fixture / "LidoSRv3/Audit/Guarantees/Synthetic.lean"
    module.write_text(
        "namespace Outer\n"
        "theorem foo'a' : True := trivial\n"
        "theorem «helper /- name» : True := trivial\n"
        "theorem after_escaped_identifier : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if "Outer.foo'a'" not in found:
        raise SystemExit("character-literal masking altered an ordinary theorem identifier")
    if "Outer.«helper /- name»" not in found:
        raise SystemExit("scanner did not retain the full guillemet-escaped theorem name")
    if "Outer.after_escaped_identifier" not in found:
        raise SystemExit("escaped identifier comment marker hid a later theorem")
    module.unlink()


def check_lean_inputs_binding(fixture: Path) -> None:
    """Any Lean input change, even outside the scanned modules, moves the index tree id,
    and the id is the one scripts/verified_source_tree.sh computes with Git."""
    mutant = fixture / "LidoSRv3/Tests/ZzInputMutant.lean"
    mutant.write_text("-- not a theorem\n", encoding="utf-8")
    expect(fixture, "check", False, "index.json differs from the registry and Lean sources")
    mutant.unlink()
    expect(fixture, "check", True, "11 guarantee records match")
    (fixture / "lake-manifest.json").unlink()
    expect(fixture, "check", False, "missing Lean input lake-manifest.json")
    shutil.copy2(ROOT / "lake-manifest.json", fixture / "lake-manifest.json")
    empty = fixture / "LidoSRv3/Audit/Empty/Deeper"
    empty.mkdir(parents=True)
    expect(fixture, "check", True, "11 guarantee records match")
    shutil.rmtree(empty.parent)
    with_git = subprocess.run(["bash", "scripts/verified_source_tree.sh"], cwd=ROOT,
                              capture_output=True, text=True)
    if with_git.returncode != 0:
        raise SystemExit("commit the Lean inputs before running test_ux2.py: "
                         + with_git.stderr.strip())
    if generate_ux2.lean_source_tree(ROOT) != with_git.stdout.strip():
        raise SystemExit("lean_source_tree differs from scripts/verified_source_tree.sh")
    canonical = generate_ux2.scan_file(
        ROOT, ROOT / "LidoSRv3/Audit/Verity/DepositParentTx.lean")
    (record,) = canonical["LidoSRv3.Audit.Verity.DepositParentTx.canonical_preconditions"]
    if "where" in record["statement"] or not record["statement"].endswith("canonicalState"):
        raise SystemExit(f"a where-proof statement was not sliced at `where`: {record['statement'][-80:]}")


def check_scanner_edges(fixture: Path) -> None:
    """Branches no synthetic module reaches: unbalanced attributes, a binder with
    no `:=` or `←` after it, and a Lean input directory with no file."""
    if generate_ux2.is_attribute_block("@[simp"):
        raise SystemExit("an unbalanced attribute was accepted as an attribute block")
    if generate_ux2.is_attribute_block("@[simp] theorem"):
        raise SystemExit("trailing declaration text was accepted as attribute text")
    if generate_ux2.binds_with_walrus("let y", 0):
        raise SystemExit("a binder with no `:=` or `←` after it counted as a walrus binder")
    hollow = fixture / "hollow"
    for name in generate_ux2.LEAN_INPUTS:
        (hollow / name).parent.mkdir(parents=True, exist_ok=True)
        (hollow / name).write_text("", encoding="utf-8")
    (hollow / "LidoSRv3" / "Empty").mkdir(parents=True)
    try:
        generate_ux2.lean_source_tree(hollow)
    except SystemExit as stop:
        if "holds no Lean input" not in f"{stop}":
            raise SystemExit(f"unexpected diagnostic for an empty Lean tree: {stop}")
    else:
        raise SystemExit("an empty Lean input directory produced a tree id")
    shutil.rmtree(hollow)


def check_symlink_tree(fixture: Path) -> None:
    """A symlink below LidoSRv3/, among the top-level inputs, or standing in for
    the LidoSRv3/ root is refused: the tree id would bind its link text while
    Lean reads its target."""
    linked = fixture / "linked"
    for name in generate_ux2.LEAN_INPUTS:
        (linked / name).parent.mkdir(parents=True, exist_ok=True)
        (linked / name).write_text(name, encoding="utf-8")
    nested = linked / "LidoSRv3" / "Nested"
    nested.mkdir(parents=True)
    (nested / "Real.lean").write_text("theorem t : True := trivial\n", encoding="utf-8")
    for link, target in (("Alias.lean", "Nested/Real.lean"), ("Twin", "Nested"),
                         ("Escape.lean", "../../lakefile.lean")):
        (linked / "LidoSRv3" / link).symlink_to(target)
        try:
            generate_ux2.lean_source_tree(linked)
        except SystemExit as stop:
            if "is a symlink" not in f"{stop}":
                raise SystemExit(f"unexpected diagnostic for a symlink: {stop}")
        else:
            raise SystemExit(f"a symlink {link} -> {target} below LidoSRv3/ was hashed")
        (linked / "LidoSRv3" / link).unlink()
    (linked / "lakefile.lean").unlink()
    (linked / "lakefile.lean").symlink_to("LidoSRv3/Nested/Real.lean")
    try:
        generate_ux2.lean_source_tree(linked)
    except SystemExit as stop:
        if "lakefile.lean is a symlink" not in f"{stop}":
            raise SystemExit(f"unexpected diagnostic for a top-level symlink: {stop}")
    else:
        raise SystemExit("a symlinked top-level Lean input was hashed")
    (linked / "lakefile.lean").unlink()
    (linked / "lakefile.lean").write_text("lakefile.lean", encoding="utf-8")
    check_symlinked_root(linked)
    shutil.rmtree(linked)


def check_symlinked_root(linked: Path) -> None:
    """`LidoSRv3` itself replaced by a symlink is refused, whatever it points at:
    Git stores that entry as a `120000` blob of the link text, never as the
    `040000` tree of the target, so following it would hash a tree the proof
    receipt cannot contain."""
    real = linked / "LidoSRv3"
    moved = linked / "Elsewhere"
    real.rename(moved)
    outside = linked.parent / "outside"
    shutil.copytree(moved, outside / "LidoSRv3")
    for target in ("Elsewhere", str(outside / "LidoSRv3"), "Missing"):
        real.symlink_to(target)
        try:
            generate_ux2.lean_source_tree(linked)
        except SystemExit as stop:
            if "LidoSRv3 is a symlink" not in f"{stop}":
                raise SystemExit(f"unexpected diagnostic for a symlinked root -> {target}: {stop}")
        else:
            raise SystemExit(f"a symlinked LidoSRv3 root -> {target} was hashed as a tree")
        real.unlink()
    shutil.rmtree(outside)
    try:
        generate_ux2.lean_source_tree(linked)
    except SystemExit as stop:
        if "missing Lean input LidoSRv3/" not in f"{stop}":
            raise SystemExit(f"unexpected diagnostic for a missing root: {stop}")
    else:
        raise SystemExit("a missing LidoSRv3 root produced a tree id")
    moved.rename(real)


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
    check_escaped_identifier_lexing(fixture)
    check_lean_inputs_binding(fixture)
    check_scanner_edges(fixture)
    check_symlink_tree(fixture)
    check_boundary_and_kill_lines(fixture)

print("ux2 artifact mutants ok: drift, stale, missing, unresolved/duplicate theorem, "
      "canonical order, unregistered assumption, missing source target, missing headline "
      "boundary, scope tracking, doc-comment and statement slicing, let/have binders, where-proofs, "
      "escaped identifier delimiters and ordinary delimiter controls, "
      "symlinked inputs and root, and the Lean source tree id")
