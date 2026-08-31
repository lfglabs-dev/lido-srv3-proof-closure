#!/usr/bin/env python3
"""Bind the architecture map's colour taxonomy to what the pinned source says.

The map colours a box by what makes it trustworthy.  Two mistakes are cheap to
make and expensive for a reader: drawing an EL system predeploy (EIP-4788,
EIP-7002, EIP-7251) as consensus layer, which puts it outside the EL trust
boundary it actually sits inside; and drawing an oracle contract as
quorum-held, which moves the committee off `HashConsensus` where it lives.  A
third is attributing the consolidation batch veto to the DSM guardians when
`ConsolidationBus.REMOVE_ROLE` belongs to the consolidation committee.

Each is pinned here against `diagram/README.md`, which carries the citations.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIAGRAM = ROOT / "diagram/index.html"
DIAGRAM_README = ROOT / "diagram/README.md"

CLASSES = ("el", "proof", "com", "bot", "sys", "cl")

# name -> required class.  Names are matched against the node label and the
# notes-card heading; an entity may appear as either or both.
TAXONOMY = {
    "EIP-4788": "sys",
    "EIP-7002 · 7251": "sys",
    "EIP-4788 / 7002 / 7251": "sys",
    "AccountingOracle": "el",
    "ValidatorsExitBus": "el",
    "ValidatorsExitBus(Oracle)": "el",
    "HashConsensus": "com",
    "DepositSecurityModule": "com",
    "DepositSecurityModule + guardians": "com",
    "EasyTrack": "com",
    "EasyTrack · EVMScriptExecutor": "com",
    "TopUpGateway": "proof",
    "ConsolidationGateway": "proof",
}

# Only the validator set is consensus layer.  Anything else painted `cl` is the
# taxonomy error this map was corrected for.
CONSENSUS_LAYER = ("Validators 0x01 / 0x02",)

BANNED = {
    "5/9 quorum": "quorum lives in HashConsensus and is governance-set, not a constant",
    "guardians' veto": "the consolidation veto is the committee's REMOVE_ROLE, not the guardians'",
    "vetoable motions": "EasyTrack holds ALLOW_PAIR_ROLE only",
    "(ext. repo)": "the IStakingModuleV2 interface is in the pinned repo; only the impl is external",
}

REQUIRED = (
    ("ALLOW_PAIR_ROLE", "EasyTrack's allow-only consolidation power must be named"),
    ("REMOVE_ROLE", "the batch veto role must be named"),
    ("CLValidatorVerifier", "TopUpGateway's verifier must be distinguished"),
    ("CLProofVerifier", "ConsolidationGateway's verifier must be distinguished"),
    ("isDepositsPaused", "the DSM's only reach into consolidation must be named"),
    ("BaseOracle", "the oracles must be shown deferring quorum to HashConsensus"),
)

NODE = re.compile(r'<g class="node ([a-z]+)"(.*?)</g>', re.DOTALL)
CARD = re.compile(r'<div class="c ([a-z]+)"><div class="n">(.*?)</div>')
LEGEND = re.compile(r'<span class="([a-z]+)">')
LABEL = re.compile(r'<text class="nm"[^>]*>(.*?)</text>', re.DOTALL)


def fail(message):
    raise SystemExit(f"diagram taxonomy: {message}")


def main():
    html = DIAGRAM.read_text(encoding="utf-8")

    nodes = []
    for match in NODE.finditer(html):
        label = LABEL.search(match.group(2))
        if not label:
            fail("a node carries no visible label")
        # Off-chain actors have no address and no source file to cite; every
        # on-chain box must say on hover what it is and where that comes from.
        if match.group(1) != "bot" and "<title>" not in match.group(2):
            fail(f"node {label.group(1)!r} carries no hover tooltip to cite its source")
        nodes.append((label.group(1).strip(), match.group(1)))
    if not nodes:
        fail(f"no nodes parsed from {DIAGRAM.relative_to(ROOT)}")

    cards = [(m.group(2).strip(), m.group(1)) for m in CARD.finditer(html)]
    if not cards:
        fail(f"no notes cards parsed from {DIAGRAM.relative_to(ROOT)}")

    for name, kind in nodes + cards:
        if kind not in CLASSES:
            fail(f"{name!r} uses unknown class {kind!r}")
        expected = TAXONOMY.get(name)
        if expected and kind != expected:
            fail(f"{name!r} is drawn as {kind!r}, must be {expected!r}")
        if kind == "cl" and name not in CONSENSUS_LAYER:
            fail(f"{name!r} is drawn as consensus layer; only {CONSENSUS_LAYER} is")

    drawn = {kind for _, kind in nodes + cards}
    legend = set(LEGEND.findall(html)) & set(CLASSES)
    if not drawn <= legend:
        fail(f"class(es) {sorted(drawn - legend)} are drawn but absent from the legend")

    for phrase, why in BANNED.items():
        if phrase in html:
            fail(f"{phrase!r} still appears: {why}")

    readme = DIAGRAM_README.read_text(encoding="utf-8")
    for phrase, why in REQUIRED:
        if phrase not in html:
            fail(f"{DIAGRAM.relative_to(ROOT)} never mentions {phrase!r}: {why}")
        if phrase not in readme:
            fail(f"{DIAGRAM_README.relative_to(ROOT)} never mentions {phrase!r}: {why}")
    for kind in CLASSES:
        if f"`{kind}`" not in readme:
            fail(f"{DIAGRAM_README.relative_to(ROOT)} does not document class {kind!r}")

    print(f"diagram taxonomy ok: {len(nodes)} nodes, {len(cards)} cards, "
          f"{len(legend)} legend classes")


if __name__ == "__main__":
    sys.exit(main())
