#!/usr/bin/env python3
"""Fail-closed mutants for the P-ALLOC-1 report theorem inventory."""

import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKER = "scripts/check_report_theorem_inventory.py"
LEAN = "LidoSRv3/Audit/Guarantees/PAlloc1.lean"
REPORT = "report/P-ALLOC-1.md"
REGISTRY = "audit/guarantees.yaml"


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
        for relative in (CHECKER, LEAN, REPORT, REGISTRY):
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

        # An unterminated block comment leaves the rest of the file unreadable;
        # it must fail closed rather than silently inventorying nothing.
        lean_path.write_text(
            lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                         "/- outer /- nested -/\n"
                         "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
            encoding="utf-8")
        invoke(fixture, False, "unterminated block comment")
        lean_path.write_text(lean, encoding="utf-8")

        # An unregistered theorem promoted to REGISTERED in the report only.
        promoted = report.replace(
            "| `active_capacity_bounded` | 69 | Abstract | unregistered |",
            "| `active_capacity_bounded` | 69 | Abstract | REGISTERED as `abstract.theorem` |", 1)
        if promoted == report:
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

        # A stale line number: the citation must point at the real declaration.
        stale = report.replace("| `checked_execute` | 103 |", "| `checked_execute` | 104 |", 1)
        if stale == report:
            raise AssertionError("line mutant changed nothing")
        report_path.write_text(stale, encoding="utf-8")
        invoke(fixture, False, "checked_execute is declared at Lean line 103")
        report_path.write_text(report, encoding="utf-8")

        # A row that names no abstract/Verity plane.
        planeless = report.replace("| `verity_tx_revert_restores_snapshot` | 184 | Verity |",
                                   "| `verity_tx_revert_restores_snapshot` | 184 | n/a |", 1)
        if planeless == report:
            raise AssertionError("plane mutant changed nothing")
        report_path.write_text(planeless, encoding="utf-8")
        invoke(fixture, False, "no recognized abstract/Verity plane")
        report_path.write_text(report, encoding="utf-8")

        invoke(fixture, True)

    print("report theorem inventory mutants rejected: dropped row, undisclosed theorem "
          "(column-zero, indented, tabbed, attributed, private, protected, nonrec, "
          "`lemma`, and combined), letter-like/subscript/`!`/`?`/escaped/dotted Lean "
          "identifiers, declaration after a nested comment, `/-` in a line "
          "comment and in a string literal, unterminated comment, report-only promotion, "
          "registry drift, stale line, missing plane; commented-out declarations, "
          "theorem-like identifiers (ASCII and letter-like), and prose inside nested "
          "block comments not miscounted; a letter-like name round-trips to a row")


if __name__ == "__main__":
    main()
