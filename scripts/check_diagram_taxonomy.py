#!/usr/bin/env python3
"""Bind the architecture map's colour taxonomy to what the pinned source says.

The map colours a box by what makes it trustworthy.  Two mistakes are cheap to
make and expensive for a reader: drawing an EL system predeploy (EIP-4788,
EIP-7002, EIP-7251) as consensus layer, which puts it outside the EL trust
boundary it actually sits inside; and drawing an oracle contract as
quorum-held, which moves the committee off `HashConsensus` where it lives.  A
third is attributing the consolidation batch veto to the DSM guardians when
`ConsolidationBus.REMOVE_ROLE` belongs to the consolidation committee.  A
fourth is dropping a box out of the `proof` class, which is the claim that it
only acts behind a beacon-root proof.  A fifth is printing one entity's
deployed address on another's box: the class stays right, so no colour rule
notices, while the reader is told to look up the wrong contract.

Each is pinned here against `diagram/README.md`, which carries the citations.
"""

import re
import sys
from html import unescape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIAGRAM = ROOT / "diagram/index.html"
DIAGRAM_README = ROOT / "diagram/README.md"

CLASSES = ("el", "proof", "com", "bot", "sys", "cl")

SURFACES = ("canvas", "notes cards")

# Each surface publishes one form of an address, and the form is the point.  A
# canvas node carries its address in the hover tooltip, where there is room for
# all forty hex digits and where a reader goes precisely to copy them; a notes
# card prints the elided `0x852d…3Cee` that fits the card.  Accepting either
# form on either surface made the two interchangeable, so shortening a tooltip
# to the card's spelling left this gate reporting eight entities bound while the
# canvas published no full address at all and a reader hovering for one found an
# elision they cannot look up.  The form each surface owes is pinned here.
FULL, ABBREVIATED = "full", "abbreviated"
SURFACE_FORM = {"canvas": FULL, "notes cards": ABBREVIATED}
if set(SURFACE_FORM) != set(SURFACES):
    raise SystemExit("diagram taxonomy: every surface must pin the address form it "
                     f"publishes; {sorted(SURFACE_FORM)} does not cover {list(SURFACES)}")

# address -> (entity, required class, {surface: the label that address belongs
# under}).  A label is how a box reads, not what it is: rewording one drops its
# TAXONOMY entry and the rule with it.  An on-chain address cannot be moved by
# rewording, so the taxonomy-critical entities are bound here to their deployed
# identity as well.  Every entry must still be found on the canvas *and* on the
# notes cards, so deleting or renaming a box fails closed instead of quietly
# retiring its rule.  Searching the two surfaces together instead let a
# surviving notes card vouch for a deleted canvas node, so the primary
# architecture drawing could lose an entity while this gate still reported
# success; the surfaces are therefore required separately.
#
# The class alone is not the identity.  Checking only the class of the box an
# address was found in let two same-class entities exchange addresses with this
# gate still reporting success: AccountingOracle and ValidatorsExitBusOracle are
# both `el`, so swapping their full and abbreviated addresses left every class
# rule satisfied while both boxes published a reader-facing address against the
# wrong contract — the exact misreading an address is pinned here to prevent.
# Each address is therefore bound to the label its entity wears, per surface,
# since the two surfaces spell the same entity differently.
IDENTITY = {
    "0x852deD011285fe67063a08005c71a85690503Cee": (
        "AccountingOracle", "el",
        {"canvas": "AccountingOracle", "notes cards": "AccountingOracle"}),
    "0x0De4Ea0184c2ad0BacA7183356Aea5B8d5Bf5c6e": (
        "ValidatorsExitBusOracle", "el",
        {"canvas": "ValidatorsExitBus", "notes cards": "ValidatorsExitBus(Oracle)"}),
    "0xD624B08C83bAECF0807Dd2c6880C3154a5F0B288": (
        "HashConsensus", "com",
        {"canvas": "HashConsensus", "notes cards": "HashConsensus"}),
    "0xF573E9E3de1f86B085417ab294f56E7920B4e9Be": (
        "DepositSecurityModule", "com",
        {"canvas": "DepositSecurityModule",
         "notes cards": "DepositSecurityModule + guardians"}),
    "0xF0211b7660680B49De1A7E9f25C65660F0a13Fea": (
        "EasyTrack EVMScriptExecutor", "com",
        {"canvas": "EasyTrack", "notes cards": "EasyTrack · EVMScriptExecutor"}),
    "0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02": (
        "EIP-4788 beacon roots", "sys",
        {"canvas": "EIP-4788", "notes cards": "EIP-4788 / 7002 / 7251"}),
    "0x00000961Ef480Eb55e80D19ad83579A64c007002": (
        "EIP-7002 withdrawals", "sys",
        {"canvas": "EIP-7002 · 7251", "notes cards": "EIP-4788 / 7002 / 7251"}),
    "0x0000BBdDc7CE488642fb579F8B00f3a590007251": (
        "EIP-7251 consolidations", "sys",
        {"canvas": "EIP-7002 · 7251", "notes cards": "EIP-4788 / 7002 / 7251"}),
}

