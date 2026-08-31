#!/usr/bin/env python3
"""Fail-closed mutants for the architecture-map taxonomy checker."""

import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKER = "scripts/check_diagram_taxonomy.py"
DIAGRAM = "diagram/index.html"
DIAGRAM_README = "diagram/README.md"


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
    with tempfile.TemporaryDirectory(prefix="diagram-taxonomy-mutants-") as tmp:
        fixture = Path(tmp)
        for relative in (CHECKER, DIAGRAM, DIAGRAM_README):
            target = fixture / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)

        diagram_path = fixture / DIAGRAM
        readme_path = fixture / DIAGRAM_README
        diagram = diagram_path.read_text(encoding="utf-8")
        readme = readme_path.read_text(encoding="utf-8")

        invoke(fixture, True, "diagram taxonomy ok")

        # Each mutant is a way the map could quietly go back to the reading the
        # UX1 correction removed.
        for mutated, needle in (
            # A system predeploy repainted as consensus layer: it would read as
            # sitting outside the EL trust boundary.
            (diagram.replace('<div class="c sys"><div class="n">EIP-4788 / 7002 / 7251</div>',
                             '<div class="c cl"><div class="n">EIP-4788 / 7002 / 7251</div>'),
             "is drawn as 'cl', must be 'sys'"),
            (diagram.replace('<g class="node sys" data-flows="f3 f6">',
                             '<g class="node cl" data-flows="f3 f6">'),
             "is drawn as 'cl', must be 'sys'"),
            # An oracle repainted as quorum-held: the committee would appear to
            # live somewhere other than HashConsensus.
            (diagram.replace('<div class="c el"><div class="n">AccountingOracle</div>',
                             '<div class="c com"><div class="n">AccountingOracle</div>'),
             "is drawn as 'com', must be 'el'"),
            # HashConsensus demoted to a plain contract.
            (diagram.replace('<div class="c com"><div class="n">HashConsensus</div>',
                             '<div class="c el"><div class="n">HashConsensus</div>'),
             "is drawn as 'el', must be 'com'"),
            # The consolidation veto handed back to the DSM guardians.
            (diagram.replace("the committee's veto window", "the guardians' veto window"),
             "the consolidation veto is the committee's REMOVE_ROLE"),
            # The quorum restated as a constant.
            (diagram.replace("handleOracleReport", "handleOracleReport · 5/9 quorum"),
             "quorum lives in HashConsensus"),
            # EasyTrack's allow-only power restated as a veto.
            (diagram.replace("the executor is the sole grantee",
                             "vetoable motions; the executor is the sole grantee"),
             "EasyTrack holds ALLOW_PAIR_ROLE only"),
            # The two beacon-proof verifiers conflated again.
            (diagram.replace("CLValidatorVerifier", "CLProofVerifier"),
             "never mentions 'CLValidatorVerifier'"),
            # An on-chain box that no longer says where it comes from.
            (diagram.replace(
                '<g class="node com" data-flows="f4 f5 f7"><title>',
                '<g class="node com" data-flows="f4 f5 f7"><notitle>', 1),
             "carries no hover tooltip"),
        ):
            if mutated == diagram:
                raise AssertionError(f"diagram mutant for {needle!r} changed nothing")
            diagram_path.write_text(mutated, encoding="utf-8")
            invoke(fixture, False, needle)
            diagram_path.write_text(diagram, encoding="utf-8")

        # The README carries the citations; a class it stops documenting is a
        # colour the reader can no longer resolve to a source claim.
        stripped = readme.replace("- `sys` —", "- sys:")
        if stripped == readme:
            raise AssertionError("README class mutant changed nothing")
        readme_path.write_text(stripped, encoding="utf-8")
        invoke(fixture, False, "does not document class 'sys'")
        readme_path.write_text(readme, encoding="utf-8")

        invoke(fixture, True)

    print("diagram taxonomy mutants rejected: predeploy as consensus layer (card and node), "
          "oracle as quorum-held, HashConsensus demoted, guardian veto, 5/9 constant, "
          "EasyTrack veto, conflated verifiers, untooltipped node, undocumented class")


if __name__ == "__main__":
    main()
