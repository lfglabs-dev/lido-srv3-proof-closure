#!/usr/bin/env python3
"""Fail-closed agreement check for every canonical Verity revision surface."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import NoReturn


VERITY_REPOSITORY = "https://github.com/lfglabs-dev/verity.git"
FULL_REVISION = re.compile(r"[0-9a-f]{40}")


def fail(message: str) -> NoReturn:
    raise ValueError(message)


def strict_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            fail(f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def load_json(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=strict_object)
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"{path} must contain one JSON object")
    return value


def _strip_html_comments(text: str) -> str:
    """Remove HTML comments, skipping backtick code spans (CommonMark §6.1).

    A literal ``<!--`` inside a code span such as ``Literal `<!--` marker`` is code
    content, not an HTML comment opener; the active rendered row following it must
    not be suppressed.  Multiline code spans (opener and closer on different lines)
    have their interior suppressed so that a Verity row inside the span cannot be
    exposed to the caller's regex.

    CommonMark §2.4 backslash escapes: a backtick preceded by an odd number of
    backslashes is a literal character, not a code-span delimiter.  Escaped
    backticks such as ``\\`<!--\\`` do not form a code span, so the ``<!--``
    between them is correctly recognised as an HTML comment opener.

    The same §2.4 rule applies to ``<``: a ``<`` preceded by an odd number of
    backslashes is literal text, so ``\\<!--`` must NOT be treated as an HTML
    comment opener.  The preceding backslash run is counted before entering the
    comment branch, identical to the handling for escaped backticks.

    CommonMark §6.6 inline HTML tags: when scanning an open/close tag, a ``<``
    appearing in attribute position (outside a quoted value) means the tag is not
    a valid CommonMark inline tag.  The scanner aborts and falls back to emitting
    only the initial ``<`` so that subsequent constructs (e.g. ``<!--``) are
    re-scanned and handled correctly.  A quoted attribute value whose closing
    quote is never found before end of text is also treated as invalid: the tag
    is aborted and subsequent content (including a canonical Verity row) is
    re-scanned and emitted normally, matching Markdown's literal rendering of the
    broken construct.

    CommonMark inline links: when a ``](`` construct is encountered, the link
    destination and optional title are scanned.  The title interior (between
    quote or parenthesis delimiters) is suppressed — only newlines are preserved —
    so that a Verity row placed inside a multiline link title cannot match as a
    rendered row.

    Line-boundary invariant: every stripped region (HTML comment, multiline code
    span, link title interior) is replaced by exactly as many ``\\n`` characters
    as the region contained.  This ensures that content on different physical
    source lines remains on different lines in the output and cannot be
    concatenated by stripping into a synthesized ``| Verity | pin |`` row that
    does not exist in the rendered Markdown.
    """
    result: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        if text[i] == "`":
            # CommonMark §2.4: a backtick preceded by an odd number of backslashes
            # is a literal character, not a code-span delimiter.  Count consecutive
            # preceding backslashes; if the count is odd, the backtick is escaped.
            num_bs = 0
            p = i - 1
            while p >= 0 and text[p] == "\\":
                num_bs += 1
                p -= 1
            if num_bs % 2 == 1:
                result.append("`")
                i += 1
                continue
            j = i
            while j < n and text[j] == "`":
                j += 1
            run_len = j - i
            k = j
            while k < n:
                if text[k] == "`":
                    lo = k
                    while lo < n and text[lo] == "`":
                        lo += 1
                    if lo - k == run_len:
                        if "\n" not in text[j:k]:
                            result.append(text[i:lo])
                        else:
                            # Multiline code span: suppress the interior but preserve
                            # physical line boundaries so that content on different
                            # physical lines cannot be concatenated by span removal.
                            result.append("\n" * text[i:lo].count("\n"))
                        i = lo
                        break
                    k = lo
                else:
                    k += 1
            else:
                result.append(text[i:j])
                i = j
        elif text[i : i + 4] == "<!--":
            # CommonMark §2.4: a '<' preceded by an odd number of backslashes is
            # escaped (literal '<'); '<!--' is then NOT an HTML comment opener and
            # must not consume subsequent content.
            num_bs = 0
            p = i - 1
            while p >= 0 and text[p] == "\\":
                num_bs += 1
                p -= 1
            if num_bs % 2 == 1:
                result.append("<")
                i += 1
            else:
                end = text.find("-->", i + 4)
                if end >= 0:
                    # Preserve physical line boundaries: replace the stripped comment
                    # with the same number of newlines it contained so that content on
                    # different physical lines is not concatenated by comment removal.
                    result.append("\n" * text[i : end + 3].count("\n"))
                    i = end + 3
                else:
                    break
        elif text[i] == "<" and i + 1 < n and (text[i + 1].isalpha() or text[i + 1] == "/"):
            # CommonMark §6.6 inline HTML open/close tag: scan through attributes,
            # suppressing any quoted attribute value whose content spans multiple lines.
            # A Verity row placed inside a multiline quoted attribute (e.g.
            # <span title="\n| Verity |…\n">) is raw HTML, not rendered table content.
            j = i + 1
            while j < n and (text[j].isalnum() or text[j] in "-:_/"):
                j += 1
            tag_out: list[str] = [text[i:j]]
            valid = True
            while j < n:
                if text[j] in ('"', "'"):
                    q = text[j]
                    j += 1
                    qs = j
                    while j < n and text[j] != q:
                        j += 1
                    content = text[qs:j]
                    if j < n:
                        j += 1  # skip closing quote
                        tag_out.append(q + ("" if "\n" in content else content) + q)
                    else:
                        # Unterminated quoted attribute: not a valid CommonMark §6.6
                        # inline tag.  Subsequent content (e.g. a canonical Verity row)
                        # must not be suppressed; abort and re-scan from the '<'.
                        valid = False
                        break
                elif text[j] == ">":
                    tag_out.append(">")
                    j += 1
                    break
                elif text[j] == "<":
                    # '<' in attribute position is not valid CommonMark §6.6 inline-tag
                    # grammar; abort so the '<' and any following '<!--' are re-scanned.
                    valid = False
                    break
                else:
                    tag_out.append(text[j])
                    j += 1
            if valid:
                result.extend(tag_out)
                i = j
            else:
                result.append("<")
                i += 1
        elif text[i] == "]" and i + 1 < n and text[i + 1] == "(":
            # CommonMark inline link ](destination "title"): suppress title
            # interior while preserving physical line boundaries so a Verity row
            # embedded in a multiline link title cannot match as a rendered row.
            result.append("](")
            j = i + 2
            # Pass through leading whitespace (preserving newlines)
            while j < n and text[j] in (" ", "\t", "\n"):
                result.append(text[j])
                j += 1
            # Destination: <...> or undelimited (no spaces, balanced parens)
            if j < n and text[j] == "<":
                result.append("<")
                j += 1
                while j < n and text[j] not in (">", "\n"):
                    result.append(text[j])
                    j += 1
                if j < n and text[j] == ">":
                    result.append(">")
                    j += 1
            else:
                depth = 0
                while j < n:
                    c = text[j]
                    if depth == 0 and (c in (" ", "\t", "\n") or c == ")"):
                        break
                    if c == "(":
                        depth += 1
                    elif c == ")":
                        depth -= 1
                    result.append(c)
                    j += 1
            # Whitespace between destination and optional title
            while j < n and text[j] in (" ", "\t", "\n"):
                result.append(text[j])
                j += 1
            # Optional title: suppress interior, preserve newlines only
            if j < n and text[j] in ('"', "'"):
                q = text[j]
                result.append(q)
                j += 1
                while j < n and text[j] != q:
                    if text[j] == "\n":
                        result.append("\n")
                    j += 1
                if j < n:
                    result.append(q)
                    j += 1
            elif j < n and text[j] == "(":
                result.append("(")
                j += 1
                depth = 0
                while j < n:
                    if text[j] == "(":
                        depth += 1
                    elif text[j] == ")":
                        if depth == 0:
                            break
                        depth -= 1
                    if text[j] == "\n":
                        result.append("\n")
                    j += 1
                if j < n:
                    result.append(")")
                    j += 1
            # Skip trailing whitespace before closing ')'
            while j < n and text[j] in (" ", "\t"):
                result.append(text[j])
                j += 1
            # Closing ')'
            if j < n and text[j] == ")":
                result.append(")")
                j += 1
            i = j
        else:
            result.append(text[i])
            i += 1
    return "".join(result)


