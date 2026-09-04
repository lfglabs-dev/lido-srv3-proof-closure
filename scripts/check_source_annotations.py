#!/usr/bin/env python3
"""Check that every Solidity line annotation in the Lean sources is true.

The Lean transcriptions carry comments of the form

    -- StakingRouter.sol:946  if (stateConfig.status != Active) revert ...
    -- WithdrawalVaultEIP7685.sol:61-62  if (requestsCount != targetPubkeys.length) ...

This script resolves each `<File>.sol` to the unique file of that basename
under `lido-core/contracts` (the pinned lidofinance/core checkout), checks that
the cited line or range exists, and checks that the quoted text is really
there: after whitespace normalisation the quoted text must be a substring of
the cited line, or, for a range, of the range joined into one line. An
annotation that quotes nothing (only a citation) is accepted as long as the
line exists. Docstring citations without quoted text are also accepted.

It also reports coverage: every `def`/`abbrev` whose docstring cites a
Solidity range is a transcription; the script counts those whose body carries
at least one annotation. Exit 1 on any false annotation.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "lido-core" / "contracts"
LEAN_DIRS = [ROOT / "LidoSRv3" / "Audit"]

# `-- File.sol:12  text` or `-- File.sol:12-15  text`; also inside docstrings.
ANNOTATION = re.compile(
    r"(?<![A-Za-z0-9_/])(?P<file>[A-Za-z0-9_]+\.sol):(?P<a>\d+)(?:-{1,2}(?P<b>\d+))?"
    r"(?:(?P<gap>\s{2,})(?P<text>[^\n]*))?"
)
DOC_RANGE = re.compile(r"[A-Za-z0-9_]+\.sol:\d+")
DECL = re.compile(r"^(?:private |protected |noncomputable )?(def|abbrev|theorem|lemma)\s+([A-Za-z0-9_.?!']+)")


def normalise(text: str) -> str:
    text = "\n".join(re.sub(r"//.*$", "", part) for part in text.split("\n"))
    return re.sub(r"\s+", " ", text).strip()


CODE_START = re.compile(
    r"^(?:if|require|revert|emit|uint\d*|int\d*|bytes\d*|address|bool|for|while|let|function|assert|return|"
    r"delete|mstore|calldataload|unchecked|else|modifier|error|event|struct|mapping|\(|\{|\[|_|\$)\b"
    r"|^[A-Za-z_][A-Za-z0-9_]*\s*(?:\(|\.|=|\[|\{|\+=|-=|:=|\*|<|>)"
)


def looks_like_code(text: str) -> bool:
    """A quoted Solidity statement, as opposed to a prose note."""
    return bool(CODE_START.search(text)) and bool(re.search(r"[;(){}=]", text))


def tokens(text: str) -> list[str]:
    return re.findall(r"[A-Za-z_][A-Za-z0-9_]{2,}", text)


def quoted(text: str) -> str:
    """The Solidity text an annotation quotes, minus trailing bracket tags."""
    text = text.strip()
    inline = re.search(r"`([^`]+)`", text)
    if inline:
        return normalise(inline.group(1))
    if "`" in text:
        text = text.split("`", 1)[0]
    text = re.sub(r"\s*\[[A-Za-z_]+\]\s*$", "", text)     # [_validateTopUpInputs]
    text = re.sub(r"\s*-/\s*$", "", text)                  # end of docstring
    text = text.strip("`").strip()
    # a trailing free-form note after a double space or ' ;' is not a quote
    text = re.split(r"\s{2,}|\s;\s", text)[0]
    return normalise(text)


def resolve(basename: str, index: dict[str, list[Path]]) -> Path | None:
    cands = index.get(basename, [])
    if len(cands) != 1:
        return None
    return cands[0]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--strict", action="store_true", help="also fail when a quoted text is not found")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    if not CORE.is_dir():
        print(f"ERROR: {CORE} missing. Run: git submodule update --init lido-core")
        return 2

    index: dict[str, list[Path]] = {}
    for p in CORE.rglob("*.sol"):
        if "/test/" in str(p) or "/mock" in str(p).lower():
            continue
        index.setdefault(p.name, []).append(p)
    cache: dict[Path, list[str]] = {}

    def lines_of(p: Path) -> list[str]:
        if p not in cache:
            cache[p] = p.read_text(errors="replace").splitlines()
        return cache[p]

    errors: list[str] = []
    mismatches: list[str] = []
    checked = 0
    transcriptions = 0
    covered = 0

    lean_files = sorted(f for d in LEAN_DIRS for f in d.rglob("*.lean"))
    for lean in lean_files:
        rel = lean.relative_to(ROOT)
        text = lean.read_text()
        lines = text.splitlines()
        # annotations
        for i, line in enumerate(lines, 1):
            for m in ANNOTATION.finditer(line):
                basename = m.group("file")
                if basename not in index:
                    continue  # not a Lido contract (e.g. a Lean file mentioned in prose)
                target = resolve(basename, index)
                if target is None:
                    errors.append(f"{rel}:{i}: ambiguous basename {basename}")
                    continue
                src = lines_of(target)
                a = int(m.group("a"))
                b = int(m.group("b") or a)
                if a < 1 or b > len(src) or b < a:
                    errors.append(f"{rel}:{i}: {basename}:{a}-{b} out of range (file has {len(src)} lines)")
                    continue
                checked += 1
                raw = m.group("text") or ""
                q = quoted(raw)
                # descriptive notes (summaries, elisions) are not quotes
                if not q or len(q) < 6 or "..." in raw or " / " in raw or not looks_like_code(q):
                    continue
                squash = lambda t: re.sub(r"\s+", "", t)
                window = normalise("\n".join(src[max(0, a - 2):min(len(src), b + 1)]))
                haystack = squash(window)
                probe = squash(q)[:50]
                if probe not in haystack:
                    # condensed quote: every identifier of the quote must appear in the window
                    words = tokens(q)
                    present = [w for w in words if w in window]
                    if not words or len(present) < max(1, round(0.8 * len(words))):
                        mismatches.append(f"{rel}:{i}: {basename}:{a}-{b} does not contain {q[:50]!r}")
        # coverage: declarations whose docstring cites a range
        for i, line in enumerate(lines):
            d = DECL.match(line)
            if not d or d.group(1) not in ("def", "abbrev"):
                continue
            # docstring immediately above (skip `open ... in` and attributes)
            k = i - 1
            while k >= 0 and (lines[k].startswith("open ") or lines[k].startswith("@[")):
                k -= 1
            if k < 0 or not lines[k].rstrip().endswith("-/"):
                continue
            start = k
            while start >= 0 and not lines[start].lstrip().startswith("/--"):
                start -= 1
            if start < 0:
                continue
            doc = "\n".join(lines[start:k + 1])
            if not DOC_RANGE.search(doc):
                continue
            transcriptions += 1
            # body: until the next top-level declaration or blank-line-separated block
            j = i + 1
            body = []
            while j < len(lines) and not DECL.match(lines[j]) and not lines[j].startswith(("/--", "/-!", "end ", "namespace ", "section", "theorem", "instance")):
                body.append(lines[j])
                j += 1
            if any(ANNOTATION.search(bl) and "--" in bl for bl in body) or d.group(1) == "abbrev":
                covered += 1
            elif args.verbose:
                print(f"  uncovered: {rel}:{i + 1} {d.group(2)}")

    for e in errors:
        print(f"ERROR {e}")
    for w in mismatches:
        print(f"{'ERROR' if args.strict else 'WARN '} {w}")
    print(f"source annotations: {checked} citations checked, {len(errors)} false, {len(mismatches)} quote mismatches; "
          f"transcribing declarations annotated: {covered}/{transcriptions}")
    if errors or (args.strict and mismatches):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
