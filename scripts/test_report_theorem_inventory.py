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
        # scope but contributes nothing to a name, named or not.
        for opener, closer, qualified in (
            ("namespace Inner", "end Inner", "Inner.scoped_thm"),
            ("namespace Outer.Deep", "end Outer.Deep", "Outer.Deep.scoped_thm"),
            ("section", "end", "scoped_thm"),
            ("section Named", "end Named", "scoped_thm"),
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

        invoke(fixture, True)

    print("report theorem inventory mutants rejected: dropped row, undisclosed theorem "
          "(column-zero, indented, tabbed, attributed, private, protected, nonrec, "
          "`lemma`, and combined), a name wrapped onto the line after its keyword "
          "(bare, `lemma`, blank-line-separated, prefixed, escaped and letter-like) "
          "with the wrapped form cited at its keyword's line, "
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
          "qualified names, qualified and sectioned names round-tripping to rows, "
          "and mis-nested, dangling and stray scope commands rejected")


if __name__ == "__main__":
    main()
