#!/usr/bin/env python3
"""Fail-closed mutants for the P-ALLOC-1 report theorem inventory."""

import importlib.util
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKER = "scripts/check_report_theorem_inventory.py"
# The checker reads the published table through the shared cmark-gfm table
# reader, so the fixture tree must carry it or every mutant would fail on an
# import error rather than on the claim it is testing.
READER = "scripts/gfm_table.py"
LEAN = "LidoSRv3/Audit/Guarantees/PAlloc1.lean"
REPORT = "report/P-ALLOC-1.md"
REGISTRY = "audit/guarantees.yaml"


def _load_checker():
    """Drive the modifier family from the checker's own table.

    Listing the spellings by hand left `scoped`, `local` and `noncomputable`
    accepted by the gate but never asserted, so a modifier added later would
    arrive with no adversarial case at all.  Reading the table here keeps the
    two in step.
    """
    spec = importlib.util.spec_from_file_location("_inventory_checker", ROOT / CHECKER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CHECK = _load_checker()


def invoke(root, ok, needle=None):
    result = subprocess.run(
        ["python3", CHECKER], cwd=root,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    if (result.returncode == 0) != ok:
        raise AssertionError(f"unexpected rc={result.returncode}:\n{result.stdout}")
    if needle and needle not in result.stdout:
        raise AssertionError(f"missing {needle!r}:\n{result.stdout}")


def main():
    with tempfile.TemporaryDirectory(prefix="report-inventory-mutants-") as tmp:
        fixture = Path(tmp)
        for relative in (CHECKER, READER, LEAN, REPORT, REGISTRY):
            target = fixture / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)

        lean_path = fixture / LEAN
        report_path = fixture / REPORT
        registry_path = fixture / REGISTRY
        lean = lean_path.read_text(encoding="utf-8")
        report = report_path.read_text(encoding="utf-8")
        registry = json.loads(registry_path.read_text(encoding="utf-8"))

        invoke(fixture, True, "8 P-ALLOC-1 theorems, 2 registered")

        # An inventory row silently dropped: the guarantee would read as having
        # fewer moving parts than it has.
        dropped = re.sub(r"^\| `router_order_preserved` \|.*\n", "", report, flags=re.MULTILINE)
        if dropped == report:
            raise AssertionError("drop mutant changed nothing")
        report_path.write_text(dropped, encoding="utf-8")
        invoke(fixture, False, "omits declared theorem(s): router_order_preserved")
        report_path.write_text(report, encoding="utf-8")

        # A new theorem added to the module without an inventory row.
        report_path.write_text(report, encoding="utf-8")
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "theorem undisclosed_sibling : True := trivial\n\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, False, "omits declared theorem(s): undisclosed_sibling")
        lean_path.write_text(lean, encoding="utf-8")

        # The same omission dressed in ordinary Lean formatting.  Indentation,
        # an attribute block, a visibility or reducibility modifier, and the
        # `lemma` alias are all everyday spellings of a top-level declaration.
        # None of them may hide a theorem from the inventory while the gate
        # still reports success, so each is asserted separately rather than
        # trusting one representative spelling to stand for the rest.
        for spelling, hidden in (
            ("  theorem undisclosed_indented", "undisclosed_indented"),
            ("\ttheorem undisclosed_tabbed", "undisclosed_tabbed"),
            ("@[simp] theorem undisclosed_attributed", "undisclosed_attributed"),
            ("  @[simp, norm_cast] theorem undisclosed_multi_attributed",
             "undisclosed_multi_attributed"),
            ("private theorem undisclosed_private", "undisclosed_private"),
            ("protected theorem undisclosed_protected", "undisclosed_protected"),
            ("nonrec theorem undisclosed_nonrec", "undisclosed_nonrec"),
            ("lemma undisclosed_lemma", "undisclosed_lemma"),
            ("  @[simp] private lemma undisclosed_combined", "undisclosed_combined"),
        ):
            report_path.write_text(report, encoding="utf-8")
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{spelling} : True := trivial\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {hidden}")
            lean_path.write_text(lean, encoding="utf-8")

        # Lean separates the keyword from the name by whitespace, and a newline
        # is whitespace: `theorem\n  name` is one ordinary declaration.  Read a
        # physical line at a time, it splits into a keyword line carrying no
        # name and a name line carrying no keyword, so neither half matches and
        # the theorem stays out of the inventory with the gate still reporting
        # success.  Every prefix that may precede the keyword is asserted in
        # this form too, since wrapping is exactly what a long prefix invites.
        for spelling, hidden in (
            ("theorem\n  undisclosed_wrapped", "undisclosed_wrapped"),
            ("lemma\n  undisclosed_wrapped_lemma", "undisclosed_wrapped_lemma"),
            ("theorem\n\n  undisclosed_blank_line", "undisclosed_blank_line"),
            ("  @[simp] private theorem\n    undisclosed_wrapped_combined",
             "undisclosed_wrapped_combined"),
            ("theorem\n  «undisclosed wrapped escaped»", "«undisclosed wrapped escaped»"),
            ("theorem\n  αundisclosed_wrapped", "αundisclosed_wrapped"),
        ):
            report_path.write_text(report, encoding="utf-8")
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{spelling} : True := trivial\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {hidden}")
            lean_path.write_text(lean, encoding="utf-8")

        # A comment is whitespace to the Lean parser, so it may sit anywhere
        # whitespace may — including between the keyword and the name.  Copying
        # comment text through left `-- why` wedged in that gap, so no
        # declaration was read across it and the theorem stayed out of the
        # inventory while this gate reported success.  Every prefix that may
        # precede the keyword is asserted in this form, since a long prefix is
        # exactly what invites a trailing note.
        for spelling, hidden in (
            ("theorem -- why\n  undisclosed_after_note", "undisclosed_after_note"),
            ("lemma -- why\n  undisclosed_lemma_after_note", "undisclosed_lemma_after_note"),
            ("theorem -- one\n  -- two\n  undisclosed_after_two_notes",
             "undisclosed_after_two_notes"),
            ("theorem /- why -/ undisclosed_after_block_note", "undisclosed_after_block_note"),
            ("theorem -- why\n  /- and why -/ undisclosed_after_mixed_notes",
             "undisclosed_after_mixed_notes"),
            ("private -- why\n  theorem undisclosed_note_after_modifier",
             "undisclosed_note_after_modifier"),
            ("@[simp] -- why\n  theorem undisclosed_note_after_attribute",
             "undisclosed_note_after_attribute"),
            ("  @[simp] private theorem -- why\n    undisclosed_combined_after_note",
             "undisclosed_combined_after_note"),
            ("theorem -- why\n  «undisclosed escaped after note»",
             "«undisclosed escaped after note»"),
            ("theorem -- why\n  αundisclosed_after_note", "αundisclosed_after_note"),
        ):
            report_path.write_text(report, encoding="utf-8")
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{spelling} : True := trivial\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {hidden}")
            lean_path.write_text(lean, encoding="utf-8")

        # Blanking a line comment must stay inside that line and must not join
        # text across it into a keyword that was never written.  Both directions
        # are asserted: the comment ends at its newline, and a keyword appearing
        # only as comment prose still declares nothing.
        for source, name in (
            ("-- a note\ntheorem undisclosed_after_note_line", "undisclosed_after_note_line"),
            ('def dashes : String := "-- theorem prose"\n'
             "theorem undisclosed_after_dash_string", "undisclosed_after_dash_string"),
        ):
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{source} : True := trivial\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {name}")
            lean_path.write_text(lean, encoding="utf-8")

        for not_a_declaration in (
            "def keyword_free : Nat := 0 -- theorem\n  spliced_name : True := trivial",
            "def also_keyword_free : Nat := 0 -- lemma\n  spliced_lemma : True := trivial",
        ):
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{not_a_declaration}\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            lean_path.write_text(lean, encoding="utf-8")

        # Blanking must preserve the line the keyword sits on, or the row that
        # discloses such a declaration could only cite a line it is not on.
        noted = "theorem disclosed_noted -- why\n    : True := trivial"
        noted_lean = lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                                  f"{noted}\n\n"
                                  "end LidoSRv3.Audit.Guarantees.PAlloc1", 1)
        if noted_lean == lean:
            raise AssertionError("noted round-trip mutant changed nothing")
        noted_line = noted_lean.splitlines().index("theorem disclosed_noted -- why") + 1
        anchor = next(line for line in report.splitlines()
                      if line.startswith("| `router_order_preserved` |"))
        lean_path.write_text(noted_lean, encoding="utf-8")
        report_path.write_text(report.replace(
            anchor,
            f"{anchor}\n| `disclosed_noted` | {noted_line} | Abstract | "
            "unregistered | Line-comment round-trip fixture. |", 1),
            encoding="utf-8")
        invoke(fixture, True, "9 P-ALLOC-1 theorems")
        lean_path.write_text(lean, encoding="utf-8")
        report_path.write_text(report, encoding="utf-8")

        # A wrapped declaration must also be citable, and it is cited at the
        # line its keyword opens — the same line the unwrapped forms occupy.
        # Were it recorded at the name's line instead, the report could only be
        # satisfied by a number that points at no keyword.
        wrapped = "theorem disclosed_wrapped\n    : True := trivial"
        wrapped_lean = lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                                    f"{wrapped}\n\n"
                                    "end LidoSRv3.Audit.Guarantees.PAlloc1", 1)
        if wrapped_lean == lean:
            raise AssertionError("wrapped round-trip mutant changed nothing")
        keyword_line = wrapped_lean.splitlines().index("theorem disclosed_wrapped") + 1
        anchor = next(line for line in report.splitlines()
                      if line.startswith("| `router_order_preserved` |"))
        lean_path.write_text(wrapped_lean, encoding="utf-8")
        report_path.write_text(report.replace(
            anchor,
            f"{anchor}\n| `disclosed_wrapped` | {keyword_line} | Abstract | "
            "unregistered | Wrapped-declaration round-trip fixture. |", 1),
            encoding="utf-8")
        invoke(fixture, True, "9 P-ALLOC-1 theorems")
        report_path.write_text(report.replace(
            anchor,
            f"{anchor}\n| `disclosed_wrapped` | {keyword_line + 1} | Abstract | "
            "unregistered | Wrapped-declaration round-trip fixture. |", 1),
            encoding="utf-8")
        invoke(fixture, False, f"disclosed_wrapped is declared at Lean line {keyword_line}")
        lean_path.write_text(lean, encoding="utf-8")
        report_path.write_text(report, encoding="utf-8")

        # Lean identifiers are not ASCII.  A name may begin with a letter-like
        # character (Greek, Coptic, Latin-1/Extended-A, script, double-struck),
        # carry subscripts or `!`/`?`, be «guillemet-escaped», or be a `.`-joined
        # compound name.  An ASCII-only capture does not recognize such a
        # declaration at all, so the module could gain an ordinary Lean theorem
        # that the report never lists while this gate still reported success.
        # Every spelling below compiles under the pinned toolchain.
        for spelling, hidden in (
            ("theorem αUndisclosed", "αUndisclosed"),
            ("theorem Δundisclosed", "Δundisclosed"),
            ("theorem ℕundisclosed", "ℕundisclosed"),
            ("theorem éundisclosed", "éundisclosed"),
            ("theorem undisclosed₁", "undisclosed₁"),
            ("theorem undisclosedᵢ", "undisclosedᵢ"),
            ("theorem undisclosed?", "undisclosed?"),
            ("theorem undisclosed!", "undisclosed!"),
            ("theorem «undisclosed escaped»", "«undisclosed escaped»"),
            ("theorem Undisclosed.dotted", "Undisclosed.dotted"),
            ("lemma αundisclosed_lemma", "αundisclosed_lemma"),
            ("  @[simp] private lemma αundisclosed_combined", "αundisclosed_combined"),
        ):
            report_path.write_text(report, encoding="utf-8")
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{spelling} : True := trivial\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {hidden}")
            lean_path.write_text(lean, encoding="utf-8")

        # Reading Lean's identifiers must leave the gate satisfiable: the row
        # parser has to accept every name the Lean parser can now find.  Were
        # only one side widened, the gate would demand an inventory row it could
        # never read, and no edit to the report could satisfy it.
        declaration = "theorem αdisclosed : True := trivial"
        widened_lean = lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                                    f"{declaration}\n\n"
                                    "end LidoSRv3.Audit.Guarantees.PAlloc1", 1)
        if widened_lean == lean:
            raise AssertionError("unicode round-trip mutant changed nothing")
        anchor = next(line for line in report.splitlines()
                      if line.startswith("| `router_order_preserved` |"))
        widened_report = report.replace(
            anchor,
            f"{anchor}\n| `αdisclosed` | "
            f"{widened_lean.splitlines().index(declaration) + 1} | Abstract | "
            "unregistered | Letter-like identifier round-trip fixture. |", 1)
        lean_path.write_text(widened_lean, encoding="utf-8")
        report_path.write_text(widened_report, encoding="utf-8")
        invoke(fixture, True, "9 P-ALLOC-1 theorems")
        lean_path.write_text(lean, encoding="utf-8")
        report_path.write_text(report, encoding="utf-8")

        # The other direction: widening the parser to cover those variants must
        # not start counting lines that declare nothing.  A commented-out
        # declaration and an identifier that merely begins with the keyword are
        # both still non-declarations.  `theoremαUndisclosed` is the case the
        # Unicode widening introduces: α is an identifier character, so the
        # whole word is one ordinary Lean name, not the keyword plus a theorem.
        for not_a_declaration in (
            "  -- theorem commented_out : True := trivial",
            "  -- lemma commented_out_lemma : True := trivial",
            "  -- theorem αcommented_out : True := trivial",
            "def theorem_like_name : Nat := 0",
            "def lemma_like_name : Nat := 0",
            "def theoremαUndisclosed : Nat := 0",
            "def lemmaαUndisclosed : Nat := 0",
        ):
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{not_a_declaration}\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            lean_path.write_text(lean, encoding="utf-8")

        # Lean block comments nest.  Prose inside a comment that merely begins a
        # line with `theorem` declares nothing, so demanding an inventory row for
        # it would fail the gate on valid source.  The nested cases are the ones
        # a first-`-/` scan gets wrong; each must still read as commented out.
        for commented in (
            "/- outer\n   /- nested -/\n   theorem only_prose : True := trivial\n-/",
            "/- outer\n   /- a -/ /- b -/\n   lemma only_prose_lemma : True := trivial\n-/",
            "/- /- /- deep -/ -/\n   theorem only_prose_deep : True := trivial\n-/",
            "/-- doc\n    /- nested -/\n    theorem only_prose_doc : True := trivial\n-/",
        ):
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{commented}\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            lean_path.write_text(lean, encoding="utf-8")

        # The scanner must resume reading source at the outer comment's real
        # end, not run on to EOF: a declaration after a nested comment is still
        # a declaration and must still be demanded.
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "/- outer\n   /- nested -/\n   theorem only_prose : True := trivial\n-/\n"
                         "theorem undisclosed_after_nested : True := trivial\n\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, False, "omits declared theorem(s): undisclosed_after_nested")
        lean_path.write_text(lean, encoding="utf-8")

        # A `/-` that is not an opener must not blank the source after it.
        # This is the direction that fails open: swallowing real declarations
        # would let the inventory omit them while the gate still passed.
        for not_an_opener in (
            "-- prose mentioning /- an opener\ntheorem undisclosed_after_line_comment",
            'def commentish : String := "/-"\ntheorem undisclosed_after_string',
        ):
            body, name = not_an_opener.rsplit("theorem ", 1)
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{body}theorem {name} : True := trivial\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {name}")
            lean_path.write_text(lean, encoding="utf-8")

        # Every modifier that elaborates in front of a `theorem` must be
        # asserted, not just the ones that happened to be listed above: a
        # spelling the gate tolerates but the suite never exercises is a spelling
        # that can hide a theorem from the inventory the day it is used.  The
        # loop reads the checker's own table so a modifier added later arrives
        # with its case already demanded.
        for modifier in CHECK.MODIFIERS_ON_THEOREM:
            hidden = f"undisclosed_{modifier}_modifier"
            report_path.write_text(report, encoding="utf-8")
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{modifier} theorem {hidden} : True := trivial\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {hidden}")
            lean_path.write_text(lean, encoding="utf-8")

        # The remaining table entries cannot be driven end to end, because Lean
        # refuses the declaration they prefix (`'unsafe' theorems are not
        # allowed`, `'theorem' subsumes 'noncomputable'`, and `scoped`/`local`
        # do not parse before `theorem` at all), so no compiling module can
        # contain one.  They are kept as parser widening, and widening is only
        # sound while it still recognizes the declaration rather than skipping
        # past it, which is what is asserted here.
        for modifier in CHECK.MODIFIERS_REJECTED_ON_THEOREM:
            hidden = f"undisclosed_{modifier}_modifier"
            match = CHECK.DECL.match(f"{modifier} theorem {hidden} : True := trivial")
            if not match or match.group(1) != hidden:
                raise AssertionError(
                    f"modifier {modifier!r} is listed but the declaration parser "
                    f"does not read {hidden!r} behind it")

        # A «guillemet-escaped» identifier is a name, not code, so the comment
        # markers a Lean author may legally put inside one must not be lexed as
        # comment delimiters.  Reading `«undisclosed /- name»` as an opener
        # rejected a valid module outright, and — worse — a later escaped atom
        # carrying `-/` rebalanced the depth and blanked the real declarations
        # in between, so the inventory could omit them with the gate still
        # green.  Both directions are asserted: the escaped name is demanded,
        # and nothing around it is swallowed.
        for spelling, hidden in (
            ("theorem «undisclosed /- name»", "«undisclosed /- name»"),
            ("theorem «undisclosed -/ name»", "«undisclosed -/ name»"),
            ("theorem «undisclosed -- name»", "«undisclosed -- name»"),
            ('theorem «undisclosed " name»', '«undisclosed " name»'),
            ("theorem «undisclosed /-- name»", "«undisclosed /-- name»"),
        ):
            report_path.write_text(report, encoding="utf-8")
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{spelling} : True := trivial\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {hidden}")
            lean_path.write_text(lean, encoding="utf-8")

        # The fail-open direction: an escaped `/-` followed by an escaped `-/`
        # balances to depth zero, so a scanner that lexes them would blank every
        # declaration between the two and report success on an inventory that
        # omits all three.
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "theorem «opener /- escaped» : True := trivial\n"
                         "theorem undisclosed_between_escapes : True := trivial\n"
                         "theorem «closer -/ escaped» : True := trivial\n\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, False, "undisclosed_between_escapes")
        lean_path.write_text(lean, encoding="utf-8")

        # An unclosed `«` is ordinary text rather than an escape, so it must not
        # swallow the declarations that follow it.
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "-- a stray « never closed on this line\n"
                         "theorem undisclosed_after_stray_escape : True := trivial\n\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, False, "omits declared theorem(s): undisclosed_after_stray_escape")
        lean_path.write_text(lean, encoding="utf-8")

        # A `«` inside a real block comment is still comment text: it must not
        # start an escape that runs past the comment's `-/` and swallows code.
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "/- prose mentioning « an escape -/\n"
                         "theorem undisclosed_after_commented_escape : True := trivial\n\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, False, "omits declared theorem(s): undisclosed_after_commented_escape")
        lean_path.write_text(lean, encoding="utf-8")

        # Prose inside a real block comment that merely names an escaped
        # identifier still declares nothing.  Reading the `«` as an escape would
        # run past the comment's own `-/` and count the prose as a declaration.
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "/- theorem «only prose escaped» : True := trivial -/\n\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, True, "8 P-ALLOC-1 theorems")
        lean_path.write_text(lean, encoding="utf-8")

        # And the escaped name must round-trip: the row parser has to accept the
        # very spelling the declaration parser now finds, or the gate would
        # demand a row no edit to the report could satisfy.
        escaped = "theorem «disclosed /- name» : True := trivial"
        escaped_lean = lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                                    f"{escaped}\n\n"
                                    "end LidoSRv3.Audit.Guarantees.PAlloc1", 1)
        anchor_row = next(line for line in report.splitlines()
                          if line.startswith("| `router_order_preserved` |"))
        escaped_report = report.replace(
            anchor_row,
            f"{anchor_row}\n| `«disclosed /- name»` | "
            f"{escaped_lean.splitlines().index(escaped) + 1} | Abstract | "
            "unregistered | Escaped-identifier round-trip fixture. |", 1)
        lean_path.write_text(escaped_lean, encoding="utf-8")
        report_path.write_text(escaped_report, encoding="utf-8")
        invoke(fixture, True, "9 P-ALLOC-1 theorems")
        lean_path.write_text(lean, encoding="utf-8")
        report_path.write_text(report, encoding="utf-8")

        # An unterminated block comment leaves the rest of the file unreadable;
        # it must fail closed rather than silently inventorying nothing.
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "/- outer /- nested -/\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, False, "unterminated block comment")
        lean_path.write_text(lean, encoding="utf-8")

        # An unregistered theorem promoted to REGISTERED in the report only.  The
        # incumbent is demoted in the same edit so the field it vacates is free:
        # otherwise the two rows collide and the narrower duplicate-field rule
        # answers first, leaving the registry-mapping rule itself unasserted.
        promoted = report.replace(
            "| `active_capacity_bounded` | 69 | Abstract | unregistered |",
            "| `active_capacity_bounded` | 69 | Abstract | REGISTERED as `abstract.theorem` |", 1)
        promoted = promoted.replace(
            "| `checked_execute` | 122 | Abstract | REGISTERED as `abstract.theorem` |",
            "| `checked_execute` | 122 | Abstract | unregistered |", 1)
        if promoted == report or "`checked_execute` | 122 | Abstract | unregistered" not in promoted:
            raise AssertionError("promotion mutant changed nothing")
        report_path.write_text(promoted, encoding="utf-8")
        invoke(fixture, False, "REGISTERED; registry names")
        report_path.write_text(report, encoding="utf-8")

        # The registry moves its registered theorem; the report must follow.
        mutated = json.loads(json.dumps(registry))
        row = next(g for g in mutated["guarantees"] if g["id"] == "P-ALLOC-1")
        row["abstract"]["theorem"] = \
            "LidoSRv3.Audit.Guarantees.PAlloc1.source_capacities_match_canonical"
        registry_path.write_text(json.dumps(mutated, indent=2) + "\n", encoding="utf-8")
        invoke(fixture, False, "REGISTERED; registry names")
        registry_path.write_text(json.dumps(registry, indent=2) + "\n", encoding="utf-8")

        # A REGISTERED cell prints which registry field backs the theorem, and the
        # row prints which plane it lives on.  Comparing unordered name sets read
        # neither, so exchanging the two labels published a report that
        # misidentifies which theorem backs each CHECKED plane while this gate
        # stayed green.  Drive every pairing from the checker's own plane table so
        # a plane added later arrives with its case already demanded.
        registered_rows = {}
        for line in report.splitlines():
            claim = CHECK.ROW.match(line)
            if claim and claim.group("registered").strip().startswith("REGISTERED"):
                field = CHECK.REGISTRATION.match(claim.group("registered").strip())
                if not field:
                    raise AssertionError(f"canonical row registers no known field: {line}")
                registered_rows[field.group("plane")] = line
        if set(registered_rows) != set(CHECK.PLANES):
            raise AssertionError(f"canonical report registers {sorted(registered_rows)}, "
                                 f"checker knows {sorted(CHECK.PLANES)}")

        def refile(line, was, now, plane=False):
            """Re-file a row under another registry field, optionally relabelling it."""
            rewritten = line.replace(f"`{was}.theorem`", f"`{now}.theorem`", 1)
            if plane:
                rewritten = rewritten.replace(f"| {CHECK.PLANES[was]} |",
                                              f"| {CHECK.PLANES[now]} |", 1)
            if rewritten == line:
                raise AssertionError(f"re-filing {was} as {now} changed nothing in: {line}")
            return rewritten

        def mutate(needle, *edits):
            mutated_report = report
            for line, rewritten in edits:
                mutated_report = mutated_report.replace(line, rewritten, 1)
            report_path.write_text(mutated_report, encoding="utf-8")
            invoke(fixture, False, needle)
            report_path.write_text(report, encoding="utf-8")

        for held, other in ((a, b) for a in registered_rows for b in registered_rows if a != b):
            kept, swapped = registered_rows[held], registered_rows[other]

            # Exchanging the registrations while each row keeps its printed plane
            # leaves the row contradicting its own registration.
            mutate("disagree about which plane the theorem backs",
                   (kept, refile(kept, held, other)),
                   (swapped, refile(swapped, other, held)))

            # Exchanging the plane labels alone is the same contradiction read
            # from the other side.
            mutate("disagree about which plane the theorem backs",
                   (kept, kept.replace(f"| {CHECK.PLANES[held]} |",
                                       f"| {CHECK.PLANES[other]} |", 1)),
                   (swapped, swapped.replace(f"| {CHECK.PLANES[other]} |",
                                             f"| {CHECK.PLANES[held]} |", 1)))

            # Exchanging both leaves two internally consistent rows that name the
            # wrong registry theorems — the swap an unordered name set could not
            # see at all.
            mutate("REGISTERED; registry names",
                   (kept, refile(kept, held, other, plane=True)),
                   (swapped, refile(swapped, other, held, plane=True)))

            # Both rows filed under one field, which records a single theorem.
            mutate(f"both claim registry field `{held}.theorem`",
                   (swapped, refile(swapped, other, held, plane=True)))

            # A registration naming no registry field at all.
            mutate("names none of the registry fields",
                   (kept, kept.replace(f"REGISTERED as `{held}.theorem`", "REGISTERED", 1)))

        # A registration names one plane, and the row must print that plane and
        # nothing wider.  Testing containment made every column the plane's label
        # is spelled inside an acceptable spelling of it, so the composite column
        # — which spells both — stood in for either registration and a row
        # registered for one plane could publish a claim on both with this gate
        # still green.  The wider columns are derived from the checker's own
        # table, so one added later arrives with its case already demanded.
        supersets = [(plane, column) for plane in registered_rows
                     for column in CHECK.PLANE_COLUMNS
                     if column != CHECK.PLANES[plane] and CHECK.PLANES[plane] in column]
        if not supersets:
            raise AssertionError("no plane column contains a registered plane's label, "
                                 "so the containment family asserts nothing")
        for plane, column in supersets:
            kept = registered_rows[plane]
            mutate("disagree about which plane the theorem backs",
                   (kept, kept.replace(f"| {CHECK.PLANES[plane]} |", f"| {column} |", 1)))

        # Read from the other side: the same widening claimed by promoting the
        # row that legitimately prints the composite column.  Demoting the
        # incumbent in the same edit frees the field, so the plane rule answers
        # rather than the narrower duplicate-field rule.
        composite_row = next((line for line in report.splitlines()
                              if f"| {CHECK.COMPOSITE_PLANE} |" in line), None)
        if composite_row is None:
            raise AssertionError(
                f"canonical report prints no {CHECK.COMPOSITE_PLANE!r} row, so demanding "
                "an exact plane may have outlawed a column the report needs")
        for plane, incumbent in registered_rows.items():
            mutate("disagree about which plane the theorem backs",
                   (incumbent, incumbent.replace(
                       f"REGISTERED as `{plane}.theorem`", "unregistered", 1)),
                   (composite_row, composite_row.replace(
                       "| unregistered |", f"| REGISTERED as `{plane}.theorem` |", 1)))

        # The Registered column publishes exactly two markers, and a reader reads
        # the cell rather than the checker's parse of it.  Skipping every cell
        # that did not begin with `REGISTERED` treated an unrecognized spelling
        # as a silent "no claim", so a row could print a lookalike — lowercase
        # `registered` is the plain case — and be read as promoted while the
        # registry recorded nothing and this gate stayed green.  Every row the
        # inventory prints is put through every lookalike, so a row or a plane
        # added later arrives with its case already demanded, and the marker is
        # asserted to be matched case-sensitively as the whole cell rather than
        # by a prefix that a longer or differently-cased word satisfies.
        marker_rows = [line for line in report.splitlines() if CHECK.ROW.match(line)]
        if len(marker_rows) != len(set(marker_rows)):
            raise AssertionError("the canonical inventory prints a row twice")

        def recell(line, marker):
            """Reprint `line` with `marker` in the Registered column, padding kept."""
            cells = CHECK.ROW.match(line)
            return line[:cells.start("registered")] + marker + line[cells.end("registered"):]

        lookalikes = ["registered", "Registered", "REGISTERED", "UNREGISTERED",
                      "Unregistered", "un-registered", "not registered", "unregistered."]
        lookalikes += [spelling.format(plane=plane) for plane in CHECK.PLANES
                       for spelling in ("registered as `{plane}.theorem`",
                                        "Registered as `{plane}.theorem`",
                                        "REGISTERED AS `{plane}.theorem`",
                                        "REGISTERED as `{plane}.theorem` (pending)")]
        for line in marker_rows:
            name = CHECK.ROW.match(line).group("name")
            for marker in lookalikes:
                rewritten = recell(line, marker)
                if rewritten == line:
                    raise AssertionError(f"lookalike {marker!r} changed nothing in: {line}")
                mutate(f"{name} prints {marker!r} in the Registered column",
                       (line, rewritten))

        # A repeated row was dropped rather than checked, because indexing the
        # matches by name keeps only the last one.  Every cell the gate reads can
        # be falsified in an earlier copy while the surviving copy stays correct,
        # so each is asserted rather than trusting the REGISTERED case to stand
        # for the rest — and the repeat is asserted in both orders, since a rule
        # that only caught the trailing copy would still let the leading one
        # publish a false claim.
        repeated_anchor = next(line for line in report.splitlines()
                               if line.startswith("| `active_capacity_bounded` |"))
        for label, wrong in (
            ("promoted to REGISTERED",
             repeated_anchor.replace("| unregistered |",
                                     "| REGISTERED as `abstract.theorem` |", 1)),
            ("stale line", repeated_anchor.replace("| 69 |", "| 6900 |", 1)),
            ("no recognized plane", repeated_anchor.replace("| Abstract |", "| n/a |", 1)),
            ("verbatim repeat", repeated_anchor),
        ):
            if label != "verbatim repeat" and wrong == repeated_anchor:
                raise AssertionError(f"duplicate-row mutant {label!r} changed nothing")
            for duplicated in (f"{wrong}\n{repeated_anchor}", f"{repeated_anchor}\n{wrong}"):
                report_path.write_text(report.replace(repeated_anchor, duplicated, 1),
                                       encoding="utf-8")
                invoke(fixture, False,
                       "lists theorem(s) more than once: active_capacity_bounded")
                report_path.write_text(report, encoding="utf-8")

        # A stale line number: the citation must point at the real declaration.
        stale = report.replace("| `checked_execute` | 122 |", "| `checked_execute` | 104 |", 1)
        if stale == report:
            raise AssertionError("line mutant changed nothing")
        report_path.write_text(stale, encoding="utf-8")
        invoke(fixture, False, "checked_execute is declared at Lean line 122")
        report_path.write_text(report, encoding="utf-8")

        # A row that names no abstract/Verity plane.
        planeless = report.replace("| `verity_tx_revert_restores_snapshot` | 220 | Verity |",
                                   "| `verity_tx_revert_restores_snapshot` | 220 | n/a |", 1)
        if planeless == report:
            raise AssertionError("plane mutant changed nothing")
        report_path.write_text(planeless, encoding="utf-8")
        invoke(fixture, False, "no recognized abstract/Verity plane")
        report_path.write_text(report, encoding="utf-8")

        # A Markdown row is delimited by its pipes, not by its padding: the same
        # row rendered tighter or looser publishes the same table to a reader.
        # Keying on one exact whitespace layout meant such a row was not parsed
        # at all, so a false claim printed beside the correct one escaped every
        # cell check and the duplicate check with it.  Each layout is asserted
        # three ways: the canonical row re-rendered in it must still be read (or
        # its theorem would report as omitted), a repeat in it must be rejected,
        # and a row naming no Lean theorem must be rejected.
        layout_anchor = next(line for line in report.splitlines()
                             if line.startswith("| `active_capacity_bounded` |"))
        cells = CHECK.ROW.match(layout_anchor)
        if not cells:
            raise AssertionError("the checker cannot parse its own canonical row")
        parts = {key: cells.group(key)
                 for key in ("name", "line", "plane", "registered", "role")}

        for layout in (
            "|`{name}`|{line}|{plane}|{registered}|{role}|",
            "| `{name}`| {line} | {plane} | {registered} | {role} |",
            "|   `{name}`   |   {line}   |   {plane}   |   {registered}   |   {role}   |",
            "|\t`{name}`\t|\t{line}\t|\t{plane}\t|\t{registered}\t|\t{role}\t|",
            "   | `{name}` | {line} | {plane} | {registered} | {role} |",
            "| `{name}` | {line} | {plane} | {registered} | {role} |  ",
        ):
            rendered = layout.format(**parts)
            report_path.write_text(report.replace(layout_anchor, rendered, 1),
                                   encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")

            report_path.write_text(
                report.replace(layout_anchor, f"{layout_anchor}\n{rendered}", 1),
                encoding="utf-8")
            invoke(fixture, False,
                   "lists theorem(s) more than once: active_capacity_bounded")

            bogus = layout.format(name="bogus_absent_theorem", line="999", plane="Bogus",
                                  registered="REGISTERED", role="False claim.")
            report_path.write_text(
                report.replace(layout_anchor, f"{layout_anchor}\n{bogus}", 1),
                encoding="utf-8")
            invoke(fixture, False,
                   "lists theorem(s) absent from Lean: bogus_absent_theorem")
            report_path.write_text(report, encoding="utf-8")

        # A declaration's leaf is not its identity.  `namespace A` and
        # `namespace B` may each declare `collision`; Lean knows them apart, and
        # recording leaves alone let the second silently overwrite the first, so
        # one row stood for two distinct theorems and the inventory could omit
        # one with this gate still green.  Both must be demanded by name.
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "namespace A\ntheorem collision : True := trivial\nend A\n\n"
                         "namespace B\ntheorem collision : True := trivial\nend B\n\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, False, "omits declared theorem(s): A.collision, B.collision")
        lean_path.write_text(lean, encoding="utf-8")

        # The qualified name must round-trip: the row parser has to accept the
        # very name the scope tracker produces, or the gate would demand a row no
        # edit to the report could satisfy.  A `section` closes like any other
        # scope but contributes nothing to a name, named or not.  A bare `end`
        # is valid Lean regardless of whether the opening label was named, so
        # `namespace Inner … end` and `section Named … end` must both succeed
        # here; the checker previously compared `None != "Inner"` and rejected.
        for opener, closer, qualified in (
            ("namespace Inner", "end Inner", "Inner.scoped_thm"),
            ("namespace Outer.Deep", "end Outer.Deep", "Outer.Deep.scoped_thm"),
            ("namespace Inner", "end", "Inner.scoped_thm"),
            ("section", "end", "scoped_thm"),
            ("section Named", "end Named", "scoped_thm"),
            ("section Named", "end", "scoped_thm"),
        ):
            declaration = "theorem scoped_thm : True := trivial"
            scoped_lean = lean.replace(
                "end LidoSRv3.Audit.Guarantees.PAlloc1",
                f"{opener}\n{declaration}\n{closer}\n\n"
                "end LidoSRv3.Audit.Guarantees.PAlloc1", 1)
            keyword_line = scoped_lean.splitlines().index(declaration) + 1
            lean_path.write_text(scoped_lean, encoding="utf-8")
            report_path.write_text(report, encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {qualified}")
            report_path.write_text(report.replace(
                layout_anchor,
                f"{layout_anchor}\n| `{qualified}` | {keyword_line} | Abstract | "
                "unregistered | Scope round-trip fixture. |", 1),
                encoding="utf-8")
            invoke(fixture, True, "9 P-ALLOC-1 theorems")
            lean_path.write_text(lean, encoding="utf-8")
            report_path.write_text(report, encoding="utf-8")

        # The inventory a reader meets is the table under `## Theorems`, and the
        # section says in prose that it lists every theorem in the module.
        # Counting rows anywhere in the document read a row filed under an
        # unrelated heading as if it were in that table, so any row could be
        # moved off the section — leaving the inventory short while the document
        # still spelled the row somewhere — with this gate green.  Every
        # canonical row is driven through it, relocated and copied.
        section = CHECK.SECTION.search(report)
        if not section:
            raise AssertionError("canonical report has no `## Theorems` section")
        elsewhere = "## Resolution"
        if elsewhere not in report[section.end("body"):]:
            raise AssertionError(f"canonical report has no {elsewhere!r} heading "
                                 "after the inventory to relocate a row into")
        inventory_rows = [line for line in section.group("body").splitlines()
                          if CHECK.ROW.match(line)]
        if len(inventory_rows) != 8:
            raise AssertionError(f"expected 8 inventory rows, read {len(inventory_rows)}")
        for line in inventory_rows:
            name = CHECK.ROW.match(line).group("name")
            needle = ("prints inventory row(s) outside the rendered theorem table: "
                      f"{name}")

            relocated = report.replace(f"{line}\n", "", 1).replace(
                elsewhere, f"{elsewhere}\n\n{line}\n", 1)
            if line in relocated.split(elsewhere)[0]:
                raise AssertionError(f"relocation mutant for {name} changed nothing")
            report_path.write_text(relocated, encoding="utf-8")
            invoke(fixture, False, needle)

            # The same claim published twice: the table a reader meets stays
            # correct, so only reading the section can see the second copy.
            report_path.write_text(report.replace(elsewhere, f"{elsewhere}\n\n{line}\n", 1),
                                   encoding="utf-8")
            invoke(fixture, False, needle)
            report_path.write_text(report, encoding="utf-8")

        # A whole second inventory filed further down: whichever copy the gate
        # read, the other published unchecked rows.
        report_path.write_text(report.replace(
            elsewhere, f"## Theorems\n\n{section.group('body').strip()}\n\n{elsewhere}", 1),
            encoding="utf-8")
        invoke(fixture, False, "prints inventory row(s) outside the rendered theorem table")
        report_path.write_text(report, encoding="utf-8")

        # And the section has to be locatable at all: renaming or demoting the
        # heading leaves the rows in the document with no inventory to be in.
        for renamed in ("## Theorem inventory", "### Theorems", "**Theorems**"):
            report_path.write_text(report.replace("## Theorems", renamed, 1), encoding="utf-8")
            invoke(fixture, False, "has no `## Theorems` section")
            report_path.write_text(report, encoding="utf-8")

        # A row is a published claim only where Markdown renders one.  Inside a
        # code fence the pipes are printed as literal characters, inside an HTML
        # comment nothing is printed at all, and inside any other HTML block the
        # line is passed through as raw HTML rather than parsed as a row, so
        # reading the raw file counted rows a reader never meets: any row could
        # be fenced, commented out or wrapped in `<div>` — leaving the rendered
        # table short while the file still spelled the row — with this gate
        # green.  Every canonical row is driven through every construct, since
        # one the suite never exercises is one that can hide a row the day it is
        # used, and every one of CommonMark's seven HTML block start conditions
        # appears here because recognizing six of them leaves the seventh able to
        # carry the row.  Each mutant ends its block before the next row so the
        # gate names exactly the theorem it hid.
        non_rendered = (
            lambda line: f"```\n{line}\n```",
            lambda line: f"```text\n{line}\n```",
            lambda line: f"~~~\n{line}\n~~~",
            lambda line: f"   ```\n{line}\n   ```",
            lambda line: f"````\n```\n{line}\n```\n````",
            lambda line: f"```\n{line}\n``````",
            lambda line: f"<!-- {line} -->",
            lambda line: f"<!--\n{line}\n-->",
            lambda line: f"<!-- a --> <!--\n{line}\n-->",
            lambda line: f"<script>\n{line}\n</script>",
            lambda line: f"<pre>\n{line}\n</pre>",
            lambda line: f"<?php\n{line}\n?>",
            lambda line: f"<!DOCTYPE html\n{line}\n>",
            lambda line: f"<![CDATA[\n{line}\n]]>",
            lambda line: f"<div>\n{line}\n</div>\n",
            lambda line: f'<div class="inventory">\n{line}\n</div>\n',
            lambda line: f"<DIV>\n{line}\n</DIV>\n",
            lambda line: f"   <div>\n{line}\n</div>\n",
            lambda line: f"<table>\n{line}\n</table>\n",
            lambda line: f"</div>\n{line}\n",
            lambda line: f'\n<span class="hidden">\n{line}\n',
            lambda line: f"    {line}",
            lambda line: f"\t{line}",
        )
        # Each row is driven from the last position in the table.  A construct
        # that hides a row also ends the rendered table on the line it opens, so
        # hiding a row in the middle takes every row below it out of the table
        # too and the gate names those instead — a true report, but not the one
        # this family is asserting.  Row order carries no claim (the inventory
        # is read by name), so moving the row under test to the end isolates
        # "this construct hid this row" exactly.  The reordering itself is
        # asserted to pass, so the isolation cannot be hiding a failure.
        last = inventory_rows[-1]
        for line in inventory_rows:
            name = CHECK.ROW.match(line).group("name")
            reordered = (report if line == last
                         else report.replace(f"{line}\n", "", 1)
                                    .replace(f"{last}\n", f"{last}\n{line}\n", 1))
            if line != last:
                if reordered == report or f"{last}\n{line}\n" not in reordered:
                    raise AssertionError(f"reorder mutant for {name} changed nothing")
                report_path.write_text(reordered, encoding="utf-8")
                invoke(fixture, True, "8 P-ALLOC-1 theorems")
            for hide in non_rendered:
                hidden = reordered.replace(line, hide(line), 1)
                if hidden == reordered:
                    raise AssertionError(f"non-rendered mutant for {name} changed nothing")
                report_path.write_text(hidden, encoding="utf-8")
                invoke(fixture, False, f"omits declared theorem(s): {name}")
                report_path.write_text(report, encoding="utf-8")

        # Adversarial (certified defect 3 family): the table stops where GFM
        # stops it.  A row hidden in the middle of the body ends the rendered
        # table there, so every row printed below it is outside the inventory a
        # reader meets even though the section still spells it.  Reading rows to
        # the end of the section counted all eight while the page showed one.
        for position, line in enumerate(inventory_rows[:-1]):
            following = sorted(CHECK.ROW.match(row).group("name")
                               for row in inventory_rows[position + 1:])
            report_path.write_text(report.replace(line, f"```\n{line}\n```", 1),
                                   encoding="utf-8")
            invoke(fixture, False, "prints inventory row(s) outside the rendered theorem "
                                   f"table: {', '.join(following)}")
            report_path.write_text(report, encoding="utf-8")

        # Condition 6 is a list of tag names, and a name the suite never
        # exercises is a name that can hide a row the day it is used.  Each is
        # driven once, from the checker's own list, so a name a later CommonMark
        # revision adds arrives with its case already demanded.
        # Driven from the last row for the same reason as the family above: a
        # block opened mid-table ends the table there, so hiding the first row
        # would be reported as the seven rows that leave the inventory with it.
        first = inventory_rows[-1]
        first_name = CHECK.ROW.match(first).group("name")
        block_names = CHECK.HTML_BLOCK_NAMES.split("|")
        if "div" not in block_names or len(block_names) < 60:
            raise AssertionError(f"implausible HTML block name list: {block_names}")
        for tag in block_names:
            report_path.write_text(report.replace(first, f"<{tag}>\n{first}\n</{tag}>\n", 1),
                                   encoding="utf-8")
            invoke(fixture, False, f"omits declared theorem(s): {first_name}")
        report_path.write_text(report, encoding="utf-8")

        # An unterminated HTML comment runs to the end of the document, so it
        # hides every row below it rather than only the one it opens on.  The
        # same holds for a raw-text element, which ends on its own closing tag
        # and so is not stopped by the blank line that ends a `<div>`.
        for runaway in ("<!--", "<script>"):
            report_path.write_text(report.replace(inventory_rows[-1],
                                                  f"{runaway}\n{inventory_rows[-1]}", 1),
                                   encoding="utf-8")
            invoke(fixture, False, "omits declared theorem(s)")
            report_path.write_text(report, encoding="utf-8")

        # A heading quoted inside a fence or an HTML block is not a heading, so
        # it must not relocate the section onto a table no reader meets.
        for quoted in (f"```\n## Theorems\n\n{inventory_rows[0]}\n```",
                       f"<div>\n## Theorems\n{inventory_rows[0]}\n</div>"):
            report_path.write_text(report.replace(
                "## Theorems", f"{quoted}\n\n## Theorems", 1), encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            report_path.write_text(report, encoding="utf-8")

        # And a row outside the section publishes nothing either when it is
        # fenced or raw HTML, so it is not the stray claim a bare copy would be.
        for quoted in (f"```\n{inventory_rows[0]}\n```",
                       f"<div>\n{inventory_rows[0]}\n</div>"):
            report_path.write_text(report.replace(
                elsewhere, f"{elsewhere}\n\n{quoted}\n", 1), encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            report_path.write_text(report, encoding="utf-8")

        # The opposite failure is worse than the one being fixed: masking text
        # that Markdown does render would blank the real table and leave a gate
        # no edit to the report could satisfy.  Each construct below only looks
        # like an opener, so the inventory beneath it must still be read.
        for still_rendered in (
            "```\nprose in a closed fence\n```",
            "``\nnot a fence: two backticks\n``",
            "```a`b\nnot a fence: backtick in the info string\n",
            "```\nclosed by a longer fence\n````",
            "~~~\n```\na tilde fence holds a backtick fence\n```\n~~~",
            "<!-- a closed comment -->",
            "<!-- a\n  closed\n  multi-line comment -->",
            "    ```\n    an indented block that is not a fence\n",
            "<div>\na block that ends at the blank line below it\n</div>",
            "<script>\na raw-text element that ends on its own tag\n</script>",
            "<?php echo 'a processing instruction'; ?>",
            "<!DOCTYPE html>",
            "<![CDATA[ a character data section ]]>",
        ):
            report_path.write_text(
                report.replace("## Theorems", f"{still_rendered}\n\n## Theorems", 1),
                encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            report_path.write_text(report, encoding="utf-8")

        # The sharpest form of that failure is a line that only resembles an
        # opener sitting directly above the table: were it read as one, the block
        # would run to the blank line past the last row and blank the whole
        # inventory at once.  Each of these is inserted immediately before the
        # first row, so all eight must still be read.
        for inert in (
            "prose that mentions <div> in the middle of a line",
            '<span class="x">an inline tag with text after it</span> is not a block',
            "<3 is not a tag",
        ):
            report_path.write_text(
                report.replace(inventory_rows[0], f"{inert}\n{inventory_rows[0]}", 1),
                encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            report_path.write_text(report, encoding="utf-8")

        # The mirror of that family.  A complete tag alone on its line is HTML
        # block condition 7, and a table row is not a paragraph, so cmark-gfm
        # opens the block and ends the table there even though the same tag
        # under a paragraph line opens nothing.  Every row below it is then
        # printed as raw HTML, and the inventory a reader meets is the one row
        # above.  Asserting this as a must-pass claimed eight rendered rows for a
        # page that renders one.
        every_row = sorted(CHECK.ROW.match(row).group("name") for row in inventory_rows)
        report_path.write_text(
            report.replace(inventory_rows[0],
                           f"a paragraph line\n<span>\n{inventory_rows[0]}", 1),
            encoding="utf-8")
        invoke(fixture, False, "prints inventory row(s) outside the rendered theorem "
                               f"table: {', '.join(every_row)}")
        report_path.write_text(report, encoding="utf-8")

        # A mis-nested scope would qualify the declarations that follow under the
        # wrong name, and an unbalanced one leaves the qualification undefined;
        # each fails closed rather than guessing at the reader's expense.
        for broken, needle in (
            ("namespace A\ntheorem scoped_thm : True := trivial\nend B\n\n"
             "end LidoSRv3.Audit.Guarantees.PAlloc1",
             "closes B but A is open"),
            ("end LidoSRv3.Audit.Guarantees.PAlloc1\n\nnamespace Dangling",
             "leaves 1 scope(s) open at end of file"),
            ("end LidoSRv3.Audit.Guarantees.PAlloc1\n\nend Stray",
             "closes a scope that was never opened"),
        ):
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1", broken, 1),
                encoding="utf-8")
            invoke(fixture, False, needle)
            lean_path.write_text(lean, encoding="utf-8")

        # The header and its rows are only a table because one delimiter line
        # underlines them.  Delete it, blank its cells, or make it disagree with
        # the header's width and Markdown renders the whole inventory as a
        # paragraph of literal text, so the rows a reader meets are not rows.
        delimiter = "| --- | --- | --- | --- | --- |"
        for mutant in (
            "",
            "|     |     |     |     |     |",
            "| --- | --- |",
            "| --- | --- | --- | --- | --- | --- |",
            "    | --- | --- | --- | --- | --- |",
        ):
            body = report.replace(f"{delimiter}\n", f"{mutant}\n" if mutant else "", 1)
            report_path.write_text(body, encoding="utf-8")
            invoke(fixture, False, "0 rendered theorem tables")
            report_path.write_text(report, encoding="utf-8")

        # Up to three columns of indentation is ordinary block markup, and the
        # fourth is what makes an indented chunk: the delimiter, the header and a
        # row are each indented in turn and the inventory must still be read, or
        # the gate would reject a table cmark-gfm plainly renders.
        header_line = next(line for line in section.group("body").splitlines()
                           if line.endswith("| Line | Plane | Registered | Role |"))
        for indented in (report.replace(delimiter, f"  {delimiter}", 1),
                         report.replace(header_line, f"   {header_line}", 1),
                         report.replace(inventory_rows[0], f" {inventory_rows[0]}", 1)):
            if indented == report:
                raise AssertionError("short-indent control changed nothing")
            report_path.write_text(indented, encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            report_path.write_text(report, encoding="utf-8")

        # Adversarial (certified defect 1 family): an escaped pipe is a `|`
        # character that delimits no cell.  Writing one into the header narrows
        # the header by a column while leaving the character count unchanged, so
        # a delimiter row widened to match the *characters* balanced the old
        # count-the-pipes check exactly — and cmark-gfm, reading a five-cell
        # header under a six-cell delimiter, rendered no table at all while this
        # gate reported eight theorems and two registrations.  Each cell of the
        # header is driven, and each is also driven with the delimiter left at
        # its true width, where the table does render and must still be read.
        header = header_line
        wide = "| --- | --- | --- | --- | --- | --- |"
        escapes = ("\\|", "\\\\|", "\\\\\\|")
        cells = [cell for cell in header.strip("|").split("|")]
        if len(cells) != 5:
            raise AssertionError(f"expected a 5-cell inventory header, read {cells}")
        for position in range(len(cells)):
            for escape in escapes:
                mutated = list(cells)
                mutated[position] = f"{mutated[position].rstrip()} {escape} alias "
                spoiled = "|" + "|".join(mutated) + "|"
                report_path.write_text(
                    report.replace(header, spoiled, 1).replace(delimiter, wide, 1),
                    encoding="utf-8")
                invoke(fixture, False, "0 rendered theorem tables")
                # Under its own true width the same header renders as a table,
                # so the escape is not a defect in itself: only its disagreement
                # with the delimiter is.  The first column names the module and
                # is free to be reworded, so that one must still be read; the
                # other four are the column labels the inventory is identified
                # by, and rewording one retires the table this gate checks.
                report_path.write_text(report.replace(header, spoiled, 1), encoding="utf-8")
                invoke(fixture, position == 0, None if position == 0
                       else "0 rendered theorem tables")
                report_path.write_text(report, encoding="utf-8")

        # A role cell may legitimately print a pipe, and the escape is how it is
        # written: the row still renders five cells and must still be read.  A
        # pattern that spelled a cell as `[^|]*` could not cross the escape and
        # dropped the row instead, so the rows are read through the renderer's
        # own cell split and this case is a must-pass.
        for escape in escapes:
            spoiled_row = inventory_rows[0].replace("| Wave 2 parent.",
                                                    f"| Wave 2 {escape} parent.", 1)
            if spoiled_row == inventory_rows[0]:
                raise AssertionError("escaped-pipe row mutant changed nothing")
            report_path.write_text(report.replace(inventory_rows[0], spoiled_row, 1),
                                   encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
            report_path.write_text(report, encoding="utf-8")

        # The rejecting half of the same family: escaping a pipe that separates
        # two real cells removes the boundary, so the row renders four cells
        # where the table declares five and the columns after it shift left.
        # The row still reads as an inventory row to the eye and is not one.
        for escape in escapes[1:]:
            narrowed = inventory_rows[0].replace("| 122 | Abstract |",
                                                 f"| 122 {escape} Abstract |", 1)
            if narrowed == inventory_rows[0]:
                raise AssertionError("narrowing escape mutant changed nothing")
            report_path.write_text(report.replace(inventory_rows[0], narrowed, 1),
                                   encoding="utf-8")
            invoke(fixture, False, "is not an inventory row")
            report_path.write_text(report, encoding="utf-8")

        # Alignment colons are part of a valid delimiter, so a table that carries
        # them must still be read: rejecting it would leave no way to publish a
        # left-, right- or centre-aligned inventory.
        report_path.write_text(
            report.replace(delimiter, "| :--- | ---: | :-: | --- | --- |", 1),
            encoding="utf-8")
        invoke(fixture, True, "8 P-ALLOC-1 theorems")
        report_path.write_text(report, encoding="utf-8")

        invoke(fixture, True)

    print("report theorem inventory mutants rejected: dropped row, undisclosed theorem "
          "(column-zero, indented, tabbed, attributed, private, protected, nonrec, "
          "`lemma`, and combined), a name wrapped onto the line after its keyword "
          "(bare, `lemma`, blank-line-separated, prefixed, escaped and letter-like) "
          "with the wrapped form cited at its keyword's line, "
          "a line or block comment standing as the whitespace between a keyword "
          "and its name (bare, `lemma`, doubled, mixed, behind a modifier, behind "
          "an attribute, combined, escaped and letter-like) with that form cited "
          "at its keyword's line and neither the comment's newline nor a keyword "
          "written only as comment prose allowed to splice a declaration, "
          "letter-like/subscript/`!`/`?`/escaped/dotted Lean "
          "identifiers, declaration after a nested comment, `/-` in a line "
          "comment and in a string literal, unterminated comment, report-only promotion, "
          "registry drift, stale line, missing plane, a row repeated with each "
          "checked cell falsified in one copy (REGISTERED, line, plane, and a "
          "verbatim repeat) in either order; commented-out declarations, "
          "theorem-like identifiers (ASCII and letter-like), and prose inside nested "
          "block comments not miscounted; a letter-like name round-trips to a row; "
          f"each of the {len(CHECK.MODIFIERS_ON_THEOREM)} modifiers Lean elaborates on a "
          f"theorem driven end to end and the {len(CHECK.MODIFIERS_REJECTED_ON_THEOREM)} "
          "kept only as parser widening asserted to still read the name behind them, both "
          "from the checker's own table; comment markers inside escaped identifiers "
          "(`/-`, `-/`, `--`, `\"`, `/--`) kept as name text, a balancing pair of them "
          "not allowed to blank the declarations in between, a stray `«` and a `«` "
          "inside a real comment not allowed to swallow code, and an escaped name "
          "carrying `/-` round-trips to a row; a row re-rendered in each of 6 "
          "whitespace layouts still read, with a repeat and a Lean-absent row in "
          "each rejected rather than slipping past the parser on padding; "
          "same-leaf theorems in sibling namespaces demanded as distinct "
          "qualified names, qualified and sectioned names round-tripping to rows "
          "(including named namespaces and named sections closed with a bare `end`), "
          "and mis-nested, dangling and stray scope commands rejected; each "
          "REGISTERED row bound to the registry field and the plane it prints, "
          "with the registrations exchanged, the plane labels exchanged, both "
          "exchanged, two rows filed under one field, and a registration naming "
          "no field all rejected, driven from the checker's own plane table; "
          f"each registered row widened to each of the {len(supersets) // len(registered_rows)} "
          "plane column(s) its own label is spelled inside, and the composite row "
          "promoted to each field in turn, rejected while the composite column "
          "stays printable by an unregistered row; "
          f"every one of {len(marker_rows)} rows printed with each of "
          f"{len(lookalikes)} Registered-column lookalikes — case variants of both "
          "markers, a bare `REGISTERED`, a negated and a hyphenated spelling, a trailing "
          "stop, and a lower- or mixed-cased registration naming each plane — rejected "
          "rather than skipped as an unrecognized cell, so the two markers are matched "
          "case-sensitively as the whole cell and a lookalike cannot promote a theorem "
          "the registry does not record; and every one of "
          f"{len(inventory_rows)} rows relocated out of the `## Theorems` section "
          "and copied outside it, a second inventory filed further down, and the "
          "section heading renamed, demoted and unheaded all rejected; and every "
          f"one of those rows hidden in each of {len(non_rendered)} constructs "
          "Markdown does not render as a row (backtick, info-string, tilde, "
          "indented, over-long and over-closed fences, space- and tab-indented "
          "code, and all seven HTML block conditions: raw-text elements, "
          "processing instructions, declarations, CDATA, inline, block and "
          "reopened comments, named blocks plain, attributed, uppercased, "
          "indented and closing-tag-first, and a bare tag after a blank line) "
          f"rejected, with each of the {len(block_names)} named-block spellings "
          "the checker's own list carries driven once, an unterminated comment "
          "and an unclosed raw-text "
          "element each hiding the rows below them, a heading quoted in a fence "
          "or an HTML block not allowed to relocate the section, a row quoted in "
          "either outside it not counted as a stray claim, and 16 look-alike "
          "openers — 13 above the section and 3 directly above the first row, "
          "where a block would blank the whole inventory — asserted to leave the "
          "real table rendered while a complete tag alone on its line, which is "
          "HTML block condition 7 and does end a table body, is rejected as the "
          "eight rows it takes out of the inventory; every row hidden mid-table "
          "asserted to take the rows below it out of the rendered table too; and "
          "the one delimiter row that makes the header and its rows a table "
          "deleted, blanked to pipes and spaces, narrowed, widened, and indented "
          "into a four-column chunk all rejected, with alignment colons and up to "
          "three columns of indentation on the delimiter, the header and a row all "
          "still read as the table they render; and the escaped pipe that delimits no "
          "cell driven through every header cell in three spellings under a "
          "delimiter widened to match its characters — the shape that rendered "
          "no table at all while the gate reported eight theorems — rejected, "
          "with the same header at its own true width still read when the escape "
          "is in the free-text column and rejected when it rewords a bound column "
          "label, a legitimate escaped pipe inside a role cell still read as the "
          "five-cell row it renders, and an escape that removes a real cell "
          "boundary rejected as the four-cell row it renders")


if __name__ == "__main__":
    main()