# A missing surface entry would skip the binding for that surface rather than
# enforce it, so an entry added later must name both surfaces to be admitted.
for _address, (_entity, _class, _labels) in IDENTITY.items():
    if set(_labels) != set(SURFACES):
        raise SystemExit(f"diagram taxonomy: {_entity} ({_address}) binds labels for "
                         f"{sorted(_labels)}, must bind one for each of {list(SURFACES)}")

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
    "Consolidation pipeline": "proof",
}

# The `proof` boxes are what SRv3 adds and has not deployed, so they carry no
# address and IDENTITY cannot reach them — yet `proof` is exactly the claim a
# reader must not see weakened, since it says the box only acts behind a
# beacon-root proof.  The canvas draws the consolidation path as one combined
# `Consolidation pipeline` box while the notes card names its gateway, so the
# same entity is spelled differently per surface; pinning one label left the
# other surface free to be repainted with this gate still reporting success.
# Each surface is therefore required to carry its own spelling at class `proof`,
# which also makes a rewording fail closed instead of quietly retiring the rule.
SURFACE_REQUIRED = {
    "canvas": {"TopUpGateway": "proof", "Consolidation pipeline": "proof"},
    "notes cards": {"TopUpGateway": "proof", "ConsolidationGateway": "proof"},
}

# Only the validator set is consensus layer, and the validator set must stay
# consensus layer: those are the two halves of one claim.  Anything else painted
# `cl` is the taxonomy error this map was corrected for, but rejecting only that
# half left the sole genuine `cl` entity free to be repainted `el`, `bot` or
# anything else with the legend and the documentation intact and this gate still
# reporting success — the reader would then meet the validator set drawn inside
# a trust boundary it does not sit in.  The validator set carries no address, so
# IDENTITY cannot reach it and the label it wears is the only handle its class
# rule has; both directions are enforced against that label below.
CONSENSUS_LAYER = ("Validators 0x01 / 0x02",)

BANNED = {
    "5/9 quorum": "quorum lives in HashConsensus and is governance-set, not a constant",
    "guardians' veto": "the consolidation veto is the committee's REMOVE_ROLE, not the guardians'",
    "vetoable motions": "EasyTrack holds ALLOW_PAIR_ROLE only",
    "(ext. repo)": "the IStakingModuleV2 interface is in the pinned repo; only the impl is external",
}

