#!/usr/bin/env python3
"""Family-level mutants for Verity provenance agreement and uniqueness."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CHECKER = ROOT / "scripts/check_verity_provenance.py"
FILES = (
    "lakefile.lean",
    "lake-manifest.json",
    "audit/artifacts.lock.json",
    "verity/targets/audit-manifest.json",
    "verity/targets/source-map.json",
    "proofs/LOCKFILE.md",
)
PIN = "e977aaad6e1a9e92e0132d41b3d33a14135a4d46"
OTHER = "0" * 40


def run(root: Path, succeeds: bool, diagnostic: str = "") -> None:
    result = subprocess.run(
        ["python3", str(CHECKER), "--root", str(root)],
        text=True, capture_output=True, check=False,
    )
    if (result.returncode == 0) != succeeds:
        raise SystemExit(f"unexpected provenance result: {result.stdout}{result.stderr}")
    if diagnostic and diagnostic not in result.stderr:
        raise SystemExit(f"missing diagnostic {diagnostic!r}: {result.stderr}")


def load(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def write(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


with tempfile.TemporaryDirectory(prefix="verity-provenance-mutants-") as tmp:
    fixture = Path(tmp)
    for relative in FILES:
        destination = fixture / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, destination)
    (fixture / ".lake/packages").mkdir(parents=True)
    os.symlink(ROOT / ".lake/packages/verity", fixture / ".lake/packages/verity")

    run(fixture, True)

    lakefile = fixture / "lakefile.lean"
    original_lakefile = lakefile.read_text(encoding="utf-8")
    lakefile.write_text(original_lakefile.replace(PIN, PIN[:12]), encoding="utf-8")
    run(fixture, False, "not an exact 40-hex revision")
    lakefile.write_text(original_lakefile + original_lakefile.split("require verity", 1)[1].join(("\nrequire verity", "")), encoding="utf-8")
    run(fixture, False, "exactly one canonical Verity git request")
    lakefile.write_text(original_lakefile, encoding="utf-8")

    manifest_path = fixture / "lake-manifest.json"
    manifest = load(manifest_path)
    package = next(p for p in manifest["packages"] if p["name"] == "verity")
    package["rev"] = OTHER
    write(manifest_path, manifest)
    run(fixture, False, "Verity rev")
    package["rev"] = PIN
    package["inputRev"] = OTHER
    write(manifest_path, manifest)
    run(fixture, False, "Verity inputRev")
    package["inputRev"] = PIN
    manifest["packages"].append(dict(package))
    write(manifest_path, manifest)
    run(fixture, False, "exactly one Verity package")
    shutil.copy2(ROOT / "lake-manifest.json", manifest_path)

    lock_path = fixture / "audit/artifacts.lock.json"
    lock = load(lock_path)
    lock["pins"]["verity"]["commit"] = OTHER
    write(lock_path, lock)
    run(fixture, False, "artifact-lock Verity pin")
    shutil.copy2(ROOT / "audit/artifacts.lock.json", lock_path)

    audit_path = fixture / "verity/targets/audit-manifest.json"
    audit = load(audit_path)
    audit["source_revisions"]["verity"] = OTHER
    write(audit_path, audit)
    run(fixture, False, "audit-manifest Verity revision")
    shutil.copy2(ROOT / "verity/targets/audit-manifest.json", audit_path)

    source_map_path = fixture / "verity/targets/source-map.json"
    source_map = load(source_map_path)
    source_revisions = source_map.get("source_revisions")
    if not isinstance(source_revisions, dict):
        raise SystemExit("fixture source_revisions must be an object")
    source_revisions["verity_commit"] = OTHER
    write(source_map_path, source_map)
    run(fixture, False, "source-map Verity revision")
    shutil.copy2(ROOT / "verity/targets/source-map.json", source_map_path)

    lockfile_path = fixture / "proofs/LOCKFILE.md"
    original_lockfile = lockfile_path.read_text(encoding="utf-8")
    lockfile_path.write_text(original_lockfile.replace(PIN, OTHER), encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md Verity pin")
    lockfile_path.write_text(original_lockfile, encoding="utf-8")

    # Regression: row only inside an HTML comment must not qualify
    verity_row = next(l for l in original_lockfile.splitlines(keepends=True) if "| Verity |" in l)
    without_active = original_lockfile.replace(verity_row, "")
    lockfile_path.write_text(without_active + f"<!-- {verity_row.rstrip()} -->\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: unclosed HTML comment running to EOF swallows remaining content (discussion_r3889427978)
    lockfile_path.write_text(without_active + f"<!--\n{verity_row}", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: row only inside a fenced code block must not qualify
    lockfile_path.write_text(without_active + f"```\n{verity_row}```\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: opener indented up to 3 spaces is still a valid fence opener
    lockfile_path.write_text(without_active + f"   ```\n{verity_row}```\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: closer longer than opener still closes the fence
    lockfile_path.write_text(without_active + f"```\n{verity_row}````\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: unclosed fence at EOF swallows remaining content
    lockfile_path.write_text(without_active + f"```\n{verity_row}", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive regression: unclosed <!-- inside a fenced block is literal content, not an HTML
    # comment opener; the real Verity row appearing after the fence must still be found
    # (discussion_r3889471382)
    lockfile_path.write_text(without_active + f"```\nsome fenced content <!--\n```\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression: multiline code span (backtick run with backtick in info string that is not a
    # CommonMark fence opener) makes the enclosed row non-table content; must be rejected
    # (discussion_r3889471379)
    lockfile_path.write_text(without_active + f"```foo`\n{verity_row}```\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Adversarial (discussion_r3889515392 + r3889768393): invalid-info opener followed by
    # a longer-run close — the fence code span is never closed so the buffer is restored,
    # but the trailing backtick in the info string (e.g. ``foo` ``) creates a real
    # CommonMark §6.1 inline code span that spans into the Verity row, suppressing
    # ``| Verity | `` from rendered content; must be rejected.
    lockfile_path.write_text(without_active + f"```foo`\n{verity_row}````\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Same rule at 4-backtick opener length.
    lockfile_path.write_text(without_active + f"````foo`\n{verity_row}`````\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Adversarial variant: exact 4-backtick close does close the 4-backtick code span;
    # the enclosed row must be rejected.
    lockfile_path.write_text(without_active + f"````foo`\n{verity_row}````\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Adversarial (P2 inline-closer, discussion_r3889585498): exact-length backtick run
    # embedded in surrounding text on the closer line closes the code span; the enclosed
    # Verity row is non-rendered and must be rejected.
    lockfile_path.write_text(without_active + f"```foo`\n{verity_row}suffix ``` end\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Adversarial (discussion_r3889585498 + r3889768393): unequal inline run does not
    # close the fence code span; however, the trailing backtick in the opener info string
    # creates an inline code span covering the Verity row — must be rejected.
    lockfile_path.write_text(without_active + f"```foo`\n{verity_row}suffix ```` end\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive regression (discussion_r3889515387): a literal `<!--` inside a backtick
    # code span is code content, not an HTML comment opener; the real Verity row
    # appearing after it must still be found.
    lockfile_path.write_text(without_active + f"Literal `<!--` marker\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Adversarial variant: double-backtick code span with `<!--` inside.
    lockfile_path.write_text(without_active + f"Literal ``<!--`` marker\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 HTML-block, discussion_r3889642189): CommonMark §4.6 Type 1 raw
    # HTML block (<script>) swallows the Verity row; must be rejected.
    lockfile_path.write_text(without_active + f"<script>\n{verity_row}</script>\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: Verity row appearing after the closed <script> block is rendered.
    lockfile_path.write_text(without_active + f"<script>\nsome script\n</script>\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Type 6 (block-level tag, blank-line terminated) also suppresses the enclosed row.
    lockfile_path.write_text(without_active + f"<div>\n{verity_row}", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: Verity row after a blank-line-closed Type 6 block is rendered.
    lockfile_path.write_text(without_active + f"<div>\nsome content\n\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 multiline-code-span, discussion_r3889768393): a multiline inline
    # backtick code span (opener and closer on different lines) contains the Verity row;
    # the span interior must be suppressed so the row is not exposed to the regex.
    lockfile_path.write_text(without_active + f"``\n{verity_row}``\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: Verity row after a closed multiline backtick span is still rendered.
    lockfile_path.write_text(without_active + f"``some\nspanning content``\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 Type-7-HTML-block, discussion_r3889768395): CommonMark §4.6 Type 7
    # block (custom tag on a line by itself) swallows the Verity row; must be rejected.
    lockfile_path.write_text(without_active + f"<custom-element>\n{verity_row}", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: Verity row after a blank-line-terminated Type 7 block is rendered.
    lockfile_path.write_text(without_active + f"<custom-element>\nsome content\n\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 whitespace-only-blank-line, discussion_r3889768399): a line with
    # only spaces/tabs must terminate a blank-line-terminated block; Verity row after it
    # is rendered (was incorrectly hidden when the line was non-empty but whitespace-only).
    lockfile_path.write_text(without_active + f"<div>\nsome content\n   \n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Same rule applies for Type 7 blocks.
    lockfile_path.write_text(without_active + f"<custom-element>\nsome content\n   \n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 same-line-opener-closer, discussion_r3889768402): invalid-fence
    # opener whose info string already closes the code span on the opener line must not
    # enter span state; subsequent lines remain rendered.
    lockfile_path.write_text(without_active + f"```foo```\n{verity_row}```\n", encoding="utf-8")
    run(fixture, True)
    # Adversarial: invalid-fence opener whose info string does NOT close the span on the
    # opener line enters span state; a whole-line closer on a subsequent line discards
    # the buffered Verity row.
    lockfile_path.write_text(without_active + f"```foo`\n{verity_row}```\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression (P2 escaped-backtick, discussion_r3889868433): backslash-escaped
    # backticks are literals (CommonMark §2.4), not code-span delimiters.  The sequence
    # \`<!--\` must not form a code span; the enclosed <!-- must be treated as an HTML
    # comment opener and the Verity row inside the comment must be stripped.
    lockfile_path.write_text(without_active + f"\\`<!--\\`\n{verity_row}-->\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: an even number of backslashes before a backtick leaves the backtick
    # unescaped (code-span delimiter); the `` \`<!--\` `` form still protects the `<!--`
    # from being treated as a comment opener.
    lockfile_path.write_text(without_active + f"\\\\`<!--`\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 quoted-angle-bracket, discussion_r3889868441): Type 7 HTML block
    # openers may contain quoted attribute values with ">"; the [^<>]* attribute pattern
    # rejected these, leaving the Verity row visible after the opener.
    lockfile_path.write_text(without_active + f'<custom-element title="a > b">\n{verity_row}', encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: Verity row after a blank-line-terminated Type 7 block whose opener
    # contains a quoted ">" attribute is rendered.
    lockfile_path.write_text(without_active + f'<custom-element title="a > b">\nsome content\n\n{verity_row}', encoding="utf-8")
    run(fixture, True)
    # Regression (P2 unicode-whitespace-fence-close, discussion_r3889901971): CommonMark
    # §4.5 permits only ASCII spaces after a closing fence, not Unicode whitespace.  A
    # "closer" followed by U+2003 EM SPACE must not close the fence; the Verity row inside
    # the open fence must remain suppressed.
    lockfile_path.write_text(without_active + f"```\nsome content\n``` \n{verity_row}", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: fence closer followed by ASCII spaces only is valid; Verity row after it is rendered.
    lockfile_path.write_text(without_active + f"```\nsome content\n```   \n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 multiline-inline-html-tag, discussion_r3889901979): a Verity row
    # embedded inside a multiline quoted attribute value of an inline HTML open tag is
    # raw HTML (CommonMark §6.6), not rendered table content; must be rejected.
    lockfile_path.write_text(without_active + f'<span title="\n{verity_row}">\n', encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: Verity row that follows an inline HTML open tag (single-line, no multiline
    # attribute) is rendered.  The tag is inline within a table cell (not alone on a line
    # that would be classified as a Type 7 HTML block opener).
    lockfile_path.write_text(without_active + f'| col | <span title="foo"> |\n{verity_row}', encoding="utf-8")
    run(fixture, True)
    # Regression (P2 invalid-tag-before-comment, discussion_r3889941662): '<x ' is not
    # a valid CommonMark §6.6 inline tag (a '<' in attribute position is invalid); the
    # inline-tag scanner must abort so that the following '<!--' is re-scanned as a real
    # HTML comment opener and the Verity row inside the comment is stripped.
    lockfile_path.write_text(without_active + f"<x <!--\n{verity_row}-->\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: a well-formed inline HTML tag embedded within a text line (not alone on
    # the line, so not a Type 7 block opener) does not abort the scanner or suppress the
    # Verity row that follows.
    lockfile_path.write_text(without_active + f"text <x> end\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 backslash-escaped-comment-opener, discussion_r3889941663): CommonMark
    # §2.4 backslash before '<' makes it a literal character; '\<!--' must NOT be treated
    # as an HTML comment opener.  Falsely treating it as one would strip everything to EOF
    # including the real Verity row — a false positive rejection of a valid lockfile.
    lockfile_path.write_text(without_active + f"\\<!--\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Adversarial: even number of preceding backslashes (escaped backslash + unescaped '<');
    # '\\<!--' IS a real HTML comment; Verity row inside it must be stripped.
    lockfile_path.write_text(without_active + f"\\\\<!--\n{verity_row}-->\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression (P2 comment-synthesis, discussion_r3889978820): when the label and pin
    # are on separate physical lines bridged by a multiline HTML comment
    # (e.g. '| Verity <!-- ...\n--> | `pin` |'), stripping the comment must not
    # concatenate the two lines into a matching row.  The comment's newlines are
    # preserved in the output so the regex cannot span them.
    lockfile_path.write_text(without_active + f"| Verity <!-- anything\n--> | `{PIN}` |\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive: a single-line HTML comment inside the Verity row is stripped without
    # introducing a line break; the row remains valid and is accepted.
    lockfile_path.write_text(without_active + f"| Verity <!-- note --> | `{PIN}` |\n", encoding="utf-8")
    run(fixture, True)
    # Regression (P2 span-synthesis, discussion_r3889978820): a multiline backtick code
    # span whose suppression would concatenate '| Verity ' and '| `pin` |' from separate
    # physical lines must not synthesize a matching row; the span's newlines are preserved.
    lockfile_path.write_text(without_active + f"| Verity ``anycontent\n`` | `{PIN}` |\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Adversarial (P2 multiline-link-title, discussion_r3890040884): a Verity row
    # embedded inside a multiline inline link title is link metadata, not rendered table
    # content; the checker must reject a lockfile where the only pin appearance is in a
    # link title.
    lockfile_path.write_text(
        without_active + f'[anchor](https://example.com "{verity_row.rstrip()}\n")\n',
        encoding="utf-8",
    )
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive (discussion_r3890040884): a real Verity row in a rendered table is found
    # even when a link with a multiline title appears elsewhere in the file.
    lockfile_path.write_text(
        without_active + f'[link](https://example.com "note\ncontinued")\n{verity_row}',
        encoding="utf-8",
    )
    run(fixture, True)
    # Positive (P2 unterminated-quoted-tag, discussion_r3890040889): an unterminated
    # quoted HTML attribute renders literally in Markdown; the canonical Verity row that
    # follows on the next line remains active and must be accepted.
    lockfile_path.write_text(
        without_active + f'| col | <span title="\n{verity_row}',
        encoding="utf-8",
    )
    run(fixture, True)
    # Adversarial (discussion_r3890040889): re-scanning after an unterminated quoted
    # attribute still rejects a wrong pin exposed on the next line.
    lockfile_path.write_text(
        without_active + f'| col | <span title="\n| Verity | `{OTHER}` |\n',
        encoding="utf-8",
    )
    run(fixture, False, "proofs/LOCKFILE.md Verity pin")
    # Adversarial (P2 escaped-link-title-delimiter, discussion_r3890135509): a
    # backslash-escaped quote before the Verity row in a quoted link title is title
    # content (CommonMark §2.4), not the closing delimiter; the scanner must not stop
    # early and expose the following lines.  A file whose only pin appearance is
    # inside such a title must be rejected.
    lockfile_path.write_text(
        without_active + f'[anchor](url "note \\"\n{verity_row.rstrip()}\ncontinued")\n',
        encoding="utf-8",
    )
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive (discussion_r3890135509): real Verity row after a link whose title
    # contains an escaped delimiter is rendered and must be accepted.
    lockfile_path.write_text(
        without_active + f'[link](url "note \\"\ncontinued")\n{verity_row}',
        encoding="utf-8",
    )
    run(fixture, True)
    # Positive (P2 unterminated-link-title, discussion_r3890135511): a blank line
    # before the Verity row terminates the link-title attempt (CommonMark does not
    # allow titles to span blank lines); the row that follows the blank line is
    # rendered at the start of a new line and must be accepted.
    lockfile_path.write_text(
        without_active + f'[anchor](url "bad\n\n{verity_row}',
        encoding="utf-8",
    )
    run(fixture, True)
    # Adversarial (discussion_r3890135511): unterminated link title followed by a
    # blank line exposing a wrong pin renders literally; the checker must reject.
    lockfile_path.write_text(
        without_active + f'[anchor](url "bad\n\n| Verity | `{OTHER}` |\n',
        encoding="utf-8",
    )
    run(fixture, False, "proofs/LOCKFILE.md Verity pin")
    # Adversarial (P2 escaped-paren-link-title, discussion_r3890213116): in a
    # parenthesized title a backslash-escaped ')' is title content (CommonMark §2.4),
    # not the closing delimiter.  The scanner must not stop at it and expose the
    # following lines, so a file whose only pin appearance is inside such a title
    # must be rejected.
    lockfile_path.write_text(
        without_active + f'[anchor](url (note \\)\n{verity_row.rstrip()}\ncontinued))\n',
        encoding="utf-8",
    )
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Adversarial (discussion_r3890213116): an escaped '(' inside a parenthesized
    # title is likewise content and must not disturb delimiter tracking.
    lockfile_path.write_text(
        without_active + f'[anchor](url (note \\(\n{verity_row.rstrip()}\ncontinued))\n',
        encoding="utf-8",
    )
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive (discussion_r3890213116): a real Verity row after a link whose
    # parenthesized title contains an escaped delimiter is rendered and accepted.
    lockfile_path.write_text(
        without_active + f'[link](url (note \\)\ncontinued))\n{verity_row}',
        encoding="utf-8",
    )
    run(fixture, True)
    # Positive (P2 blank-line-link-title, discussion_r3890213120): a blank line
    # inside an attempted title voids the title (CommonMark §6.3) even when a
    # matching quote and ')' appear later, so the paragraph ends at the blank line
    # and the following Verity row is rendered and must be accepted.
    lockfile_path.write_text(
        without_active + f'[anchor](url "bad\n\n{verity_row.rstrip()}\ncontinued")\n',
        encoding="utf-8",
    )
    run(fixture, True)
    # Adversarial (discussion_r3890213120): the same closed-title shape exposing a
    # wrong pin renders literally; the checker must reject it.
    lockfile_path.write_text(
        without_active + f'[anchor](url "bad\n\n| Verity | `{OTHER}` |\ncontinued")\n',
        encoding="utf-8",
    )
    run(fixture, False, "proofs/LOCKFILE.md Verity pin")
    # Positive (discussion_r3890213120): the blank-line rule holds for the
    # single-quoted and parenthesized title forms as well.
    lockfile_path.write_text(
        without_active + f"[anchor](url 'bad\n\n{verity_row.rstrip()}\ncontinued')\n",
        encoding="utf-8",
    )
    run(fixture, True)
    lockfile_path.write_text(
        without_active + f'[anchor](url (bad\n\n{verity_row.rstrip()}\ncontinued))\n',
        encoding="utf-8",
    )
    run(fixture, True)
    # Positive (discussion_r3890213116): an unescaped '(' may not appear in a
    # parenthesized title (CommonMark §6.3), so no link is formed and the Verity
    # row inside the attempted title stays rendered.
    lockfile_path.write_text(
        without_active + f'[anchor](url (note (x)\n{verity_row.rstrip()}\ncontinued))\n',
        encoding="utf-8",
    )
    run(fixture, True)
    lockfile_path.write_text(original_lockfile, encoding="utf-8")

print(
    "Verity provenance mutants rejected: exact lakefile request, request uniqueness, "
    "manifest rev/inputRev/uniqueness, canonical artifact/audit/source-map pins, "
    "lockfile Verity pin (HTML comment, unclosed-HTML-comment-to-EOF, equal fence, "
    "indented opener, longer closer, unclosed-at-EOF, backtick-code-span-suppressor, "
    "exact-close-4bt-code-span, inline-exact-close-3bt-code-span, "
    "unequal-3bt-info-backtick-inline-span, unequal-4bt-info-backtick-inline-span, "
    "unequal-inline-run-info-backtick-span, "
    "script-html-block, div-html-block-to-EOF, "
    "multiline-code-span, type-7-html-block, whole-line-closer-code-span, "
    "escaped-backtick-html-comment, type-7-quoted-angle-bracket, "
    "unicode-whitespace-fence-close, multiline-inline-html-tag, "
    "invalid-tag-before-comment, double-backslash-comment, "
    "comment-synthesis, span-synthesis, "
    "multiline-link-title, unterminated-quoted-tag-wrong-pin, "
    "escaped-link-title-delimiter, unterminated-link-title-wrong-pin, "
    "escaped-close-paren-link-title, escaped-open-paren-link-title, "
    "blank-line-closed-link-title-wrong-pin); "
    "positive gates: baseline, fenced-literal-unclosed-HTML-comment, "
    "html-comment-in-1bt-code-span, html-comment-in-2bt-code-span, "
    "after-closed-script-block, after-blank-line-div-block, "
    "after-closed-multiline-span, after-blank-line-type-7-block, "
    "whitespace-blank-type-6, whitespace-blank-type-7, "
    "same-line-opener-closer-code-span, "
    "double-backslash-backtick-code-span, after-blank-line-type-7-quoted-angle, "
    "ascii-space-fence-close, after-single-line-inline-html-tag, "
    "valid-inline-tag-within-text, backslash-escaped-comment-opener, "
    "single-line-comment-in-verity-row, "
    "after-multiline-link-title, unterminated-quoted-tag-real-pin, "
    "after-escaped-link-title-delimiter, unterminated-link-title-real-pin, "
    "after-escaped-paren-link-title, blank-line-closed-quoted-title-real-pin, "
    "blank-line-closed-single-quoted-title, blank-line-closed-paren-title, "
    "unescaped-paren-in-paren-title; "
    "checkout identity agree"
)
