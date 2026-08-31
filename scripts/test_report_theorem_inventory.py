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

        # The other direction: widening the parser to cover those variants must
        # not start counting lines that declare nothing.  A commented-out
        # declaration and an identifier that merely begins with the keyword are
        # both still non-declarations.
        for not_a_declaration in (
            "  -- theorem commented_out : True := trivial",
            "  -- lemma commented_out_lemma : True := trivial",
            "def theorem_like_name : Nat := 0",
            "def lemma_like_name : Nat := 0",
        ):
            lean_path.write_text(
                lean.replace("end LidoSRv3.Audit.Guarantees.PAlloc1",
                             f"{not_a_declaration}\n\n"
                             "end LidoSRv3.Audit.Guarantees.PAlloc1", 1),
                encoding="utf-8")
            invoke(fixture, True, "8 P-ALLOC-1 theorems")
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
          "`lemma`, and combined), report-only promotion, registry drift, stale line, "
          "missing plane; commented-out declarations and theorem-like identifiers "
          "not miscounted")


if __name__ == "__main__":
    main()