# A rule written as one ASCII spelling retires itself the moment the prose is
# retypeset: `guardians’ veto window` with a curly apostrophe reads identically
# to a reader and no longer matches `guardians' veto`.  Punctuation that only
# varies typographically is folded to its ASCII form before any wording rule is
# applied, so a rule survives ordinary editing.  Only marks that are purely
# typographic are folded: the README's class entries are delimited by an em dash
# that BOT_ENTRY keys on and name their class in backticks that the class-doc
# check looks for, so neither is a spelling variant of anything here.
TYPOGRAPHY = str.maketrans({
    "‘": "'", "’": "'", "ʼ": "'", "´": "'",
    "“": '"', "”": '"',
})

# Banning the guardians' spelling only removes one way to misattribute the
# consolidation veto; the claim can be handed to any other holder by rewording.
# The Bus delay is the consolidation committee's window because `removeBatches`
# is `REMOVE_ROLE`, so each surface that raises the window must also name the
# committee as its owner, and every mention must carry that owner rather than
# leaving one attributed elsewhere.  Requiring the attribution affirmatively
# fails closed under rewording; a banned list only catches what it enumerates.
VETO_WINDOW = re.compile(r"veto window")
VETO_OWNED = re.compile(r"committee's veto window")

# The README's taxonomy intro promises the reader an exhaustive list, so the
# count it states is a claim about CLASSES and not decoration: adding a class
# without renumbering leaves the prose asserting the list is complete when it is
# one short, and a reader who trusts it stops looking.  Requiring the two agree
# fails closed on either edit; checking only that each class is documented, as
# the loop below does, cannot notice a stale count.
NUMBER_WORDS = ("zero", "one", "two", "three", "four", "five", "six", "seven",
                "eight", "nine", "ten")
CLASS_COUNT = re.compile(r"the (\w+) classes are pinned here")

REQUIRED = (
    ("ALLOW_PAIR_ROLE", "EasyTrack's allow-only consolidation power must be named"),
    ("REMOVE_ROLE", "the batch veto role must be named"),
    ("isDepositsPaused", "the DSM's only reach into consolidation must be named"),
    ("BaseOracle", "the oracles must be shown deferring quorum to HashConsensus"),
)

# The two gateways gate on the same beacon root through *different* verifiers,
# and which one a gateway inherits is the claim a reader takes away.  Requiring
# both names as document-wide substrings, the way REQUIRED above does, cannot
# read that claim: both spellings survive when the pair is exchanged, so the
# TopUpGateway box could be repainted with the ConsolidationGateway's verifier
# and this gate still reported success; both also survive when a gateway box
# drops its verifier entirely, since the unrelated EIP-4788 box cites both `.sol`
# files.  Each mention is therefore bound to the gateway it is claimed for.
GATEWAY_VERIFIER = {
    "TopUpGateway": "CLValidatorVerifier",
    "ConsolidationGateway": "CLProofVerifier",
}

# Surface -> box label -> the gateway whose verifier claim that box carries.
# The canvas draws the consolidation path as one combined box, so the label a
# reader meets differs per surface while the claim underneath is the same.
VERIFIER_SURFACE = {
    "canvas": {"TopUpGateway": "TopUpGateway",
               "Consolidation pipeline": "ConsolidationGateway"},
    "notes cards": {"TopUpGateway": "TopUpGateway",
                    "ConsolidationGateway": "ConsolidationGateway"},
}

# Gateway and verifier names in one pass, longest first so `ConsolidationGateway`
# is never read as a bare prefix.  A mention is attributed to the nearest gateway
# named before it; inside a gateway's own box an unqualified mention is that
# box's own claim, which is how `inherits CLValidatorVerifier` reads.
MENTION = re.compile("|".join(re.escape(name) for name in sorted(
    set(GATEWAY_VERIFIER) | set(GATEWAY_VERIFIER.values()), key=len, reverse=True)))

# The README's `proof` entry is where the pairing is stated for the record, so it
# must carry both pairings and attribute each one explicitly: prose has no box to
# make an unqualified mention default to.
PROOF_ENTRY = re.compile(r"^- `proof` —.*?(?=^- `)", re.MULTILINE | re.DOTALL)

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

