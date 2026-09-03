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
        "theorem equation_clause : ∀ n : Nat, n = n\n"
        "  | n => rfl\n"
        "theorem after_equation_clause : True := trivial\n"
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
        "Outer.Inner.equation_clause": ("theorem equation_clause : ∀ n : Nat, n = n", "", 29, 29),
        "Outer.Inner.after_equation_clause": ("theorem after_equation_clause : True", "", 31, 31),
        "Outer.Inner.eleven": ("theorem eleven : True", "/-- Doc for eleven. -/", 35, 35),
        "Outer.Inner.twelve": ("theorem twelve : helper = 1", "", 38, 38),
        "Outer.Inner.thirteen": ("protected\ntheorem thirteen : True", "/-- Doc for thirteen. -/", 40, 41),
        "Outer.Inner.fourteen": ("lemma fourteen : True", "", 42, 42),
        "Outer.Inner.fifteen": ("theorem\nfifteen : True", "", 43, 44),
    }
    if set(found) != set(expected):
        raise SystemExit(f"scanner resolved {sorted(found)}")
    for name, (statement, doc, start, end) in expected.items():
        (record,) = found[name]
        got = (record["statement"], record["doc"], record["start_line"], record["end_line"])
        if got != (statement, doc, start, end):
            raise SystemExit(f"{name}: scanner produced {got}")

    # An apostrophe continues an ordinary Lean identifier, even when its
    # prefix spells a signature keyword. Each spelling exercises a distinct
    # statement_end branch: `where` ends a signature, while `let` and `have`
    # can consume a following walrus binding.
    module.write_text(
        "namespace Suffix\n"
        "def where' : Prop := True\n"
        "def let' : Prop := True\n"
        "def have' : Prop := True\n"
        "theorem where_suffix : where' := trivial\n"
        "theorem let_suffix : let' := trivial\n"
        "theorem have_suffix : have' := trivial\n"
        "end Suffix\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    expected_suffixes = {
        "Suffix.where_suffix": "theorem where_suffix : where'",
        "Suffix.let_suffix": "theorem let_suffix : let'",
        "Suffix.have_suffix": "theorem have_suffix : have'",
    }
    if {name: records[0]["statement"] for name, records in found.items()} != expected_suffixes:
        raise SystemExit("scanner treated keyword-prefix identifiers as signature keywords")

    # An equation clause may wrap its arrow, but a result-type `match` has
    # visually similar arms that remain part of the declaration signature.
    module.write_text(
        "namespace Outer\n"
        "theorem result_match : match true with\n"
        "  | true => True\n"
        "  | false => False := by\n"
        "  trivial\n"
        "theorem wrapped_equation : ∀ n : Nat, n = n\n"
        "  | n\n"
        "    => rfl\n"
        "theorem after_wrapped_equation : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    match_record = found["Outer.result_match"][0]
    if match_record["statement"] != (
        "theorem result_match : match true with\n"
        "  | true => True\n"
        "  | false => False"):
        raise SystemExit("scanner treated a result-type match arm as an equation clause")
    wrapped_record = found["Outer.wrapped_equation"][0]
    if (wrapped_record["statement"], wrapped_record["end_line"]) != (
            "theorem wrapped_equation : ∀ n : Nat, n = n", 6):
        raise SystemExit("scanner did not slice a wrapped equation clause at its signature line")

    module.write_text(
        "namespace Outer\n"
        "theorem multiline_pattern : ∀ n : Nat, n = n\n"
        "  | (Nat.succ\n"
        "      n) => rfl\n"
        "theorem after_multiline_pattern : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.multiline_pattern"][0]["statement"] != "theorem multiline_pattern : ∀ n : Nat, n = n":
        raise SystemExit("scanner did not scan a multiline equation pattern through its arrow")
    if found["Outer.after_multiline_pattern"][0]["statement"] != "theorem after_multiline_pattern : True":
        raise SystemExit("scanner consumed the declaration after a multiline equation pattern")

    # Result-type match arms are indented beneath the theorem, while the
    # equation clauses return to the theorem command column.  Seeing the
    # former must not suppress scanning the latter or consume the next theorem.
    module.write_text(
        "namespace Outer\n"
        "theorem mixed : ∀ b : Bool, match b with\n"
        "  | true => True\n"
        "  | false => False\n"
        "| true => trivial\n"
        "| false => trivial\n"
        "theorem after_mixed : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.mixed"][0]["statement"] != (
            "theorem mixed : ∀ b : Bool, match b with\n"
            "  | true => True\n"
            "  | false => False"):
        raise SystemExit("scanner did not end a result match before equation clauses")
    if found["Outer.after_mixed"][0]["statement"] != "theorem after_mixed : True":
        raise SystemExit("scanner consumed the declaration after result-match equation clauses")

    # The first result-match arm may be inline.  Its column must establish the
    # result-match layout boundary so following equation clauses do not absorb
    # the next declaration's `:=` into this theorem's statement.
    module.write_text(
        "namespace Outer\n"
        "theorem inline_mixed : ∀ b : Bool, match b with | true => True | false => False\n"
        "| true => trivial\n"
        "| false => trivial\n"
        "theorem after_inline_mixed : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.inline_mixed"][0]["statement"] != (
            "theorem inline_mixed : ∀ b : Bool, match b with | true => True | false => False"):
        raise SystemExit("scanner did not end an inline result match before equation clauses")
    if found["Outer.after_inline_mixed"][0]["statement"] != "theorem after_inline_mixed : True":
        raise SystemExit("scanner consumed the declaration after inline result-match equation clauses")

    # Nested result matches each have their own arm column. When the inner
    # arms dedent, the outer match remains active; only a later dedent below
    # the outer arms begins the equation proof.
    module.write_text(
        "namespace Outer\n"
        "theorem nested_mixed : ∀ b c : Bool, match b with\n"
        "  | true => match c with\n"
        "    | true => True\n"
        "    | false => False\n"
        "  | false => False\n"
        "| true, true => trivial\n"
        "| _, _ => trivial\n"
        "theorem after_nested_mixed : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.nested_mixed"][0]["statement"] != (
            "theorem nested_mixed : ∀ b c : Bool, match b with\n"
            "  | true => match c with\n"
            "    | true => True\n"
            "    | false => False\n"
            "  | false => False"):
        raise SystemExit("scanner lost the outer result-match state after a nested match")
    if found["Outer.after_nested_mixed"][0]["statement"] != "theorem after_nested_mixed : True":
        raise SystemExit("scanner consumed the declaration after nested result-match equation clauses")

    # Equation clauses may begin on the theorem signature line. A following
    # theorem is the boundary control: it must not be absorbed into the first
    # declaration when that first arm has no preceding newline.
    module.write_text(
        "namespace Outer\n"
        "theorem inline_equation : ∀ n : Nat, n = n | n => rfl\n"
        "theorem after_inline_equation : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.inline_equation"][0]["statement"] != "theorem inline_equation : ∀ n : Nat, n = n":
        raise SystemExit("scanner did not slice a same-line equation clause")
    if found["Outer.after_inline_equation"][0]["statement"] != "theorem after_inline_equation : True":
        raise SystemExit("scanner consumed the declaration after a same-line equation clause")

    # `|>` is an operator in a result-match scrutinee, not an arm delimiter.
    # The following theorem controls that the real match arms remain in the
    # signature and do not become equation clauses.
    module.write_text(
        "namespace Outer\n"
        "theorem piped_result_match : match true |> id with\n"
        "  | true => True\n"
        "  | false => False\n"
        ":= by trivial\n"
        "theorem after_piped_result_match : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.piped_result_match"][0]["statement"] != (
            "theorem piped_result_match : match true |> id with\n"
            "  | true => True\n"
            "  | false => False"):
        raise SystemExit("scanner treated a pipeline operator as a result-match arm")
    if found["Outer.after_piped_result_match"][0]["statement"] != (
            "theorem after_piped_result_match : True"):
        raise SystemExit("scanner consumed the declaration after a piped result match")

    # Both Lean application operators contain a pipe but neither is an
    # equation arm.  A depth-zero lambda arrow after `<|` is the control that
    # used to make the scanner truncate the signature at the operator.
    module.write_text(
        "namespace Outer\n"
        "theorem left_applied : id <| (fun x : Nat => x) = fun x => x := by rfl\n"
        "theorem after_left_applied : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.left_applied"][0]["statement"] != (
            "theorem left_applied : id <| (fun x : Nat => x) = fun x => x"):
        raise SystemExit("scanner treated a left-application operator as an equation clause")
    if found["Outer.after_left_applied"][0]["statement"] != (
            "theorem after_left_applied : True"):
        raise SystemExit("scanner consumed the declaration after a left-application result")

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

    # Theorem names use the same dotted escaped-component grammar as scopes;
    # whitespace inside an escaped component must not truncate a registered name.
    module.write_text(
        "namespace Outer\n"
        "theorem Foo.«bar baz» : True := trivial\n"
        "theorem «Foo bar».baz : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.Foo.«bar baz»", "Outer.«Foo bar».baz"}:
        raise SystemExit("scanner did not parse qualified escaped theorem names")

    # Find the opening documentation comment by balancing nested block comments,
    # rather than stopping at an inner opener.
    module.write_text(
        "namespace Outer\n"
        "/-- Outer documentation.\n"
        "/- nested note\n"
        "  /- deeper note -/\n"
        "-/\n"
        "-/\n"
        "theorem nested_doc : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    (record,) = found["Outer.nested_doc"]
    if record["doc"] != "/-- Outer documentation.\n/- nested note\n  /- deeper note -/\n-/\n-/":
        raise SystemExit("scanner lost documentation around nested block comments")

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

    # In a command macro, Lean infers the quotation category from the macro's
    # result. The quoted theorem is syntax data, while the following theorem
    # is the active control and must be the only indexed declaration.
    module.write_text(
        "namespace Outer\n"
        "macro \"registered\" : command => `( theorem registered : True := trivial)\n"
        "theorem registered : True := trivial\n"
        "theorem inferred_command_control : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if {name: len(records) for name, records in found.items()} != {
            "Outer.registered": 1, "Outer.inferred_command_control": 1}:
        raise SystemExit("scanner indexed a theorem inside an inferred command quotation")

    # Declaration attributes are a repeatable token sequence, not a single
    # optional prefix.  Commands may also share a physical line, so a theorem
    # must be recognized at its whitespace command boundary and its statement
    # must begin at the theorem rather than the preceding helper command.
    module.write_text(
        "namespace Outer\n"
        "@[simp] @[protected] theorem repeated_attributes : True := trivial\n"
        "def helper := 1 theorem inline_after_helper : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    expected_inline = {
        "Outer.repeated_attributes": "theorem repeated_attributes : True",
        "Outer.inline_after_helper": "theorem inline_after_helper : True",
    }
    if {name: records[0]["statement"] for name, records in found.items()} != expected_inline:
        raise SystemExit("scanner did not recognize repeated attributes or inline command declarations")

    # Scope commands use the same whitespace command boundary as declarations.
    # Namespaces qualify declarations, while named sections are local binders
    # and must not become name components.
    module.write_text(
        "namespace Outer section Local theorem inner : True := trivial end Local "
        "theorem outer : True := trivial end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.inner", "Outer.outer"}:
        raise SystemExit("scanner did not qualify namespaces without qualifying sections")

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

    # A scope keyword inside a guillemet theorem name is identifier data.  It
    # must neither pop the active namespace nor underflow at top level.
    module.write_text(
        "namespace Outer\n"
        "theorem «foo end» : True := trivial\n"
        "theorem still_nested : True := trivial\n"
        "end Outer\n"
        "theorem top_level : True := trivial\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"Outer.«foo end»", "Outer.still_nested", "top_level"}:
        raise SystemExit("scanner treated `end` in an escaped theorem name as a scope command")

    # `_root_.` makes a declaration name absolute, so it must suppress the
    # active namespace rather than becoming a component of it.  The ordinary
    # declaration is the control that remains qualified by the namespace.
    module.write_text(
        "namespace Outer\n"
        "theorem _root_.root_level : True := trivial\n"
        "theorem control_level : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"root_level", "Outer.control_level"}:
        raise SystemExit("scanner did not resolve `_root_` declarations from the Lean root namespace")

    # A documentation comment may share the declaration line, including when
    # same-line attributes precede the declaration.  The following theorem is
    # the control: it must not inherit either previous comment.
    module.write_text(
        "namespace Outer\n"
        "/-- Same-line documentation. -/ theorem documented : True := trivial\n"
        "/-- Attribute documentation. -/ @[simp] theorem attributed : True := trivial\n"
        "/-- Multiline attribute documentation. -/ @[simp,\n"
        "  reducible]\n"
        "theorem multiline_attributed : True := trivial\n"
        "/-- Wrapped-inline attribute documentation. -/ @[simp,\n"
        "  grind] theorem wrapped_inline_attributed : True := trivial\n"
        "theorem undocumented : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.documented"][0]["doc"] != "/-- Same-line documentation. -/":
        raise SystemExit("scanner did not attach a same-line documentation comment")
    if found["Outer.attributed"][0]["doc"] != "/-- Attribute documentation. -/":
        raise SystemExit("scanner did not attach a same-line documentation comment before an attribute")
    if found["Outer.multiline_attributed"][0]["doc"] != "/-- Multiline attribute documentation. -/":
        raise SystemExit("scanner did not attach a same-line documentation comment before multiline attributes")
    if found["Outer.wrapped_inline_attributed"][0]["doc"] != (
            "/-- Wrapped-inline attribute documentation. -/"):
        raise SystemExit("scanner lost inline documentation across a wrapped attribute")

    module.write_text(
        "namespace Outer\n"
        "/-- Documentation through ordinary comments. -/\n"
        "-- formatting note\n"
        "/- implementation note -/\n"
        "theorem commented_doc : True := trivial\n"
        "theorem undocumented : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.commented_doc"][0]["doc"] != "/-- Documentation through ordinary comments. -/":
        raise SystemExit("scanner did not retain documentation across ordinary comments")
    if found["Outer.undocumented"][0]["doc"]:
        raise SystemExit("scanner leaked a same-line documentation comment to the next declaration")

    # A declaration can immediately follow another command and its attached
    # documentation comment on the same line. The next theorem is the control
    # for both declaration and documentation boundaries.
    module.write_text(
        "namespace Outer\n"
        "def helper := 1 /-- Helper-backed theorem. -/ theorem registered : helper = 1 := rfl\n"
        "theorem undocumented_after_helper : True := trivial\n"
        "end Outer\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if found["Outer.registered"][0]["doc"] != "/-- Helper-backed theorem. -/":
        raise SystemExit("scanner did not attach documentation after a same-line preceding command")
    if found["Outer.registered"][0]["doc"].startswith("def helper"):
        raise SystemExit("scanner included preceding same-line code in documentation")
    if found["Outer.undocumented_after_helper"][0]["doc"]:
        raise SystemExit("scanner leaked same-line command documentation to the next declaration")

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

    # A hash command following an unnamed close is a distinct command, while
    # a named close before the same command must keep its scope name.
    module.write_text(
        "namespace Unnamed\n"
        "end #check Nat\n"
        "theorem after_unnamed : True := trivial\n"
        "namespace Named\n"
        "end Named #check Nat\n"
        "theorem after_named : True := trivial\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"after_unnamed", "after_named"}:
        raise SystemExit("scanner did not distinguish hash commands after unnamed and named `end`")

    # A close has no required label.  Its optional label is only meaningful
    # when it matches the scope being closed; otherwise a further same-line
    # token starts the next command.  These commands are deliberately outside
    # the scanner's historical keyword list, so accepting them cannot depend
    # on extending that list.  The named-close control keeps explicit labels
    # on the same line with the following command.
    module.write_text(
        "namespace UniverseClose\n"
        "end universe u\n"
        "theorem after_universe : True := trivial\n"
        "namespace ExportClose\n"
        "end export Nat (add)\n"
        "theorem after_export : True := trivial\n"
        "namespace IncludeClose\n"
        "end include u\n"
        "theorem after_include : True := trivial\n"
        "namespace NamedClose\n"
        "end NamedClose universe v\n"
        "theorem after_named_universe : True := trivial\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"after_universe", "after_export", "after_include", "after_named_universe"}:
        raise SystemExit("scanner consumed a same-line command as an omitted `end` label")

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

    # Scope names are dotted identifier-component sequences.  Guillemet
    # components retain their whitespace both at an opener and its matching
    # `end`, whether they lead or trail an ordinary component.
    module.write_text(
        "namespace «Outer Space».Inner\n"
        "section Local.«Scope Space»\n"
        "theorem within_escaped_scopes : True := trivial\n"
        "end Local.«Scope Space»\n"
        "end «Outer Space».Inner\n"
        "theorem after_escaped_scopes : True := trivial\n", encoding="utf-8")
    found = generate_ux2.scan_file(fixture, module)
    if set(found) != {"«Outer Space».Inner.within_escaped_scopes", "after_escaped_scopes"}:
        raise SystemExit("scanner did not parse qualified escaped scope names")

    module.write_text("end Nothing\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "`end` without an open namespace")
    module.write_text("namespace A\nend B\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "`end B` closes `namespace A`")
    module.write_text("theorem open_ended (x : Nat) : x = x\n", encoding="utf-8")
    expect_scan_failure(fixture, module, "never reaches `:=` or `where`")
    module.write_text("/-- orphan -/\n\ntheorem gap : True := trivial\n", encoding="utf-8")
    (record,) = generate_ux2.scan_file(fixture, module)["gap"]
    if record["doc"] != "/-- orphan -/":
        raise SystemExit("scanner did not retain documentation across a blank line")
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
    for literal in ("'«'", "'»'", "'\\\\'"):
        character_then_axiom = strip(
            f"def marker : Char := {literal}\naxiom injected : False\n",
            mask_escaped_identifiers=True)
        if "axiom injected" not in character_then_axiom:
            raise SystemExit(f"character literal {literal} hid a later proof escape")

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


def check_top_level_executable_mode(fixture: Path) -> None:
    """An executable top-level Lean input hashes as Git mode 100755."""
    input_path = fixture / "lakefile.lean"
    original_mode = input_path.stat().st_mode
    regular_tree = generate_ux2.lean_source_tree(fixture)
    input_path.chmod(original_mode | 0o111)
    executable_tree = generate_ux2.lean_source_tree(fixture)
    input_path.chmod(original_mode)
    if regular_tree == executable_tree:
        raise SystemExit("an executable top-level Lean input was still hashed as mode 100644")


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
    check_top_level_executable_mode(fixture)
    check_boundary_and_kill_lines(fixture)

print("ux2 artifact mutants ok: drift, stale, missing, unresolved/duplicate theorem, "
      "canonical order, unregistered assumption, missing source target, missing headline "
      "boundary, scope tracking, doc-comment and statement slicing, let/have binders, where-proofs, "
      "escaped identifier delimiters and ordinary delimiter controls, "
      "symlinked inputs and root, and the Lean source tree id")
