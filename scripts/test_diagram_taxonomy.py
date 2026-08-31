#!/usr/bin/env python3
"""Fail-closed mutants for the architecture-map taxonomy checker."""

import importlib.util
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKER = "scripts/check_diagram_taxonomy.py"
DIAGRAM = "diagram/index.html"
DIAGRAM_README = "diagram/README.md"


def _load_checker():
    """Drive the family loops from the checker's own tables.

    Naming the mutated entities by hand let a table entry added later inherit
    coverage it never had: the suite kept asserting the same three samples while
    the gate had grown to eight.  Reading the tables here means a new entry
    arrives with its adversarial cases already demanded.
    """
    spec = importlib.util.spec_from_file_location("_diagram_checker", ROOT / CHECKER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CHECK = _load_checker()

NODE = re.compile(r'<g class="node ([a-z]+)"(.*?)</g>', re.DOTALL)
CARD = re.compile(r'<div class="c ([a-z]+)"><div class="n">(.*?)</div>(.*?</div>)</div>')
NODE_LABEL = re.compile(r'(<text class="nm"[^>]*>)(.*?)(</text>)', re.DOTALL)

REWORDED = "Reworded box"


def excise(diagram, pattern, needle, surface):
    """Delete the single node or card that carries `needle`, leaving the rest."""
    matches = [m for m in pattern.finditer(diagram) if needle in m.group(0)]
    if len(matches) != 1:
        raise AssertionError(f"expected one {surface} carrying {needle!r}, got {len(matches)}")
    return diagram[:matches[0].start()] + diagram[matches[0].end():]


def drop_node(diagram, needle):
    return excise(diagram, NODE, needle, "node")


def drop_card(diagram, needle):
    return excise(diagram, CARD, needle, "card")


def sole(diagram, pattern, forms, surface):
    """The one box on `surface` carrying any spelling in `forms`."""
    matches = [m for m in pattern.finditer(diagram)
               if any(form in m.group(0).lower() for form in forms)]
    if len(matches) != 1:
        raise AssertionError(f"expected one {surface} carrying {forms!r}, got {len(matches)}")
    return matches[0]


def address_forms(address):
    return (address.lower(), CHECK.abbreviated(address).lower())


def wrong_class(expected):
    # Never `cl` (that trips the consensus-layer rule first) and never the
    # expected class, so the repaint is the only thing the gate can object to.
    return "com" if expected != "com" else "el"


def reword_node(match, kind):
    body = NODE_LABEL.sub(lambda m: m.group(1) + REWORDED + m.group(3), match.group(0), count=1)
    return body.replace(f'<g class="node {match.group(1)}"', f'<g class="node {kind}"', 1)


def reword_card(match, kind):
    return match.group(0).replace(
        f'<div class="c {match.group(1)}"><div class="n">{match.group(2)}</div>',
        f'<div class="c {kind}"><div class="n">{REWORDED}</div>', 1)


def splice(diagram, match, replacement):
    return diagram[:match.start()] + replacement + diagram[match.end():]


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
        checker_path = fixture / CHECKER
        diagram = diagram_path.read_text(encoding="utf-8")
        readme = readme_path.read_text(encoding="utf-8")
        checker = checker_path.read_text(encoding="utf-8")

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
            # The same reattribution, retypeset.  A curly apostrophe reads
            # identically and used to slip the banned ASCII spelling on every
            # surface at once, so the wording rule has to fold typography first.
            (diagram.replace("committee's veto window", "guardians’ veto window"),
             "the consolidation veto is the committee's REMOVE_ROLE"),
            # The window handed to a holder the banned list never names.  Banning
            # spellings only removes the ones enumerated, so each surface has to
            # name the committee affirmatively instead.
            (diagram.replace("committee's veto window", "DSM's veto window"),
             "names the committee as its owner only 0 time(s)"),
            # Only the notes card reattributed.  The canvas spells the owner
            # `consolidation committee's`, so this leaves that surface intact and
            # fails only if the notes are read as their own surface.
            (diagram.replace("the committee's veto window", "the DSM's veto window"),
             "the notes cards raises the veto window"),
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
            # The same entity dropped from one surface only.  Searching the
            # canvas and the notes cards together let whichever surface survived
            # vouch for the one that did not, so the primary drawing could lose
            # a box while its card kept the gate green.  Each surface is
            # asserted separately, in both directions.
            (drop_node(diagram, "0x852deD"),
             "the map no longer identifies AccountingOracle "
             "(0x852deD011285fe67063a08005c71a85690503Cee) on the canvas"),
            (drop_card(diagram, "0x852d"),
             "the map no longer identifies AccountingOracle "
             "(0x852deD011285fe67063a08005c71a85690503Cee) on the notes cards"),
            # A predeploy is drawn as one node but named by three addresses;
            # dropping that node must strand every identity bound to it rather
            # than only the one that happens to be checked first.
            (drop_node(diagram, "0x00000961Ef480Eb55e80D19ad83579A64c007002"),
             "on the canvas"),
        ):
            if mutated == diagram:
                raise AssertionError(f"diagram mutant for {needle!r} changed nothing")
            diagram_path.write_text(mutated, encoding="utf-8")
            invoke(fixture, False, needle)
            diagram_path.write_text(diagram, encoding="utf-8")

        # Every address-bound entity, not just the three sampled above, must
        # survive a relabelling repaint and a deletion on each surface
        # independently.  The label is rewritten in each repaint so that only
        # the address can be what catches it.
        family = []
        for address, (entity, expected) in CHECK.IDENTITY.items():
            forms = address_forms(address)
            kind = wrong_class(expected)
            for surface, pattern, reword in (
                ("canvas", NODE, reword_node),
                ("notes cards", CARD, reword_card),
            ):
                box = sole(diagram, pattern, forms, surface)
                family.append((
                    splice(diagram, box, reword(box, kind)),
                    f"is drawn as {kind!r} under the label {REWORDED!r}",
                ))
                family.append((
                    splice(diagram, box, ""),
                    f"{entity} ({address})",
                ))

        # The proof-gated boxes carry no address, so the label each surface
        # wears is the only handle their class rule has.  Repainting one,
        # deleting it, or merely rewording it must each fail closed on that
        # surface alone — the combined `Consolidation pipeline` canvas node and
        # the `ConsolidationGateway` card are the same entity spelled two ways,
        # and neither spelling may vouch for the other.
        for surface, pattern, reword, label_of, prefix in (
            ("canvas", NODE, reword_node,
             lambda m: NODE_LABEL.search(m.group(2)).group(2).strip(), "node "),
            ("notes cards", CARD, reword_card, lambda m: m.group(2).strip(), "c "),
        ):
            for label, expected in CHECK.SURFACE_REQUIRED[surface].items():
                # Match the box's own label field: the same name also occurs in
                # neighbouring prose, which is not what carries the class.
                boxes = [m for m in pattern.finditer(diagram) if label_of(m) == label]
                if len(boxes) != 1:
                    raise AssertionError(
                        f"expected one {surface} box labelled {label!r}, got {len(boxes)}")
                box = boxes[0]
                repainted = wrong_class(expected)
                family.append((
                    splice(diagram, box, box.group(0).replace(
                        f'"{prefix}{expected}"', f'"{prefix}{repainted}"', 1)),
                    f"{label!r} is drawn as {repainted!r}, must be {expected!r}",
                ))
                family.append((
                    splice(diagram, box, ""),
                    f"{label!r} is no longer drawn on the {surface}",
                ))
                family.append((
                    splice(diagram, box, reword(box, expected)),
                    f"{label!r} is no longer drawn on the {surface}",
                ))

        # The consensus-layer rule is one claim with two halves: nothing else may
        # be painted `cl`, and the validator set must keep it.  Only the first
        # was enforced, so repainting the sole genuine `cl` entity — or deleting
        # it outright — left the legend and the documentation intact with this
        # gate still reporting success.  The validator set carries no address, so
        # no IDENTITY rule can catch the repaint on its behalf.  Every class it
        # could be repainted to is driven from the checker's own table, so a
        # class added later arrives with its adversarial case already demanded.
        for label in CHECK.CONSENSUS_LAYER:
            boxes = [m for m in NODE.finditer(diagram)
                     if NODE_LABEL.search(m.group(2)).group(2).strip() == label]
            if len(boxes) != 1:
                raise AssertionError(
                    f"expected one canvas box labelled {label!r}, got {len(boxes)}")
            box = boxes[0]
            needle = f"[{label!r}] is not drawn as consensus layer"
            for kind in CHECK.CLASSES:
                if kind == "cl":
                    continue
                family.append((
                    splice(diagram, box,
                           box.group(0).replace('"node cl"', f'"node {kind}"', 1)),
                    needle,
                ))
            family.append((splice(diagram, box, ""), needle))
            # Merely rewording it keeps the colour but retires the name the rule
            # is keyed to, so the other half of the same claim has to catch it.
            family.append((
                splice(diagram, box, reword_node(box, "cl")),
                f"{REWORDED!r} is drawn as consensus layer; only",
            ))

        # A reworded label must not retire its class rule.  Renaming a box while
        # leaving its address and its colour untouched satisfies every
        # address-bound rule, so only the taxonomy-coverage check can catch it.
        renamed = next(m for m in NODE.finditer(diagram)
                       if NODE_LABEL.search(m.group(2)).group(2).strip() == "EIP-4788")
        family.append((
            splice(diagram, renamed, reword_node(renamed, "sys")),
            "taxonomy name(s) ['EIP-4788'] are no longer drawn on either surface",
        ))

        for mutated, needle in family:
            if mutated == diagram:
                raise AssertionError(f"family mutant for {needle!r} changed nothing")
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

        # Documenting every class is not the same claim as the intro's count.
        # The intro promises the list is exhaustive, so a stale number tells a
        # reader to stop looking one class early while every class still has an
        # entry — the per-class loop above passes throughout.  Every wrong
        # spelling of the count is driven from the checker's own word table so a
        # class added later arrives with this case already demanded.
        correct = CHECK.NUMBER_WORDS[len(CHECK.CLASSES)]
        for word in CHECK.NUMBER_WORDS:
            if word == correct:
                continue
            miscounted = readme.replace(f"the {correct} classes are pinned here",
                                        f"the {word} classes are pinned here", 1)
            if miscounted == readme:
                raise AssertionError("README class-count mutant changed nothing")
            readme_path.write_text(miscounted, encoding="utf-8")
            invoke(fixture, False, f"says {word!r} classes are pinned but "
                                   f"{len(CHECK.CLASSES)} are enforced")
            readme_path.write_text(readme, encoding="utf-8")

        # Dropping the sentence rather than misnumbering it retires the claim
        # instead of contradicting it, so it must fail closed too.
        uncounted = readme.replace(f"the {correct} classes are pinned here",
                                   "the classes below are pinned", 1)
        if uncounted == readme:
            raise AssertionError("README uncounted mutant changed nothing")
        readme_path.write_text(uncounted, encoding="utf-8")
        invoke(fixture, False, "no longer states how many classes are pinned")
        readme_path.write_text(readme, encoding="utf-8")

        # The count is bound to the enforced set, not to the literal `six`:
        # growing CLASSES and documenting the new class leaves the intro stale,
        # which is the direction a future taxonomy edit actually takes.
        grown, substitutions = re.subn(
            r"^CLASSES = .*$",
            f"CLASSES = {CHECK.CLASSES + ('mpc',)!r}",
            checker, count=1, flags=re.MULTILINE)
        if substitutions != 1:
            raise AssertionError("checker CLASSES mutant changed nothing")
        checker_path.write_text(grown, encoding="utf-8")
        readme_path.write_text(readme + "\n- `mpc` — a newly pinned class.\n",
                               encoding="utf-8")
        invoke(fixture, False, f"but {len(CHECK.CLASSES) + 1} are enforced")
        checker_path.write_text(checker, encoding="utf-8")
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
          "oracle as quorum-held, HashConsensus demoted, guardian veto (the banned "
          "spelling, the same claim retypeset with a curly apostrophe, and a "
          "reattribution no banned list names, rejected per surface), 5/9 constant, "
          "EasyTrack veto, conflated verifiers, untooltipped node, undocumented class; "
          f"a taxonomy intro miscounted to each of the other "
          f"{len(CHECK.NUMBER_WORDS) - 1} words the checker knows, and one that drops the "
          "count instead of misstating it, rejected while every class stays documented, "
          "and the count shown bound to the enforced set by growing CLASSES; "
          "relabelled node and card repaints and a dropped entity still caught by "
          "address; an entity dropped from one surface only (canvas node deleted with "
          "its card kept, card deleted with its node kept, and a multi-address "
          "predeploy node deleted) rejected per surface; `bot` compromise collapsed "
          "to a class-wide invariant rejected on "
          "the README entry and on the rendered legend pill (restated, stripped, and "
          "with the slashable consequence dropped); "
          f"every one of {len(CHECK.IDENTITY)} address-bound entities relabel-repainted "
          "and deleted per surface, every proof-gated box repainted, deleted and merely "
          "reworded per surface (the combined `Consolidation pipeline` canvas node and "
          "the `ConsolidationGateway` card bound independently), and a rename that keeps "
          "its address and colour still rejected for retiring its taxonomy rule; "
          f"the addressless consensus-layer box repainted to each of the "
          f"{len(CHECK.CLASSES) - 1} other classes, deleted, and merely reworded, "
          "rejected in both directions of the one-genuine-`cl`-entity rule")


if __name__ == "__main__":
    main()