# The README carries the citations, but the legend pill is the surface a reader
# actually looks at.  Pinning the qualification to the README alone left the map
# free to go on asserting one consequence for the whole class, which is how a
# `liveness only` pill outlived the corrected README entry.  The pill's visible
# text must not make the class-wide claim, and the pill must carry the
# qualification itself rather than leave it elsewhere in the document.
BOT_LEGEND = re.compile(r'<span class="bot"[^>]*>(.*?)</span>', re.DOTALL)
BOT_LEGEND_BANNED = (
    ("liveness only", "node operators hold signing keys that can sign slashable messages"),
    ("liveness, not funds", "slashing reduces validator balances, which is a funds outcome"),
)

NODE = re.compile(r'<g class="node ([a-z]+)"(.*?)</g>', re.DOTALL)
CARD = re.compile(r'<div class="c ([a-z]+)"><div class="n">(.*?)</div>(.*?</div>)</div>')
LEGEND = re.compile(r'<span class="([a-z]+)"[^>]*>')
LABEL = re.compile(r'<text class="nm"[^>]*>(.*?)</text>', re.DOTALL)
CARD_ADDRESS = re.compile(r'<div class="a">(.*?)</div>')

# HTML comments render as nothing.  A verifier name or a required phrase
# hidden inside <!-- … --> is not visible to a reader and must not satisfy
# any check.  Applied to the full HTML before any scan, and before
# searching the README for required taxonomy content.
_COMMENT = re.compile(r'<!--.*?-->', re.DOTALL)


# What continues an address token rather than ending it.  A corrupted address
# is not corrupted only with hex: `…3Ceeg`, `…3Cee_`, `…3CeeZ` and `X0x852d…`
# all publish a token a reader would copy and fail to look up, and a boundary
# class of hex alone accepts every one of them because the valid address is
# still a substring.  Any letter, digit or underscore therefore continues the
# token, as does the ellipsis the abbreviated form elides its middle with.
_TOKEN_CHAR = r'[0-9A-Za-z_…]'


_CONTINUES = re.compile(_TOKEN_CHAR)

# Markup and character references are not what a reader copies.  `&#103;` is
# three punctuation-looking characters to a regex and a `g` to a browser, so a
# boundary check run over raw HTML reads the reference as the gap it needs and
# accepts `0x852d…3Cee&#103;` — which the map then publishes as `0x852d…3Ceeg`.
# Tags collapse to a space rather than to nothing: two separately positioned
# text elements sit side by side in the source without being one token on the
# page, and joining them would invent corruption that no reader can see.
_TAG = re.compile(r'<[^>]*>')


def rendered(fragment):
    """The text a reader is actually shown: markup removed, references decoded."""
    return unescape(_TAG.sub(" ", _COMMENT.sub(" ", fragment)))


def _address_occurrences(text, addr):
    """Count the standalone and the extended publications of addr in text.

    Asking only whether *some* standalone occurrence exists lets an intact form
    vouch for a corrupted one printed beside it: `0x852d…3Cee · 0x852d…3Ceeg`
    answers yes on the first form while the second is an address a reader would
    copy and fail to look up.  Every occurrence is therefore judged on its own
    boundaries, so locating an entity and rejecting a corrupted publication stay
    independent questions.  Any letter, digit or underscore continues the token,
    as does the ellipsis the abbreviated form elides its middle with, so the
    extension does not have to be a hex digit to be caught.
    """
    standalone = extended = 0
    for match in re.finditer(re.escape(addr), text):
        before = text[match.start() - 1:match.start()]
        after = text[match.end():match.end() + 1]
        if _CONTINUES.match(before) or _CONTINUES.match(after):
            extended += 1
        else:
            standalone += 1
    return standalone, extended


def fail(message):
    raise SystemExit(f"diagram taxonomy: {message}")


def fold(text):
    return text.translate(TYPOGRAPHY)