# CommonMark §4.6 HTML block openers and their end-condition patterns (Types 1, 3–6).
# Type 2 (<!-- … -->) is handled inline by _strip_html_comments; only the block forms
# that _strip_html_comments does not cover need the line-by-line pass below.
_HTML1 = re.compile(
    r"^ {0,3}<(script|pre|style|textarea)(?:[\s>]|$)", re.IGNORECASE
)
_HTML1_END: dict[str, re.Pattern[str]] = {
    "script": re.compile(r"</script>", re.IGNORECASE),
    "pre": re.compile(r"</pre>", re.IGNORECASE),
    "style": re.compile(r"</style>", re.IGNORECASE),
    "textarea": re.compile(r"</textarea>", re.IGNORECASE),
}
_HTML5 = re.compile(r"^ {0,3}<!\[CDATA\[")   # checked before Type 4 (<![)
_HTML5_END = re.compile(r"\]\]>")
_HTML3 = re.compile(r"^ {0,3}<\?")
_HTML3_END = re.compile(r"\?>")
_HTML4 = re.compile(r"^ {0,3}<![A-Z]")
_HTML4_END = re.compile(r">")
_HTML6 = re.compile(
    r"^ {0,3}</?(?:"
    r"address|article|aside|base|basefont|blockquote|body|caption|center|"
    r"col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|"
    r"figure|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|"
    r"hr|html|iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|"
    r"ol|optgroup|option|p|param|search|section|summary|table|tbody|td|"
    r"tfoot|th|thead|title|tr|track|ul"
    r")(?:[\s>]|/>|$)",
    re.IGNORECASE,
)
# Type 7: any other open/close tag on a line by itself (blank-line-terminated).
# Uses the full CommonMark §4.6 attribute grammar so that quoted attribute values
# containing ">" are recognised (e.g. title="a > b").  Attribute values may be
# double-quoted ("[^"]*"), single-quoted ('[^']*'), or unquoted (no whitespace,
# quotes, =, <, >, or backtick).
_HTML7 = re.compile(
    r"^ {0,3}"
    r"</?[A-Za-z][A-Za-z0-9-]*"
    r'(?:\s+[A-Za-z_:][A-Za-z0-9_.:-]*(?:\s*=\s*(?:[^"\'=<>`\x00-\x1f\s]+|"[^"]*"|\'[^\']*\'))?)*'
    r"\s*/?>[ \t]*$"
)


