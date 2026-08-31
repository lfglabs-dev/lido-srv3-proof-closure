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

# address -> (entity, required class).  A label is how a box reads, not what it
# is: rewording one drops its TAXONOMY entry and the rule with it.  An on-chain
# address cannot be moved by rewording, so the taxonomy-critical entities are
# bound here to their deployed identity as well.  Every entry must still be
# found somewhere on the map, so deleting or renaming a box fails closed
# instead of quietly retiring its rule.
IDENTITY = {
    "0x852deD011285fe67063a08005c71a85690503Cee": ("AccountingOracle", "el"),
    "0x0De4Ea0184c2ad0BacA7183356Aea5B8d5Bf5c6e": ("ValidatorsExitBusOracle", "el"),
    "0xD624B08C83bAECF0807Dd2c6880C3154a5F0B288": ("HashConsensus", "com"),
    "0xF573E9E3de1f86B085417ab294f56E7920B4e9Be": ("DepositSecurityModule", "com"),
    "0xF0211b7660680B49De1A7E9f25C65660F0a13Fea": ("EasyTrack EVMScriptExecutor", "com"),
    "0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02": ("EIP-4788 beacon roots", "sys"),
    "0x00000961Ef480Eb55e80D19ad83579A64c007002": ("EIP-7002 withdrawals", "sys"),
    "0x0000BBdDc7CE488642fb579F8B00f3a590007251": ("EIP-7251 consolidations", "sys"),
}

# name -> required class.  Names are matched against the node label and the
# notes-card heading; an entity may appear as either or both.  This layer reads
# the map the way a reader does; IDENTITY above is what survives a relabelling.
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

# The `bot` class collects off-chain actors whose compromise does not cost the
# same thing, so its README entry must qualify per actor instead of asserting
# one consequence for the class.  Node operators are the case that breaks a
# liveness-only reading: they hold validator signing keys, and a compromised
# signing key can sign slashable messages, which reduces validator balances even
# though no `bot` actor can redirect principal.  Requiring the qualification
# inside the entry fails closed when it is dropped; a banned-sentence list would
# only catch the one wording it happened to name.
BOT_ENTRY = re.compile(r"^- `bot` —.*?(?=^- `)", re.MULTILINE | re.DOTALL)
BOT_QUALIFICATION = (
    ("Node operators", "the exception must be attributed to a named actor"),
    ("signing keys", "the node operators' validator signing keys must be named"),
    ("slashable", "a compromised signing key can sign slashable messages"),
)

NODE = re.compile(r'<g class="node ([a-z]+)"(.*?)</g>', re.DOTALL)
CARD = re.compile(r'<div class="c ([a-z]+)"><div class="n">(.*?)</div>(.*?</div>)</div>')
LEGEND = re.compile(r'<span class="([a-z]+)">')
LABEL = re.compile(r'<text class="nm"[^>]*>(.*?)</text>', re.DOTALL)
CARD_ADDRESS = re.compile(r'<div class="a">(.*?)</div>')


def fail(message):
    raise SystemExit(f"diagram taxonomy: {message}")


def abbreviated(address):
    # Cards print the address the way the map does.  Deriving the short form
    # from the full one keeps one identity per entity, so the node surface and
    # the card surface cannot drift apart.
    return f"{address[:6]}…{address[-4:]}"


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
        # The node body carries the tooltip, and the tooltip carries the full
        # address: that is the entity's identity, independent of its label.
        nodes.append((label.group(1).strip(), match.group(1), match.group(2)))
    if not nodes:
        fail(f"no nodes parsed from {DIAGRAM.relative_to(ROOT)}")

    cards = []
    for m in CARD.finditer(html):
        address = CARD_ADDRESS.search(m.group(3))
        cards.append((m.group(2).strip(), m.group(1), address.group(1) if address else ""))
    if not cards:
        fail(f"no notes cards parsed from {DIAGRAM.relative_to(ROOT)}")

    for name, kind, _ in nodes + cards:
        if kind not in CLASSES:
            fail(f"{name!r} uses unknown class {kind!r}")
        expected = TAXONOMY.get(name)
        if expected and kind != expected:
            fail(f"{name!r} is drawn as {kind!r}, must be {expected!r}")
        if kind == "cl" and name not in CONSENSUS_LAYER:
            fail(f"{name!r} is drawn as consensus layer; only {CONSENSUS_LAYER} is")

    located = set()
    for address, (entity, expected) in IDENTITY.items():
        forms = (address.lower(), abbreviated(address).lower())
        for name, kind, identity in nodes + cards:
            if not any(form in identity.lower() for form in forms):
                continue
            located.add(address)
            if kind != expected:
                fail(f"{entity} ({address}) is drawn as {kind!r} under the label "
                     f"{name!r}, must be {expected!r}")
    absent = [f"{entity} ({address})" for address, (entity, _) in IDENTITY.items()
              if address not in located]
    if absent:
        fail(f"the map no longer identifies {', '.join(absent)}; a taxonomy-critical "
             "entity must stay addressable so its class rule cannot lapse")

    drawn = {kind for _, kind, _ in nodes + cards}
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

    entry = BOT_ENTRY.search(readme)
    if not entry:
        fail(f"{DIAGRAM_README.relative_to(ROOT)} has no `bot` class entry to qualify")
    for phrase, why in BOT_QUALIFICATION:
        if phrase not in entry.group(0):
            fail(f"the `bot` entry states one compromise consequence for the whole "
                 f"class and never mentions {phrase!r}: {why}")

    print(f"diagram taxonomy ok: {len(nodes)} nodes, {len(cards)} cards, "
          f"{len(legend)} legend classes, {len(IDENTITY)} address-bound entities")


if __name__ == "__main__":
    sys.exit(main())