def abbreviated(address):
    # Cards print the address the way the map does.  Deriving the short form
    # from the full one keeps one identity per entity, so the node surface and
    # the card surface cannot drift apart.
    return f"{address[:6]}…{address[-4:]}"


def verifier_claims(where, text, own):
    """Return the (gateway, verifier) pairs `text` claims, rejecting mismatches.

    `own` is the gateway whose box this is, and it holds until the prose names
    another gateway: that is what lets a box say `inherits CLValidatorVerifier`
    without repeating whose it is, and still read `the ConsolidationGateway's
    CLProofVerifier` as the contrast it is rather than as a second claim.  Prose
    with no box of its own passes `own=None`, so every mention there must name
    its gateway.
    """
    # A verifier name inside an HTML comment is not visible to a reader and
    # must not count as a published claim.
    text = _COMMENT.sub(" ", text)
    holder = own
    claimed = set()
    for match in MENTION.finditer(text):
        token = match.group(0)
        if token in GATEWAY_VERIFIER:
            holder = token
            continue
        if holder is None:
            fail(f"{where} names {token!r} without saying whose verifier it is; the "
                 "two gateways inherit different verifiers and the pairing is the claim")
        if GATEWAY_VERIFIER[holder] != token:
            fail(f"{where} attributes {token!r} to {holder}, which inherits "
                 f"{GATEWAY_VERIFIER[holder]!r}; the gateways gate on the same beacon "
                 "root through different verifiers and exchanging them misstates both")
        claimed.add((holder, token))
    return claimed