def _strip_non_rendered(text: str) -> str:
    """Remove CommonMark fenced code blocks, HTML blocks, then HTML comments.

    Processing order: fenced code blocks (§4.5) → HTML blocks (§4.6) → HTML
    comments (§4.6 Type 2, handled inline by _strip_html_comments).  Each layer
    is stripped before the next so that a ``<!--`` inside a fence is not treated
    as a comment opener, and HTML block contents are suppressed before comment
    scanning.

    Fenced-block rules (CommonMark §4.5):
    - opener: 0–3 spaces of indentation, then 3+ identical `` ` `` or ``~`` chars
    - closer: same character, at least as many chars as the opener, optional trailing space
    - unclosed fence: extends to EOF
    For backtick openers whose info string contains a backtick, CommonMark treats the
    run as a code-span opener (§6.1) rather than a fence opener.  Code-span closers
    must have the same exact length as their opener (not merely ≥), and may appear
    anywhere on a line (not only occupying a whole line), so the fence ``{N,}``
    closer rule and the whole-line anchor both do not apply.  If no exact-length
    closer is found before EOF the code span is unmatched, the opener is literal,
    and all enclosed lines are restored as rendered content.

    HTML block rules (CommonMark §4.6, Types 1, 3–7):
    - Type 1: ``<script|pre|style|textarea>`` … ``</tag>``
    - Type 3: ``<?`` … ``?>``
    - Type 4: ``<!UPPER`` … ``>``
    - Type 5: ``<![CDATA[`` … ``]]>``
    - Type 6: block-level open/close tag … blank line
    - Type 7: any other open/close tag alone on a line … blank line
    The opener line and all lines up to and including the end-condition line are
    suppressed.  For blank-line-terminated blocks (Types 6–7) the blank line itself
    is not part of the block; CommonMark defines a blank line as containing only
    spaces and tabs, not merely the empty string.  Type 2 (``<!-- … -->``) is
    handled separately by _strip_html_comments, which correctly skips code-span
    content, including multiline code spans whose interior spans multiple lines.
    """
    out: list[str] = []
    in_fence = False
    fence_char = ""
    fence_min_len = 0
    is_code_span = False
    code_span_buffer: list[str] = []
    in_html_block = False
    html_block_end: "re.Pattern[str] | None" = None  # None = blank-line-terminated (Type 6)
    for line in text.splitlines(keepends=True):
        stripped = line.rstrip("\r\n")
        if in_fence:
            if is_code_span:
                # CommonMark §6.1: the closer is an exact-length backtick run and
                # may appear anywhere on the line, not only as a whole-line match.
                closes = re.search(
                    r"(?<!"
                    + re.escape(fence_char)
                    + r")"
                    + re.escape(fence_char)
                    + r"{"
                    + str(fence_min_len)
                    + r"}(?!"
                    + re.escape(fence_char)
                    + r")",
                    stripped,
                )
                if closes:
                    remainder = line[closes.end():]
                    if remainder.strip("\r\n"):
                        out.append(remainder)
                    in_fence = False
                    is_code_span = False
                    code_span_buffer = []
                else:
                    code_span_buffer.append(line)
            else:
                if re.match(
                    r"^ {0,3}" + re.escape(fence_char) + r"{" + str(fence_min_len) + r",}[ ]*$",
                    stripped,
                ):
                    in_fence = False
        elif in_html_block:
            if html_block_end is None:
                # Type 6/7: blank-line-terminated; blank line ends the block but is
                # not itself part of it.  CommonMark defines a blank line as one
                # containing only spaces and tabs (not merely the empty string).
                if not stripped.strip():
                    in_html_block = False
                    out.append(line)
            elif html_block_end.search(stripped):
                # Types 1, 3–5: closing line is consumed by the block.
                in_html_block = False
        else:
            m = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)", stripped)
            if m:
                fence_char = m.group(1)[0]
                fence_min_len = len(m.group(1))
                # Backtick opener with a backtick in its info string is not a valid
                # fence opener (§4.5); it forms a code span (§6.1) whose closer must
                # be the exact same backtick-run length, not merely ≥.
                is_code_span = fence_char == "`" and "`" in m.group(2)
                if is_code_span:
                    # §6.1: if the exact-length closer already appears on the opener
                    # line (in the info string / remaining text), the code span opens
                    # and closes on the same line; treat the line as rendered content.
                    closes_on_opener = re.search(
                        r"(?<!" + re.escape(fence_char) + r")"
                        + re.escape(fence_char) + r"{" + str(fence_min_len) + r"}(?!"
                        + re.escape(fence_char) + r")",
                        m.group(2),
                    )
                    if closes_on_opener:
                        out.append(line)
                        is_code_span = False
                    else:
                        code_span_buffer = [line]
                        in_fence = True
                else:
                    in_fence = True
            else:
                # CommonMark §4.6 HTML block detection (Types 1, 3–7).
                # Opener line is always suppressed; if the end condition is also met
                # on the opener line the block closes immediately without entering
                # the in_html_block state.
                m1 = _HTML1.match(stripped)
                if m1:
                    tag = m1.group(1).lower()
                    end_re = _HTML1_END[tag]
                    if not end_re.search(stripped):
                        in_html_block = True
                        html_block_end = end_re
                elif _HTML5.match(stripped):
                    if not _HTML5_END.search(stripped):
                        in_html_block = True
                        html_block_end = _HTML5_END
                elif _HTML3.match(stripped):
                    if not _HTML3_END.search(stripped):
                        in_html_block = True
                        html_block_end = _HTML3_END
                elif _HTML4.match(stripped):
                    if not _HTML4_END.search(stripped):
                        in_html_block = True
                        html_block_end = _HTML4_END
                elif _HTML6.match(stripped):
                    in_html_block = True
                    html_block_end = None
                elif _HTML7.match(stripped):
                    in_html_block = True
                    html_block_end = None
                else:
                    out.append(line)
    # Unmatched code span: the opener was literal in CommonMark; restore all lines.
    if in_fence and is_code_span:
        out.extend(code_span_buffer)
    return _strip_html_comments("".join(out))


