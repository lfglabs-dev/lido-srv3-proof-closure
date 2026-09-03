#!/usr/bin/env python3
"""Optimized fail-closed mutants for the v4 assurance contract."""

import copy
import hashlib
import importlib.util
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def invoke(root, ok, needle=None, command="generate"):
    result = subprocess.run(
        ["python3", "scripts/audit_metadata.py", command], cwd=root,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    if (result.returncode == 0) != ok:
        raise AssertionError(f"unexpected rc={result.returncode}:\n{result.stdout}")
    if needle and needle not in result.stdout:
        raise AssertionError(f"missing {needle!r}:\n{result.stdout}")


def main():
    with tempfile.TemporaryDirectory(prefix="assurance-v4-mutants-") as tmp:
        fixture = Path(tmp)
        (fixture / "scripts").mkdir()
        (fixture / "audit").mkdir()
        (fixture / "verity/targets").mkdir(parents=True)
        (fixture / "LidoSRv3/Audit/Provenance").mkdir(parents=True)
        (fixture / "fixtures/solidity-reference").mkdir(parents=True)
        shutil.copy2(ROOT / "scripts/audit_metadata.py", fixture / "scripts/audit_metadata.py")
        # The generator reads the published table through the shared cmark-gfm
        # table reader, so the fixture tree must carry it or every mutant would
        # fail on an import error rather than on the claim it is testing.
        shutil.copy2(ROOT / "scripts/gfm_table.py", fixture / "scripts/gfm_table.py")
        # And it reduces the headline blockquote to the text a reader is shown
        # through the shared link-metadata reducer, for the same reason.
        shutil.copy2(ROOT / "scripts/markdown_text.py", fixture / "scripts/markdown_text.py")
        shutil.copy2(ROOT / "README.md", fixture / "README.md")
        shutil.copy2(ROOT / "fixtures/solidity-reference/StakingRouter.constructor.L88-L106.sol",
                     fixture / "fixtures/solidity-reference/StakingRouter.constructor.L88-L106.sol")
        shutil.copy2(ROOT / "LidoSRv3/Audit/Provenance/Deposit.lean",
                     fixture / "LidoSRv3/Audit/Provenance/Deposit.lean")
        for name in (
            "guarantees.yaml", "assumptions.yaml", "artifacts.lock.json",
            "source-map.yaml", "trust-native-decide-allowlist.txt",
        ):
            shutil.copy2(ROOT / "audit" / name, fixture / "audit" / name)
        shutil.copy2(ROOT / "verity/targets/audit-manifest.json", fixture / "verity/targets/audit-manifest.json")

        # Give the isolated generator an immutable review-basis object.  The
        # production script names the real R1 commit; this fixture substitutes
        # its own baseline solely so its negative mutations can exercise the
        # same Git-object binding.
        subprocess.run(["git", "init", "--quiet"], cwd=fixture, check=True)
        subprocess.run(["git", "config", "user.email", "audit-test@example.invalid"], cwd=fixture, check=True)
        subprocess.run(["git", "config", "user.name", "audit metadata test"], cwd=fixture, check=True)
        subprocess.run(["git", "add", "."], cwd=fixture, check=True)
        subprocess.run(["git", "commit", "--quiet", "-m", "R1 review basis"], cwd=fixture, check=True)
        fixture_review_base = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=fixture, check=True,
            text=True, stdout=subprocess.PIPE,
        ).stdout.strip()
        audit_script = fixture / "scripts/audit_metadata.py"
        audit_source = audit_script.read_text(encoding="utf-8")
        audit_source, substitutions = re.subn(
            r'R1_REVIEW_BASE = "[0-9a-f]{40}"',
            f'R1_REVIEW_BASE = "{fixture_review_base}"',
            audit_source,
            count=1,
        )
        if substitutions != 1:
            raise AssertionError("fixture could not substitute the R1 review basis")
        audit_script.write_text(audit_source, encoding="utf-8")

        gpath = fixture / "audit/guarantees.yaml"
        apath = fixture / "audit/assumptions.yaml"
        lpath = fixture / "audit/artifacts.lock.json"
        spath = fixture / "audit/source-map.yaml"
        tpath = fixture / "audit/trust-native-decide-allowlist.txt"
        mpath = fixture / "verity/targets/audit-manifest.json"
        guarantees = json.loads(gpath.read_text())
        assumptions = json.loads(apath.read_text())
        lock = json.loads(lpath.read_text())
        source = json.loads(spath.read_text())
        manifest = json.loads(mpath.read_text())

        invoke(fixture, True)
        invoke(fixture, True, command="check")

        # Metadata is untrusted Markdown-table content: a pipe in every
        # family of metadata-derived report cells must remain literal data,
        # including adjacent pipes that would add columns.
        spec = importlib.util.spec_from_file_location("fixture_audit_metadata", audit_script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        def set_id(row): row["id"] = "left||right"
        def set_abstract_status(row): row["abstract"]["status"] = "left||right"
        def set_verity_status(row): row["verity"]["status"] = "left||right"
        def set_classification(row): row["classification"]["kind"] = "left||right"

        cell_families = (
            set_id, set_abstract_status, set_verity_status, set_classification,
        )
        for mutate in cell_families:
            x = copy.deepcopy(guarantees)
            mutate(x["guarantees"][11])
            report = module.rendered(x["guarantees"], source)["R1-FINAL-AUDITOR-REPORT.md"]
            escaped_row = next(line for line in report.splitlines() if "left\\|\\|right" in line)
            if len(re.findall(r"(?<!\\)\|", escaped_row)) != 6:
                raise AssertionError(f"metadata pipe escaped into table structure:\n{escaped_row}")

        # Assumptions, limitations, source and next gate no longer live in table
        # cells: the acceptance record expands them per claim.  Each must reach
        # the reader verbatim, outside any table row, so nothing that qualifies a
        # claim can be truncated or hidden by the index table.
        def set_abstract_theorem(row): row["abstract"]["theorem"] = "left||right"
        def set_verity_theorem(row): row["verity"]["theorem"] = "left||right"
        def set_summary(row): row["summary"] = "left||right"
        def set_assumptions(row): row["assumptions"] = ["left||right"]
        def set_missing(row): row["fidelity"]["missing"] = ["left||right"]
        def set_next_gate(row): row["next_gate"] = "left||right"

        for mutate in (set_abstract_theorem, set_verity_theorem, set_summary,
                       set_assumptions, set_missing, set_next_gate):
            x = copy.deepcopy(guarantees)
            mutate(x["guarantees"][11])
            report = module.rendered(x["guarantees"], source)["R1-FINAL-AUDITOR-REPORT.md"]
            carriers = [line for line in report.splitlines() if "left||right" in line]
            if not carriers:
                raise AssertionError("qualifying metadata never reached the expanded report")
            for line in carriers:
                if line.lstrip().startswith("|"):
                    raise AssertionError(f"qualifying metadata folded back into a table cell:\n{line}")

        # The review-basis language is only valid for the complete structured
        # report-input family committed at that basis.  These are otherwise-
        # valid edits, including a simultaneous ordinary update of both
        # families: regeneration must not silently retain the stale basis.
        x = copy.deepcopy(guarantees)
        x["guarantees"][11]["summary"] += " changed"
        write(gpath, x)
        invoke(fixture, False, "R1 review basis input family differs for audit/guarantees.yaml")
        write(gpath, guarantees)
        x = copy.deepcopy(source)
        x["targets"][0]["spans"][0]["function"] += " changed"
        write(spath, x)
        invoke(fixture, False, "R1 review basis input family differs for audit/source-map.yaml")
        write(spath, source)
        changed_guarantees = copy.deepcopy(guarantees)
        changed_guarantees["guarantees"][11]["summary"] += " synchronized family change"
        changed_source = copy.deepcopy(source)
        changed_source["targets"][0]["spans"][0]["function"] += " synchronized family change"
        write(gpath, changed_guarantees)
        write(spath, changed_source)
        invoke(fixture, False, "R1 review basis input family differs for audit/guarantees.yaml")
        write(gpath, guarantees)
        write(spath, source)
        # The Trust allowlist is a rendered-report input: it decides the exact
        # accepted-axiom section.  This mutation is otherwise entirely valid
        # (unique, test-scoped, correctly native-decision shaped), so only the
        # basis binding can reject it -- and it must reject `check` too, not
        # just `generate`, or a widened allowlist would still certify as R1.
        trust_allowlist = tpath.read_text(encoding="utf-8")
        widened = trust_allowlist + (
            "LidoSRv3.Tests.Injected.review_basis_widening"
            "._native.native_decide.ax_1_1\n"
        )
        tpath.write_text(widened, encoding="utf-8")
        invoke(fixture, False, "R1 review basis input family differs for audit/trust-native-decide-allowlist.txt")
        invoke(fixture, False, "R1 review basis input family differs for audit/trust-native-decide-allowlist.txt",
               command="check")
        tpath.write_text(trust_allowlist, encoding="utf-8")

        # A disclosure that is not a native-decision axiom must never reach the
        # report's exact accepted-axiom section, whatever the review basis says.
        tpath.write_text(trust_allowlist + "LidoSRv3.Tests.Injected.injected\n", encoding="utf-8")
        invoke(fixture, False, "Trust native-decision allowlist documents a non-native axiom")
        tpath.write_text(trust_allowlist, encoding="utf-8")

        constructor_fixture = fixture / "fixtures/solidity-reference/StakingRouter.constructor.L88-L106.sol"
        constructor_source = constructor_fixture.read_text(encoding="utf-8")
        constructor_fixture.write_text(constructor_source.replace("_maxEBType1);", "_maxEBType2);", 1), encoding="utf-8")
        invoke(fixture, False, "constructor fixture hash differs")
        constructor_fixture.write_text(constructor_source, encoding="utf-8")

        # Regression: changing both the vendored slice and its local digest used
        # to pass.  The independently fetched pinned Git blob must still reject it.
        mutated_constructor = constructor_source.replace("_maxEBType1);", "_maxEBType2);", 1)
        constructor_fixture.write_text(mutated_constructor, encoding="utf-8")
        audit_source = audit_script.read_text(encoding="utf-8")
        audit_script.write_text(
            audit_source.replace(
                hashlib.sha256(constructor_source.encode()).hexdigest(),
                hashlib.sha256(mutated_constructor.encode()).hexdigest(),
                1,
            ),
            encoding="utf-8",
        )
        invoke(fixture, False, "fixture differs from pinned upstream Git blob")
        constructor_fixture.write_text(constructor_source, encoding="utf-8")
        audit_script.write_text(audit_source, encoding="utf-8")

        deposit_lean = fixture / "LidoSRv3/Audit/Provenance/Deposit.lean"
        deposit_lean_source = deposit_lean.read_text(encoding="utf-8")
        deposit_lean.write_text(
            deposit_lean_source.replace("inputs.maxEBType1 ≠ 0", "inputs.maxEBType1 = 0", 1),
            encoding="utf-8",
        )
        invoke(fixture, False, "constructor Lean predicate differs")
        deposit_lean.write_text(deposit_lean_source, encoding="utf-8")

        deposit_lean.write_text(
            deposit_lean_source.replace(
                "inputs.maxEBType1 ≠ 0",
                "inputs.maxEBType1 ≠ 0 ∧ inputs.depositContract = 0xDEAD",
                1,
            ),
            encoding="utf-8",
        )
        invoke(fixture, False, "constructor Lean predicate differs")
        deposit_lean.write_text(deposit_lean_source, encoding="utf-8")

        deposit = next(target for target in source["targets"] if target["id"] == "P-DEPOSIT-1")
        constructor_span = next(span for span in deposit["spans"] if span["function"] == "constructor")
        deposit["spans"].remove(constructor_span)
        write(spath, source)
        invoke(fixture, False, "pinned constructor source span is missing")
        deposit["spans"].insert(0, constructor_span)
        write(spath, source)

        mutants = []
        x = copy.deepcopy(guarantees); x["schema"] = "legacy-seven-planes"; mutants.append((gpath, x, "guarantee schema differs"))
        x = copy.deepcopy(guarantees); x["objective"] += " Prove EVM."; mutants.append((gpath, x, "project objective differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][0], x["guarantees"][1] = x["guarantees"][1], x["guarantees"][0]; mutants.append((gpath, x, "IDs/order differ"))
        x = copy.deepcopy(guarantees); x["guarantees"][0]["abstract"]["theorem"] = None; mutants.append((gpath, x, "checked abstract lacks"))
        x = copy.deepcopy(guarantees); x["guarantees"][2]["verity"] = {"status":"CHECKED", "theorem":"LidoSRv3.Fake.nominal_tx"}; mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][8]["verity"]["theorem"] = "LidoSRv3.Fake.topup2"; mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][7]["verity"]["theorem"] = "LidoSRv3.Fake.address1"; mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees)
        none_row = next(row for row in x["guarantees"] if row["classification"]["kind"] == "NONE")
        none_row["classification"]["consumer"] = "P-ALLOC-1"; mutants.append((gpath, x, "NONE may not hide extra claims"))
        x = copy.deepcopy(guarantees); x["guarantees"][6]["fidelity"]["missing"] = ["unclosed leg"]; x["guarantees"][6]["classification"] = {"kind":"PROPERTY_FALSE"}; mutants.append((gpath, x, "lacks counterexample"))
        x = copy.deepcopy(guarantees); x["guarantees"][6]["verity"] = {"status":"OPEN", "theorem":None}; x["guarantees"][6]["fidelity"]["missing"] = ["recursive dispatch absent"]; x["guarantees"][6]["classification"] = {"kind":"IMPLEMENTATION_PENDING", "work":"compose the ensemble"}; mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][3]["assumptions"].remove("A-TOPUP-NOWRAP"); mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][0]["next_gate"] = "Refine through generated Yul and EVM."; mutants.append((gpath, x, "canonical assurance detail differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][0]["special_bindings"] = guarantees["guarantees"][10]["special_bindings"]; mutants.append((gpath, x, "bindings are SSZ-only"))
        x = copy.deepcopy(guarantees); x["guarantees"][10]["special_bindings"]["deployed_yul"]["scope"] = "entire runtime"; mutants.append((gpath, x, "targeted deployed-Yul binding differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][5]["fidelity"]["missing"] = ["hidden gap"]; x["guarantees"][5]["classification"] = {"kind":"NONE"}; mutants.append((gpath, x, "NONE is reserved"))
        x = copy.deepcopy(guarantees); x["guarantees"][0]["reproduction"]["command"] = ""; mutants.append((gpath, x, "reproduction record is incomplete"))
        x = copy.deepcopy(guarantees); x["guarantees"][8]["summary"] = "Everything is proved."; mutants.append((gpath, x, "canonical assurance detail differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][2]["roadmap_priority"] = "P3"; mutants.append((gpath, x, "roadmap priority differs"))

        for path, value, needle in mutants:
            write(path, value); invoke(fixture, False, needle); write(gpath, guarantees)

        x = copy.deepcopy(assumptions); x["schema"] = "v1"; write(apath, x); invoke(fixture, False, "assumption schema differs"); write(apath, assumptions)
        x = copy.deepcopy(assumptions); del x["assumptions"][0]["removal_path"]; write(apath, x); invoke(fixture, False, "assumption fields differ"); write(apath, assumptions)
        x = copy.deepcopy(assumptions); x["assumptions"][0]["severity"] = "UNKNOWN"; write(apath, x); invoke(fixture, False, "invalid severity"); write(apath, assumptions)
        x = copy.deepcopy(assumptions); x["assumptions"] = [a for a in x["assumptions"] if a["id"] != "A-SHA256-FFI"]; write(apath, x); invoke(fixture, False, "solc/SHA-256 trust boundaries"); write(apath, assumptions)

        x = copy.deepcopy(lock); x["pins"]["verity"]["commit"] = "0" * 40; write(lpath, x); invoke(fixture, False, "verity pin differs"); write(lpath, lock)
        x = copy.deepcopy(lock); x["pins"]["lean"]["toolchain"] = "latest"; write(lpath, x); invoke(fixture, False, "Lean toolchain pin differs"); write(lpath, lock)
        x = copy.deepcopy(lock); x["unavailable"]["canonical_eip7251_runtime"] = {"status":"MISSING", "blocked":True, "value":None}; write(lpath, x); invoke(fixture, False, "retired deployment-provenance blockers"); write(lpath, lock)
        x = copy.deepcopy(manifest); x["proof_policy"]["sorry"] = 1; write(mpath, x); invoke(fixture, False, "proof policy permits proof escapes"); write(mpath, manifest)
        x = copy.deepcopy(manifest); x["source_revisions"]["lido"] = "0" * 40; write(mpath, x); invoke(fixture, False, "manifest source revisions differ"); write(mpath, manifest)
        x = copy.deepcopy(source); x["pinned_source"] = "lidofinance/core@main"; write(spath, x); invoke(fixture, False, "source-map pin differs"); write(spath, source)
        x = copy.deepcopy(source); x["scope"]["general_yul_evm_deployment"] = "OPEN"; write(spath, x); invoke(fixture, False, "source-map assurance scope differs"); write(spath, source)
        x = copy.deepcopy(source); x["ssz_claim"]["deployed_yul_binding"] = "FULL_RUNTIME"; write(spath, x); invoke(fixture, False, "source-map SSZ boundary differs"); write(spath, source)
        x = copy.deepcopy(source); x["targets"][0]["spans"][0]["permalink"] = "https://github.com/lidofinance/core/blob/main/x"; write(spath, x); invoke(fixture, False, "permalink is not immutable/exact"); write(spath, source)
        x = copy.deepcopy(source); x["targets"][0]["spans"][0]["source_sha"] = "0" * 40; write(spath, x); invoke(fixture, False, "source span pin differs"); write(spath, source)

        # The README headline table is a published claim surface: every canonical
        # row reads CHECKED/CHECKED, so the per-row gap count is the only thing
        # keeping it from reading as finished.  Mutate each way it can be silenced.
        readme_path = fixture / "README.md"
        readme = readme_path.read_text(encoding="utf-8")
        for mutated, needle in (
            (readme.replace("| 1 | `P-ALLOC-1` | CHECKED | CHECKED | 3 open |",
                            "| 1 | `P-ALLOC-1` | CHECKED | CHECKED | 0 open |"),
             "P-ALLOC-1 discloses 0 fidelity gaps"),
            (readme.replace("| 1 | `P-ALLOC-1` | CHECKED | CHECKED | 3 open |",
                            "| 1 | `P-ALLOC-1` | CHECKED | CHECKED |"),
             "P-ALLOC-1 row is missing its `N open` fidelity-gap cell"),
            (readme.replace("67 in total", "some in total"),
             "must render the 67 total fidelity gaps as visible text"),
            (readme.replace("not about a deployed contract", "about a deployed contract"),
             "must render the model-vs-deployed boundary as visible text"),
        ):
            if mutated == readme:
                raise AssertionError(f"README mutant for {needle!r} changed nothing")
            readme_path.write_text(mutated, encoding="utf-8")
            invoke(fixture, False, needle)

        # A duplicate row is a second published claim, not a harmless echo.  Drive
        # this from every row the table actually prints so a guarantee added later
        # arrives with its case already demanded, and cover both orderings plus a
        # copy filed under another index, which no per-ID position pattern matches.
        rows = re.findall(r"^\| *\d+ *\| *`[^`]+` *\|[^\n|]*\|[^\n|]*\| *\d+ open *\|$",
                          readme, flags=re.MULTILINE)
        if not rows:
            raise AssertionError("no canonical README fidelity rows found to duplicate")
        for row in rows:
            contradictory = re.sub(r"\d+ open", "0 open", row)
            reindexed = re.sub(r"^\| *\d+", "| 99", contradictory)
            for duplicated in (f"{row}\n{contradictory}",
                               f"{contradictory}\n{row}",
                               f"{row}\n{reindexed}",
                               f"{row}\n{row}"):
                readme_path.write_text(readme.replace(row, duplicated, 1), encoding="utf-8")
                invoke(fixture, False, "headline fidelity rows")
        readme_path.write_text(readme, encoding="utf-8")

        # The disclosure is a claim about one table.  Reading gap rows from
        # anywhere in the README bound them to nothing in particular, so a row
        # re-filed into a later table or into loose prose went on satisfying this
        # gate while the table a reader meets had silently dropped it — the
        # headline could skip an ID outright.  Every row the table prints is
        # driven through both relocations and through outright deletion, so a
        # guarantee added later arrives with its case already demanded.
        header = "| # | ID | Abstract Lean | Verity Executable Contract | Fidelity gaps |"
        if readme.count(header) != 1:
            raise AssertionError("expected exactly one headline table header in README")
        appendix = ("\n## Appendix\n\n"
                    "| Row | Claim | Abstract | Verity | Gaps |\n"
                    "| --- | --- | --- | --- | --- |\n")
        for row in rows:
            claim_id = re.search(r"`([^`]+)`", row).group(1)
            outside = f"README: {claim_id} print(s) a fidelity-gap row outside the headline"
            without = readme.replace(f"{row}\n", "", 1)
            if row in without:
                raise AssertionError(f"relocation mutant for {claim_id} changed nothing")

            # Re-filed into a second table that does not claim the headline's
            # own columns, so nothing but reading the headline table can see it.
            readme_path.write_text(f"{without}{appendix}{row}\n", encoding="utf-8")
            invoke(fixture, False, outside)

            # Re-filed into loose prose, which is not a table at all.
            readme_path.write_text(f"{without}\n{row}\n", encoding="utf-8")
            invoke(fixture, False, outside)

            # Dropped from the headline table without being re-filed anywhere:
            # the row set the table prints is itself part of the disclosure.
            readme_path.write_text(without, encoding="utf-8")
            invoke(fixture, False, f"README: {claim_id} row is missing its `N open`")
            readme_path.write_text(readme, encoding="utf-8")

        # A row the registry does not record as canonical, printed inside the
        # headline table: the table must disclose the canonical claims and no
        # more, or it publishes a gap count that stands behind nothing.
        foreign = "| 99 | `P-NOT-CANONICAL-1` | CHECKED | CHECKED | 4 open |"
        readme_path.write_text(readme.replace(rows[-1], f"{rows[-1]}\n{foreign}", 1),
                               encoding="utf-8")
        invoke(fixture, False, "prints a fidelity-gap row for P-NOT-CANONICAL-1")

        # A second table claiming the headline's own columns competes with the
        # disclosure: whichever one this gate read, the other published
        # unchecked counts to a reader who meets both.
        second = (f"\n## Appendix\n\n{header}\n| --- | --- | --- | --- | --- |\n"
                  f"{rows[0]}\n")
        readme_path.write_text(readme + second, encoding="utf-8")
        invoke(fixture, False, "found 2 headline fidelity tables, expected exactly one")

        # And the table has to be locatable at all: repainting the column the
        # counts live in leaves the disclosure with no table to bind to.
        readme_path.write_text(
            readme.replace("| Fidelity gaps |\n", "| Gaps |\n", 1), encoding="utf-8")
        invoke(fixture, False, "found 0 headline fidelity tables, expected exactly one")
        readme_path.write_text(readme, encoding="utf-8")

        # The table has to be rendered, not merely present in raw source.
        # Wrapping it in an HTML comment preserves every raw pipe character but
        # removes the table from the rendered page; a raw-text search would
        # still find all eleven rows while a reader sees nothing.  The gate
        # must search the rendered text and reject a table that lives only
        # inside a comment.
        table_header_pos = readme.index(header)
        # The table runs to the first blank line after the header.
        table_end = readme.index("\n\n", table_header_pos)
        raw_table = readme[table_header_pos:table_end]
        commented = readme.replace(raw_table, f"<!--\n{raw_table}\n-->", 1)
        readme_path.write_text(commented, encoding="utf-8")
        invoke(fixture, False, "found 0 headline fidelity tables, expected exactly one")
        readme_path.write_text(readme, encoding="utf-8")

        # A CommonMark type-6 HTML block (a block-level element like <div>)
        # eats every line until the next blank line as raw HTML.  The table
        # rows become HTML block content rather than Markdown rows, so they
        # never render as a table — the gate must detect this and reject it.
        divd = readme.replace(raw_table, f"<div>\n{raw_table}\n</div>", 1)
        readme_path.write_text(divd, encoding="utf-8")
        invoke(fixture, False, "found 0 headline fidelity tables, expected exactly one")
        readme_path.write_text(readme, encoding="utf-8")

        # The boundary sentence and the total gap count are headline claims:
        # they qualify the CHECKED table before a reader reaches it, which is
        # the only reason they are stated up front.  Searching the whole README
        # for them bound them to nothing in particular, so either one could be
        # relocated below the table — into an appendix, into loose prose, into a
        # second blockquote — and go on satisfying this gate while the headline
        # a reader meets no longer carried the qualification at all.
        opening = module.README_HEADLINE_BLOCK.match(readme)
        if not opening:
            raise AssertionError("canonical README has no headline blockquote to scope to")
        block = opening.group("block")
        title = readme.split("\n", 1)[0]
        for sentence, muted, needle in (
            ("67 in total", "counted below",
             "headline blockquote must render the 67 total fidelity gaps as visible text"),
            ("not about a deployed contract", "about a Lean model",
             "headline blockquote must render the model-vs-deployed boundary as "
             "visible text"),
        ):
            if readme.count(sentence) != 1 or block.count(sentence) != 1:
                raise AssertionError(f"expected {sentence!r} once, inside the headline block")
            muted_block = block.replace(sentence, muted, 1)
            quieted = readme.replace(block, muted_block, 1)
            if quieted == readme:
                raise AssertionError(f"headline mutant for {sentence!r} changed nothing")

            # Still published, just no longer where it qualifies anything.
            for relocated in (
                f"{quieted}\n## Appendix\n\nThe evidence is {sentence}.\n",
                quieted.replace(header, f"The evidence is {sentence}.\n\n{header}", 1),
                f"{quieted}\n> The evidence is {sentence}.\n",
            ):
                if relocated == quieted:
                    raise AssertionError(f"relocation mutant for {sentence!r} changed nothing")
                readme_path.write_text(relocated, encoding="utf-8")
                invoke(fixture, False, needle)

            # Or spelled inside the block and published by none of it.  The
            # block's contents were searched as raw Markdown, so a qualification
            # whose characters render as no visible text satisfied the search
            # while the headline a reader meets carried nothing: an HTML comment
            # was enough, and every other construct below prints just as little.
            # Each is driven for both sentences, since one the suite never
            # exercises is one that can carry a qualification the day it is used.
            for concealed in (
                f"> <!-- The evidence is {sentence}. -->\n",
                f"> <!-- a note\n> continued: {sentence}\n> -->\n",
                f"> <?php echo 'The evidence is {sentence}.'; ?>\n",
                f"> <![CDATA[The evidence is {sentence}.]]>\n",
                f"> <!DOCTYPE note SYSTEM {sentence}>\n",
                # Thread r3909473219: a tag is not an element.  Naming three
                # of them as `<(script|style|textarea)\b.*?</\1>` removed the
                # bodies it knew about and stopped at the first end tag, so
                # `<template>` published a qualification to no reader while
                # this gate read it as prose, and a `template` nested in
                # another carried one past the close that pattern stopped at.
                # Every element the shared reader holds to be non-rendered is
                # driven here, so one it never exercises cannot carry a
                # qualification the day it is used.
                *(f"> <{element}>{sentence}</{element}>\n"
                  for element in module.markdown_text.NON_RENDERED_ELEMENTS),
                f"> <script type=\"text/javascript\">var n = '{sentence}';</script>\n",
                f"> <STYLE>/* {sentence} */</STYLE>\n",
                f"> <template><template>note</template>{sentence}</template>\n",
                f'> <span title="{sentence}">See the note.</span>\n',
                f'> <img alt="{sentence}" src="x.png">\n',
                # Thread 14: a Markdown link reference definition renders as
                # nothing; its title is invisible to a reader but present in
                # the raw source a naïve regex would search.
                f'> [note]: http://example.com "{sentence}"\n',
                # Thread r3901367508: an inline link's destination and title
                # are invisible; only the display text renders, so a
                # qualification hidden in the title must not satisfy the check.
                f'> [see here](http://example.com "{sentence}")\n',
                # Thread r3909071230: a CommonMark destination may carry
                # balanced parentheses.  A pattern that stopped at the first
                # `)` consumed `foo(bar` and left the title standing as
                # ordinary text, so a headline rendering only the word
                # "details" satisfied the check for both qualifications.
                f'> [details](foo(bar) "{sentence}")\n',
                f'> [details](foo(bar(baz)) "{sentence}")\n',
                f"> [details](foo(bar) '{sentence}')\n",
                f'> [details](foo(bar) ({sentence}))\n',
                f'> [details](<foo(bar> "{sentence}")\n',
                f'> [outer [inner](u "{sentence}") label](v)\n',
            ):
                readme_path.write_text(
                    readme.replace(block, muted_block + concealed, 1), encoding="utf-8")
                invoke(fixture, False, needle)

            # Thread r3909320734: a full or collapsed reference link names its
            # definition in a second bracket group, which renders as nothing.
            # Recognising only the `(` form left the whole sentence standing in
            # `[details][not about a deployed contract; 67 in total]` as if a
            # reader met it.  The definition is appended so the link really does
            # form and CommonMark really does render only "details".
            readme_path.write_text(
                readme.replace(block, muted_block + f"> [details][{sentence}]\n", 1)
                .rstrip("\n") + f'\n\n[{sentence}]: http://example.com\n',
                encoding="utf-8")
            invoke(fixture, False, needle)

            # A collapsed reference link renders its own label, so the same
            # sentence written as `[sentence][]` is text a reader is shown and
            # must still be accepted.
            readme_path.write_text(
                readme.replace(block, muted_block + f"> [{sentence}][]\n", 1)
                .rstrip("\n") + f'\n\n[{sentence}]: http://example.com\n',
                encoding="utf-8")
            invoke(fixture, True, command="check")

            # The mirror of that family: a qualification carried in the link
            # *label* is text a reader is shown, so removing the metadata must
            # not remove it too.  Otherwise the gate would reject a headline a
            # reader plainly meets and no edit to the README could satisfy it.
            for shown in (
                f'> [The evidence is {sentence}.](http://example.com)\n',
                f'> [The evidence is {sentence}.](foo(bar) "hidden")\n',
                f'> [The evidence is {sentence}.][note]\n\n[note]: http://example.com\n',
                f'> The evidence is {sentence}. [see](foo(bar) "hidden")\n',
                f'> The evidence is {sentence}. [unterminated](foo "x\n',
                # The same edge for element bodies.  Reading that rule one
                # construct too widely would delete text a reader plainly
                # meets: prose beside a non-rendered element, an element whose
                # name only looks like one, one a browser does paint, and the
                # text after a raw-text element's first end tag are all on the
                # page and must still qualify the table.
                f"> <script>note</script> The evidence is {sentence}.\n",
                f"> The evidence is {sentence}. <script>note</script>\n",
                f"> <script>a</script> The evidence is {sentence}. <style>b</style>\n",
                f"> <scriptx>The evidence is {sentence}.</scriptx>\n",
                f"> <script-note>The evidence is {sentence}.</script-note>\n",
                f"> <xmp>The evidence is {sentence}.</xmp>\n",
            ):
                readme_path.write_text(
                    readme.replace(block, muted_block + shown, 1), encoding="utf-8")
                invoke(fixture, True, command="check")

            # And dropped from the README outright.
            readme_path.write_text(quieted, encoding="utf-8")
            invoke(fixture, False, needle)
            readme_path.write_text(readme, encoding="utf-8")

        # The block has to be locatable at all, and it is located by its
        # position: the blockquote directly under the title.  Demote it to
        # ordinary prose, push it below an introduction, or unhead it, and the
        # qualifications no longer lead the document even though every sentence
        # is still spelled in it.
        for displaced in (
            readme.replace(block, re.sub(r"^> ?", "", block, flags=re.MULTILINE), 1),
            readme.replace(block, f"Introductory prose.\n\n{block}", 1),
            readme.replace(block, "", 1),
            readme.replace(f"{title}\n\n", "", 1),
            readme.replace(f"{title}\n", f"#{title}\n", 1),
        ):
            if displaced == readme:
                raise AssertionError("headline-block displacement mutant changed nothing")
            readme_path.write_text(displaced, encoding="utf-8")
            invoke(fixture, False, "no headline blockquote under the title")
            readme_path.write_text(readme, encoding="utf-8")

        # Scoping must not make the README unwritable: the title is not the
        # claim, the block may grow, and repeating a qualification further down
        # is redundant rather than wrong.
        for still_qualified in (
            readme.replace(title, "# Renamed Heading", 1),
            readme.replace(block, f"{block}> - An extra headline note.\n", 1),
            f"{readme}\n## Appendix\n\nRestated: these are proofs "
            "not about a deployed contract, with 67 in total.\n",
        ):
            if still_qualified == readme:
                raise AssertionError("headline-block control changed nothing")
            readme_path.write_text(still_qualified, encoding="utf-8")
            invoke(fixture, True)
            readme_path.write_text(readme, encoding="utf-8")

        # Removing what does not render must not take visible text with it, or
        # the gate would reject a headline a reader plainly meets and no edit to
        # the README could satisfy it.  Each sentence is muted in place and
        # restated in a form whose rendered characters still spell it exactly.
        for sentence, muted in (("67 in total", "counted below"),
                                ("not about a deployed contract", "about a Lean model")):
            muted_block = block.replace(sentence, muted, 1)
            for restated in (
                f"> The evidence is <b>{sentence}</b>.\n",
                f'> <span class="note">The evidence is {sentence}.</span>\n',
                f"> The evidence is {sentence.replace(' ', '<b> </b>', 1)}.\n",
                f"> The evidence is {sentence}. <!-- and nowhere else -->\n",
            ):
                readme_path.write_text(
                    readme.replace(block, muted_block + restated, 1), encoding="utf-8")
                invoke(fixture, True)
                readme_path.write_text(readme, encoding="utf-8")

        # The headline is a table only because one delimiter row underlines it.
        # Blank its cells or make it disagree with the header's width and
        # Markdown renders the CHECKED cells and the gap counts that qualify
        # them as a run of paragraph text instead.
        delimiter = "| --- | --- | --- | --- | --- |"
        for mutant in (
            "",
            "|     |     |     |     |     |",
            "| --- | --- |",
            "| --- | --- | --- | --- | --- | --- |",
            "    | --- | --- | --- | --- | --- |",
        ):
            body = readme.replace(f"{delimiter}\n", f"{mutant}\n" if mutant else "", 1)
            readme_path.write_text(body, encoding="utf-8")
            invoke(fixture, False, "found 0 headline fidelity tables", command="check")
            readme_path.write_text(readme, encoding="utf-8")

        # Up to three columns of indentation is ordinary block markup, and the
        # fourth is what makes an indented chunk: the delimiter, the header and a
        # row are each indented in turn and the headline must still be located,
        # or the gate would reject a table cmark-gfm plainly renders.
        for indented in (readme.replace(delimiter, f"  {delimiter}", 1),
                         readme.replace(header, f"   {header}", 1),
                         readme.replace(rows[0], f" {rows[0]}", 1)):
            if indented == readme:
                raise AssertionError("short-indent control changed nothing")
            readme_path.write_text(indented, encoding="utf-8")
            invoke(fixture, True, command="check")
            readme_path.write_text(readme, encoding="utf-8")

        # Adversarial (certified defect 2 family): an escaped pipe is a `|`
        # character that delimits no cell.  Writing one into the header narrows
        # the header by a column while leaving the character count unchanged, so
        # a delimiter row widened to match the *characters* balanced the old
        # count-the-pipes check exactly — and cmark-gfm, reading a five-cell
        # header under a six-cell delimiter, rendered no table on the page while
        # every gap count below was checked against it.  Each cell of the header
        # is driven, and each is also driven at the header's true width, where
        # the table does render and must still be read.
        wide = "| --- | --- | --- | --- | --- | --- |"
        cells = header.strip("|").split("|")
        if len(cells) != 5:
            raise AssertionError(f"expected a 5-cell headline header, read {cells}")
        for position in range(len(cells)):
            for escape in ("\\|", "\\\\|", "\\\\\\|"):
                mutated = list(cells)
                mutated[position] = f"{mutated[position].rstrip()} {escape} alias "
                spoiled = "|" + "|".join(mutated) + "|"
                readme_path.write_text(
                    readme.replace(header, spoiled, 1).replace(delimiter, wide, 1),
                    encoding="utf-8")
                invoke(fixture, False, "found 0 headline fidelity tables", command="check")
                # The middle two columns are free text; the index, the ID and
                # the gap-count column are what the disclosure is bound to, so
                # rewording one of those retires the table this gate checks.
                readme_path.write_text(readme.replace(header, spoiled, 1), encoding="utf-8")
                free = position in (2, 3)
                invoke(fixture, free, None if free else "found 0 headline fidelity tables",
                       command="check")
                readme_path.write_text(readme, encoding="utf-8")

        # Adversarial (certified defect 4 family): the headline is a position,
        # not just a shape.  A table that renders perfectly but sits under a
        # trailing heading publishes its gap counts after the CHECKED cells they
        # qualify, and the headline a reader meets first carries none of them.
        table_start = readme.index(header)
        table_end = readme.index("\n\n", table_start)
        whole_table = readme[table_start:table_end + 1]
        for relocated in (
            readme.replace(whole_table, "", 1).rstrip("\n") + f"\n\n## Appendix\n\n{whole_table}",
            readme.replace(whole_table, "", 1).replace(
                "## Reproduce", f"## Status\n\n{whole_table}\n## Reproduce", 1),
        ):
            if whole_table in relocated.split("## ")[0]:
                raise AssertionError("headline-table relocation mutant changed nothing")
            readme_path.write_text(relocated, encoding="utf-8")
            invoke(fixture, False, "not in the headline above the first section",
                   command="check")
            readme_path.write_text(readme, encoding="utf-8")

        # Alignment colons belong to a valid delimiter, so the table must still
        # be located through them; otherwise no aligned headline could pass.
        readme_path.write_text(
            readme.replace(delimiter, "| :--- | ---: | :-: | --- | --- |", 1),
            encoding="utf-8")
        invoke(fixture, True, command="check")
        readme_path.write_text(readme, encoding="utf-8")

        invoke(fixture, True, command="generate")
        (fixture / "audit/STATUS.md").write_text("stale\n", encoding="utf-8")
        invoke(fixture, False, "STATUS.md is stale", command="check")

    print("optimized assurance-v4 mutants rejected: objective, canonical claims, "
          "classifications, assumptions, SSZ-only binding, pins, source spans, proof "
          "policy, README fidelity-gap disclosure, duplicate headline rows, and stale "
          f"views; and every one of {len(rows)} headline rows re-filed into a later "
          "table, re-filed into loose prose, and dropped outright, plus a non-canonical "
          "row printed inside the table, a second table claiming the headline's own "
          "columns, the gap column repainted so the table cannot be located, the table "
          "wrapped in an HTML comment, and the table wrapped in a block-level HTML "
          "element (`<div>`); and "
          "each headline qualification re-filed into an appendix, into prose above the "
          "table, into a later blockquote and dropped outright, and spelled inside the "
          "block by each of 20 constructs that publish no visible text (single- and "
          "multi-line comments, a processing instruction, CDATA, a declaration, "
          "the body of every one of the eight elements the shared reader holds "
          "to be non-rendered — with an attributed and an upper-case opener and "
          "a nested `template` whose close the body runs past, since naming "
          "three of them and stopping at the first end tag let `<template>` "
          "publish a qualification to no reader — `title`/`alt` attribute "
          "values, Markdown link reference definition titles, inline link "
          "destination/title fields, and six inline-link shapes whose destination "
          "carries balanced or angle-bracketed parentheses — the form a `[^)]*` "
          "pattern stopped short of, leaving the title standing as ordinary text, "
          "including one hidden in a nested label, and a full reference link whose "
          "second bracket group names a definition that renders as nothing), with a "
          "collapsed reference link still read because it renders its own label, "
          "with the opening blockquote "
          "demoted to prose, pushed below an "
          "introduction, deleted, unheaded and its title demoted all rejected, while a "
          "renamed title, a longer block, a redundant restatement, and each "
          "qualification restated through inline markup that still renders it, and each "
          "carried in a link label or beside an unterminated link, and each "
          "printed on either side of a non-rendered element, beside one of a "
          "different name, inside two whose names only look like one, or inside "
          "the `xmp` a browser paints — text a reader is shown — stay accepted; "
          "and the delimiter row that makes the headline a table deleted, "
          "blanked to pipes and spaces, narrowed, widened, and indented into a "
          "four-column chunk all rejected, with alignment colons and up to three "
          "columns of indentation on the delimiter, the header and a row all still "
          "located as the table they render; the escaped pipe that delimits no cell driven through every "
          "header cell in three spellings under a delimiter widened to match its "
          "characters — the shape that rendered no table on the page while every gap "
          "count below was checked against it — rejected, with the same header at its "
          "own true width still located when the escape is in a free-text column and "
          "rejected when it rewords the index, the ID or the gap-count column; and the "
          "whole table relocated under a trailing appendix and under a later section "
          "rejected, since a gap count a reader reaches only after the CHECKED cells "
          "it was written to qualify no longer qualifies them")


if __name__ == "__main__":
    main()