def main():
    # Strip HTML comments before all scans: content inside <!-- … --> is not
    # rendered to a reader and must not contribute to any check — whether
    # identifying an entity, enforcing a class, or verifying required text.
    html = _COMMENT.sub(" ", fold(DIAGRAM.read_text(encoding="utf-8")))

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
    card_bodies = []
    for m in CARD.finditer(html):
        address = CARD_ADDRESS.search(m.group(3))
        cards.append((m.group(2).strip(), m.group(1), address.group(1) if address else ""))
        card_bodies.append(m.group(0))
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

    consensus = {name for name, kind, _ in nodes + cards if kind == "cl"}
    demoted = [name for name in CONSENSUS_LAYER if name not in consensus]
    if demoted:
        fail(f"{demoted} is not drawn as consensus layer anywhere on the map; the "
             "validator set is the one genuine `cl` entity, so repainting or "
             "renaming it moves the only consensus-layer box out of its class")

    for surface, boxes in (("canvas", nodes), ("notes cards", cards)):
        absent = []
        elided = []
        required = SURFACE_FORM[surface]
        for address, (entity, expected, labels) in IDENTITY.items():
            forms = {FULL: address.lower(), ABBREVIATED: abbreviated(address).lower()}
            belongs = labels[surface]
            located = wrong_form = False
            for name, kind, identity in boxes:
                # Read the box the way it is published: a reference that renders
                # to a letter continues the token a reader copies, even though
                # the raw source shows punctuation at that boundary.
                identity = rendered(identity).lower()
                intact = {}
                # Judged before the box is located, and on every box rather
                # than only this entity's: a corrupted token is what a reader
                # copies, so it must fail wherever it is published and whether
                # or not an intact form sits beside it.
                for spelling, form in forms.items():
                    standalone, extended = _address_occurrences(identity, form)
                    if extended:
                        fail(f"the {name!r} box on the {surface} publishes {entity}'s "
                             f"address as part of a longer token; {form!r} is extended "
                             f"there rather than printed as itself in {extended} of its "
                             f"{standalone + extended} occurrence(s), and a reader copying "
                             "what is drawn would look up an address that does not exist")
                    intact[spelling] = standalone
                if not any(intact.values()):
                    continue
                if kind != expected:
                    fail(f"{entity} ({address}) is drawn as {kind!r} under the label "
                         f"{name!r}, must be {expected!r}")
                # The class is not the identity.  Two entities of one class can
                # exchange addresses with every class rule still satisfied, and
                # the reader then meets a published address against the wrong
                # contract, so the address must be found under its own entity.
                if name != belongs:
                    fail(f"{entity} ({address}) is published on the {surface} under the "
                         f"label {name!r}, which names a different entity; the address "
                         f"belongs to {belongs!r}, and an address printed against "
                         "another box misidentifies the contract a reader would look up")
                # Being findable is not the same as being published.  Only the
                # form this surface owes counts as the entity's identity here;
                # the other form locates the box for the rules above and leaves
                # the surface still owing its own.
                if intact[required]:
                    located = True
                else:
                    wrong_form = True
            if located:
                continue
            (elided if wrong_form else absent).append(f"{entity} ({address})")
        if elided:
            other = ABBREVIATED if required == FULL else FULL
            fail(f"on the {surface}, only the {other} address of {', '.join(elided)} is "
                 f"printed; that surface publishes the {required} form, and a reader who "
                 "goes to it for an address a contract can be looked up by finds a "
                 "spelling that identifies no contract")
        if absent:
            fail(f"the map no longer identifies {', '.join(absent)} on the {surface}; "
                 "a taxonomy-critical entity must stay addressable on the canvas and "
                 "on the notes cards so its class rule cannot lapse")

    for surface, boxes in (("canvas", nodes), ("notes cards", cards)):
        drawn_here = {name: kind for name, kind, _ in boxes}
        for label, expected in SURFACE_REQUIRED[surface].items():
            if label not in drawn_here:
                fail(f"{label!r} is no longer drawn on the {surface}; a proof-gated box "
                     "carries no address, so its class rule can only be held by the label "
                     f"it wears on the {surface}")
            if drawn_here[label] != expected:
                fail(f"{label!r} is drawn as {drawn_here[label]!r} on the {surface}, "
                     f"must be {expected!r}")

    bound = 0
    for surface, boxes in (("canvas", [(name, body) for name, _, body in nodes]),
                           ("notes cards", [(name, body) for (name, _, _), body
                                            in zip(cards, card_bodies)])):
        for label, gateway in VERIFIER_SURFACE[surface].items():
            verifier = GATEWAY_VERIFIER[gateway]
            for name, body in boxes:
                if name != label:
                    continue
                if (gateway, verifier) not in verifier_claims(
                        f"the {label!r} box on the {surface}", body, gateway):
                    fail(f"the {label!r} box on the {surface} never names {verifier!r}; "
                         f"{gateway} gates on the beacon root through that verifier and "
                         "not through the other gateway's, so the box a reader meets "
                         "must say which one it inherits")
                bound += 1

    # A rule keyed by a label retires itself the moment that label is reworded.
    # Every taxonomy name must therefore still be found somewhere on the map, so
    # a rename fails closed here instead of silently dropping its class rule.
    labelled = {name for name, _, _ in nodes + cards}
    orphaned = sorted(set(TAXONOMY) - labelled)
    if orphaned:
        fail(f"taxonomy name(s) {orphaned} are no longer drawn on either surface; "
             "a reworded label must not retire its class rule")

    drawn = {kind for _, kind, _ in nodes + cards}
    legend = set(LEGEND.findall(html)) & set(CLASSES)
    if not drawn <= legend:
        fail(f"class(es) {sorted(drawn - legend)} are drawn but absent from the legend")

    for phrase, why in BANNED.items():
        if phrase in html:
            fail(f"{phrase!r} still appears: {why}")

    # The canvas and the notes cards are read independently, so an attribution
    # that survives on one surface must not vouch for the other.
    for surface, text in (("canvas", "".join(body for _, _, body in nodes)),
                          ("notes cards", "".join(card_bodies))):
        mentions = len(VETO_WINDOW.findall(text))
        owned = len(VETO_OWNED.findall(text))
        if not mentions:
            fail(f"the {surface} no longer raises the consolidation veto window; the "
                 "Bus delay is the committee's REMOVE_ROLE window and must be named "
                 "where a reader meets the box")
        if owned != mentions:
            fail(f"the {surface} raises the veto window {mentions} time(s) but names the "
                 f"committee as its owner only {owned} time(s); the window is the "
                 "consolidation committee's REMOVE_ROLE, not the DSM guardians'")

    # Strip HTML comments before all README checks: text inside <!-- … --> is
    # not rendered to a reader and must not satisfy any documentation claim.
    readme = _COMMENT.sub(" ", fold(DIAGRAM_README.read_text(encoding="utf-8")))
    for phrase, why in REQUIRED:
        if phrase not in html:
            fail(f"{DIAGRAM.relative_to(ROOT)} never mentions {phrase!r}: {why}")
        if phrase not in readme:
            fail(f"{DIAGRAM_README.relative_to(ROOT)} never mentions {phrase!r}: {why}")
    for kind in CLASSES:
        if f"`{kind}`" not in readme:
            fail(f"{DIAGRAM_README.relative_to(ROOT)} does not document class {kind!r}")

    proof_entry = PROOF_ENTRY.search(readme)
    if not proof_entry:
        fail(f"{DIAGRAM_README.relative_to(ROOT)} has no `proof` class entry to carry "
             "the gateway/verifier pairing the citations rest on")
    stated = verifier_claims(f"the `proof` entry in {DIAGRAM_README.relative_to(ROOT)}",
                             proof_entry.group(0), None)
    for gateway, verifier in GATEWAY_VERIFIER.items():
        if (gateway, verifier) not in stated:
            fail(f"the `proof` entry never states that {gateway} gates through "
                 f"{verifier!r}; the entry is where the two verifiers are told apart "
                 "for the record, so dropping a pairing retires the distinction")

    counted = CLASS_COUNT.search(readme)
    if not counted:
        fail(f"{DIAGRAM_README.relative_to(ROOT)} no longer states how many classes "
             "are pinned, so the list cannot be read as exhaustive")
    if counted.group(1) != NUMBER_WORDS[len(CLASSES)]:
        fail(f"the taxonomy intro says {counted.group(1)!r} classes are pinned but "
             f"{len(CLASSES)} are enforced; the list reads as exhaustive and is not")

    entry = BOT_ENTRY.search(readme)
    if not entry:
        fail(f"{DIAGRAM_README.relative_to(ROOT)} has no `bot` class entry to qualify")
    for phrase, why in BOT_QUALIFICATION:
        if phrase not in entry.group(0):
            fail(f"the `bot` entry states one compromise consequence for the whole "
                 f"class and never mentions {phrase!r}: {why}")

    pill = BOT_LEGEND.search(html)
    if not pill:
        fail(f"{DIAGRAM.relative_to(ROOT)} has no `bot` legend entry to qualify")
    for phrase, why in BOT_LEGEND_BANNED:
        if phrase in pill.group(1).lower():
            fail(f"the `bot` legend pill reads {phrase!r}, one compromise consequence "
                 f"for the whole class: {why}")
    for phrase, why in BOT_QUALIFICATION:
        if phrase not in pill.group(0):
            fail(f"the `bot` legend pill never mentions {phrase!r}: {why}")

    print(f"diagram taxonomy ok: {len(nodes)} nodes, {len(cards)} cards, "
          f"{len(legend)} legend classes, {len(IDENTITY)} entities bound to their "
          "class and to the label they are published under, in the full address form "
          "on the canvas and the abbreviated form on the notes cards, "
          f"{len(SURFACE_REQUIRED['canvas'])} proof-gated boxes bound per surface, "
          f"{bound} gateway boxes bound to the verifier they inherit, "
          f"{len(TAXONOMY)} taxonomy names still drawn")


if __name__ == "__main__":
    sys.exit(main())