def check(root: Path) -> str:
    lakefile = (root / "lakefile.lean").read_text(encoding="utf-8")
    requests = re.findall(
        r'^\s*require\s+verity\s+from\s+git\s*\n\s*"([^"\n]+)"@"([^"\n]+)"\s*$',
        lakefile,
        re.MULTILINE,
    )
    if len(requests) != 1:
        fail("lakefile.lean must contain exactly one canonical Verity git request")
    requested_repository, requested_revision = requests[0]
    if requested_repository != VERITY_REPOSITORY:
        fail(f"lakefile Verity repository differs: {requested_repository!r}")
    if FULL_REVISION.fullmatch(requested_revision) is None:
        fail(f"lakefile Verity request is not an exact 40-hex revision: {requested_revision!r}")

    manifest = load_json(root / "lake-manifest.json")
    packages = manifest.get("packages")
    if not isinstance(packages, list):
        fail("lake-manifest.json packages must be a list")
    resolved = [package for package in packages if isinstance(package, dict) and package.get("name") == "verity"]
    if len(resolved) != 1:
        fail("lake-manifest.json must contain exactly one Verity package")
    package = resolved[0]
    expected_package = {
        "url": requested_repository,
        "type": "git",
        "rev": requested_revision,
        "inputRev": requested_revision,
        "inherited": False,
        "configFile": "lakefile.lean",
    }
    for key, expected in expected_package.items():
        if package.get(key) != expected:
            fail(f"lake-manifest Verity {key} {package.get(key)!r} differs from requested {expected!r}")

    lock = load_json(root / "audit/artifacts.lock.json")
    lock_pin = ((lock.get("pins") or {}).get("verity") if isinstance(lock.get("pins"), dict) else None)
    if lock_pin != {"repository": requested_repository, "commit": requested_revision}:
        fail("artifact-lock Verity pin differs from the lakefile request")

    audit_manifest = load_json(root / "verity/targets/audit-manifest.json")
    revisions = audit_manifest.get("source_revisions")
    audit_revision = revisions.get("verity") if isinstance(revisions, dict) else None
    if audit_revision != requested_revision:
        fail("audit-manifest Verity revision differs from the lakefile request")

    legacy_source_map = load_json(root / "verity/targets/source-map.json")
    source_revisions = legacy_source_map.get("source_revisions")
    source_map_revision = source_revisions.get("verity_commit") if isinstance(source_revisions, dict) else None
    if source_map_revision != requested_revision:
        fail("source-map Verity revision differs from the lakefile request")

    lockfile_text = (root / "proofs/LOCKFILE.md").read_text(encoding="utf-8")
    # Use [ \t]* instead of \s* so the match is confined to a single physical line;
    # \s* would match \n and allow stripped regions to be bridged across line boundaries.
    lockfile_matches = re.findall(r"^\|[ \t]*Verity[ \t]*\|[ \t]*`([0-9a-f]{40})`[ \t]*\|", _strip_non_rendered(lockfile_text), re.MULTILINE)
    if len(lockfile_matches) != 1:
        fail("proofs/LOCKFILE.md must contain exactly one Verity pin row")
    if lockfile_matches[0] != requested_revision:
        fail(f"proofs/LOCKFILE.md Verity pin {lockfile_matches[0]!r} differs from the lakefile request")

    checkout = root / ".lake/packages/verity"
    if not checkout.is_dir():
        fail(f"resolved Verity checkout {checkout} not found")
    result = subprocess.run(
        ["git", "-C", str(checkout), "rev-parse", "HEAD"],
        text=True, capture_output=True, check=False,
    )
    if result.returncode != 0 or FULL_REVISION.fullmatch(result.stdout.strip()) is None:
        fail("could not read an exact resolved Verity checkout revision")
    checkout_revision = result.stdout.strip()
    if checkout_revision != requested_revision:
        fail(f"resolved Verity checkout revision {checkout_revision!r} differs from requested {requested_revision!r}")
    dirty = subprocess.run(
        ["git", "-C", str(checkout), "status", "--porcelain", "--untracked-files=all"],
        text=True, capture_output=True, check=False,
    )
    if dirty.returncode != 0 or dirty.stdout:
        fail("resolved Verity checkout is dirty or unreadable")
    return requested_revision


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    try:
        revision = check(args.root.resolve())
    except (OSError, ValueError) as exc:
        print(f"Verity provenance check failed: {exc}", file=sys.stderr)
        return 1
    print(revision)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
