#!/usr/bin/env python3
"""Fail-closed mutants for the architecture-map taxonomy checker."""

import re
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
            # The relabelling bypass.  Reformatting a label used to drop that
            # box's taxonomy entry and its rule with it, so a repaint rode
            # through unnoticed.  The address does not move when the wording
            # does, so the class must still be enforced against it.
            (diagram.replace('<g class="node el" data-flows="f4 f5 f7"><title>0x852deD',
                             '<g class="node com" data-flows="f4 f5 f7"><title>0x852deD', 1)
                    .replace('<text class="nm" x="850" y="160">AccountingOracle</text>',
                             '<text class="nm" x="850" y="160">Accounting Oracle</text>', 1),
             "AccountingOracle (0x852deD011285fe67063a08005c71a85690503Cee) "
             "is drawn as 'com' under the label 'Accounting Oracle', must be 'el'"),
            # The same bypass on the notes card, which carries the abbreviated
            # address rather than the full one.
            (diagram.replace('<div class="c el"><div class="n">AccountingOracle</div>',
                             '<div class="c com"><div class="n">Accounting Oracle</div>', 1),
             "AccountingOracle (0x852deD011285fe67063a08005c71a85690503Cee) is drawn as 'com'"),
            # A renamed predeploy repainted as quorum-held.
            (diagram.replace('<div class="c sys"><div class="n">EIP-4788 / 7002 / 7251</div>',
                             '<div class="c com"><div class="n">Beacon roots and requests</div>', 1),
             "EIP-4788 beacon roots (0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02) "
             "is drawn as 'com'"),
            # A renamed committee demoted to a plain contract.
            (diagram.replace('<div class="c com"><div class="n">HashConsensus</div>',
                             '<div class="c el"><div class="n">Hash Consensus</div>', 1),
             "HashConsensus (0xD624B08C83bAECF0807Dd2c6880C3154a5F0B288) is drawn as 'el'"),
            # The rendered legend restating one compromise consequence for the
            # whole `bot` class.  This is the surface the reader looks at, so a
            # corrected README does not excuse it.
            (diagram.replace("off-chain · cannot redirect principal",
                             "off-chain · liveness only", 1),
             "the `bot` legend pill reads 'liveness only'"),
            (diagram.replace("off-chain · cannot redirect principal",
                             "off-chain · liveness, not funds", 1),
             "the `bot` legend pill reads 'liveness, not funds'"),
            # The pill stripped back to a bare colour swatch: the class-wide
            # reading would return by omission rather than by wording.
            (re.sub(r'<span class="bot"[^>]*>', '<span class="bot">', diagram, count=1),
             "the `bot` legend pill never mentions 'Node operators'"),
            # The qualification must survive on the map as a claim and not just
            # as a name: the slashable consequence is the part that breaks the
            # liveness-only reading of the node operators' signing keys.
            (diagram.replace("can sign slashable messages", "can be rotated"),
             "the `bot` legend pill never mentions 'slashable'"),
            # A taxonomy-critical entity that leaves the map entirely: its rule
            # must not retire quietly along with it.
            (diagram.replace("0xD624B08C83bAECF0807Dd2c6880C3154a5F0B288", f"0x{'0' * 40}")
                    .replace("0xD624…B288", "0x0000…0000"),
             "the map no longer identifies HashConsensus"),
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

        # The `bot` class covers node operators, who hold validator signing
        # keys.  Collapsing it back to one consequence for the whole class reads
        # a signing-key compromise as liveness-only, when it can sign slashable
        # messages and so reduce validator balances.
        collapsed = re.sub(
            r"^- `bot` —.*?(?=^- `)",
            "- `bot` — off-chain: picks when and what, never how much. Compromise is a\n"
            "  liveness problem, not a funds problem.\n",
            readme, flags=re.MULTILINE | re.DOTALL)
        if collapsed == readme:
            raise AssertionError("README bot-class mutant changed nothing")
        readme_path.write_text(collapsed, encoding="utf-8")
        invoke(fixture, False, "never mentions 'Node operators'")
        readme_path.write_text(readme, encoding="utf-8")

        # The qualification must survive as a claim, not merely as a name: the
        # slashable consequence is the part that breaks the liveness-only
        # reading, so dropping it alone must still fail closed.
        unslashable = readme.replace("can sign slashable messages", "can be rotated")
        if unslashable == readme:
            raise AssertionError("README slashable mutant changed nothing")
        readme_path.write_text(unslashable, encoding="utf-8")
        invoke(fixture, False, "never mentions 'slashable'")
        readme_path.write_text(readme, encoding="utf-8")

        invoke(fixture, True)

    print("diagram taxonomy mutants rejected: predeploy as consensus layer (card and node), "
          "oracle as quorum-held, HashConsensus demoted, guardian veto, 5/9 constant, "
          "EasyTrack veto, conflated verifiers, untooltipped node, undocumented class; "
          "relabelled node and card repaints and a dropped entity still caught by "
          "address; `bot` compromise collapsed to a class-wide invariant rejected on "
          "the README entry and on the rendered legend pill (restated, stripped, and "
          "with the slashable consequence dropped)")


if __name__ == "__main__":
    main()
