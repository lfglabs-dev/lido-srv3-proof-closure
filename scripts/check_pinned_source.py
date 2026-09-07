#!/usr/bin/env python3
"""Check that every Solidity line cited by the audit exists in the pinned lidofinance/core commit.

What this script establishes (stdlib only, no stored hashes, runs offline once the
`lido-core` submodule is present):

  1. PIN CONSISTENCY  - `audit/source-map.yaml` declares one `pinned_source`
     (lidofinance/core@<sha>). Every span permalink / `source_sha` in that file must
     name the same sha, and the `lido-core` git submodule must be checked out at it.
  2. SOURCE SPANS     - every span in `audit/source-map.yaml` (path + start/end line)
     must exist in `lido-core/`; the first line of each span is printed so a
     reviewer can eyeball it against the cited function name.
  3. INLINE CITATIONS - `LidoSRv3/Audit/**/*.lean`, `report/*.md` and
     `diagram/README.md` are scanned for `<File>.sol:<line>` / `<File>.sol:<a>-<b>`
     citations. Each is resolved to a unique file under `lido-core/contracts`
     (ambiguous basenames are reported) and the line range must exist. When an
     identifier in backticks precedes the citation on the same line (for example
     `` `preservesEthBalance` modifier (`WithdrawalVault.sol:81--85`) ``) the
     identifier must occur inside the cited range; a miss is reported as `ident?`
     (fatal only with --strict, because the association is heuristic).
  4. RELEASE LINK     - the pinned sha must be reachable from tag `v4.0.0` of
     lidofinance/core (the tag is fetched into the submodule if absent) and
     `git diff --stat <pin> v4.0.0 -- contracts` is printed so the reviewer sees
     which contract files, if any, differ between the pin and the release.

Exit status: 0 when everything matches, 1 on any mismatch, 2 when a prerequisite is
missing (no submodule, unreadable source map).

Usage:
    python3 scripts/check_pinned_source.py [--strict] [--repo-root DIR] [--no-fetch]
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

RELEASE_TAG = "v4.0.0"
CITATION_RE = re.compile(
    r"(?P<path>(?:[A-Za-z0-9_./-]*/)?)(?P<file>[A-Za-z0-9_]+\.sol):(?P<a>\d+)(?:(?:-|--|–|—)(?P<b>\d+))?"
)
IDENT_RE = re.compile(r"`([A-Za-z_][A-Za-z0-9_]*)`")
SHA_RE = re.compile(r"[0-9a-f]{40}")


def git(root: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(root / "lido-core"), *args],
        check=True, capture_output=True, text=True,
    ).stdout.strip()


def load_source_map(root: Path) -> dict:
    return json.loads((root / "audit" / "source-map.yaml").read_text(encoding="utf-8"))


DECL_RE = r"\b(function|modifier|struct|event|error|contract|library|interface|enum)\s+%s\b"


def ident_in_or_encloses(lines: list[str], a: int, b: int, ident: str) -> tuple[bool, str]:
    """True if `ident` occurs in lines a..b, or is declared (function/modifier/struct/...)
    at most 80 lines above `a` so that the cited range plausibly sits inside its body."""
    word = r"\b" + re.escape(ident) + r"\b"
    if re.search(word, "\n".join(lines[a - 1:b])):
        return True, f" (`{ident}` in range)"
    decl = re.compile(DECL_RE % re.escape(ident))
    for i in range(a - 2, max(-1, a - 82), -1):
        if decl.search(lines[i]):
            return True, f" (`{ident}` declared at line {i + 1}, encloses range)"
    return False, ""


def read_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8", errors="replace").splitlines()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo-root", default=str(Path(__file__).resolve().parent.parent))
    ap.add_argument("--strict", action="store_true", help="treat missing backtick identifiers as failures")
    ap.add_argument("--no-fetch", action="store_true", help="never touch the network (tag must already be local)")
    args = ap.parse_args()
    root = Path(args.repo_root)
    failures: list[str] = []
    warnings: list[str] = []

    core = root / "lido-core"
    if not (core / "contracts").is_dir():
        print(f"ERROR: {core} has no contracts/ directory. Run: git submodule update --init lido-core")
        return 2
    try:
        smap = load_source_map(root)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: cannot read audit/source-map.yaml: {exc}")
        return 2

    # ---- 1. pin consistency ---------------------------------------------------------
    pinned = smap["pinned_source"]
    m = SHA_RE.search(pinned)
    if not m:
        print(f"ERROR: pinned_source has no 40-hex sha: {pinned!r}")
        return 2
    pin = m.group(0)
    head = git(root, "rev-parse", "HEAD")
    print("== 1. Pin consistency")
    print(f"  source-map pinned_source : {pinned}")
    print(f"  lido-core submodule HEAD : {head}")
    if head != pin:
        failures.append(f"submodule HEAD {head} != pinned {pin}")
        print("  MISMATCH: submodule is not checked out at the pin")
    else:
        print("  ok: submodule HEAD equals pin")

    spans = []
    for target in smap.get("targets", []):
        for span in target.get("spans", []):
            spans.append((target.get("id", "?"), span))
    bad_sha = 0
    for tid, span in spans:
        for key in ("source_sha", "permalink"):
            val = span.get(key, "")
            if pin not in val:
                bad_sha += 1
                failures.append(f"{tid}: {key} does not reference pin: {val}")
    print(f"  spans: {len(spans)}; spans whose source_sha/permalink differ from pin: {bad_sha}")

    # ---- 2. source-map spans -------------------------------------------------------
    print("\n== 2. Source-map spans (first line of each span)")
    for tid, span in spans:
        rel = span["path"]
        a, b = int(span["start_line"]), int(span.get("end_line", span["start_line"]))
        f = core / rel
        label = f"  {tid:<22} {rel}:{a}-{b}"
        if not f.is_file():
            failures.append(f"{tid}: missing file {rel}")
            print(f"{label}  MISSING FILE")
            continue
        lines = read_lines(f)
        if not (1 <= a <= b <= len(lines)):
            failures.append(f"{tid}: range {a}-{b} outside {rel} ({len(lines)} lines)")
            print(f"{label}  RANGE OUT OF FILE ({len(lines)} lines)")
            continue
        # `function` is a human label ("allocate outer loop", "isType2(uint256)"):
        # only its leading identifier is checked, against the range or its enclosing declaration.
        fn = span.get("function") or ""
        fm = re.match(r"[A-Za-z_][A-Za-z0-9_]*", fn)
        fn_ok, fn_note = True, ""
        if fm:
            fn_ok, fn_note = ident_in_or_encloses(lines, a, b, fm.group(0))
            if not fn_ok:
                warnings.append(f"{tid}: function label {fn!r} not found in/around {rel}:{a}-{b}")
        print(f"{label}  ok{fn_note if fn_ok else ' (fn?)'}  | {lines[a - 1].strip()[:90]}")

    # ---- 3. inline citations -------------------------------------------------------
    print("\n== 3. Inline citations in Lean sources, reports and diagram README")
    by_basename: dict[str, list[Path]] = {}
    for p in (core / "contracts").rglob("*.sol"):
        by_basename.setdefault(p.name, []).append(p)
    scan_files = sorted((root / "LidoSRv3" / "Audit").rglob("*.lean"))
    scan_files += sorted((root / "report").glob("*.md"))
    if (root / "diagram" / "README.md").is_file():
        scan_files.append(root / "diagram" / "README.md")

    rows: list[tuple[str, str, str, str]] = []
    seen: set[tuple[str, str]] = set()
    for sf in scan_files:
        for lineno, text in enumerate(read_lines(sf), 1):
            for cm in CITATION_RE.finditer(text):
                cite = cm.group(0)
                where = f"{sf.relative_to(root)}:{lineno}"
                # identifier in backticks preceding the citation on the same line
                prefix = text[: cm.start()]
                idents = IDENT_RE.findall(prefix)
                ident = idents[-1] if idents and (cm.start() - prefix.rfind("`" + idents[-1] + "`")) <= 80 else None
                key = (cite, ident or "")
                if key in seen:
                    continue
                seen.add(key)
                # resolve the file
                if cm.group("path") and cm.group("path").startswith("contracts/"):
                    cands = [core / (cm.group("path") + cm.group("file"))]
                    cands = [c for c in cands if c.is_file()]
                else:
                    cands = by_basename.get(cm.group("file"), [])
                if len(cands) != 1:
                    status = "NO FILE" if not cands else "AMBIGUOUS " + ", ".join(str(c.relative_to(core)) for c in cands)
                    failures.append(f"{where}: {cite}: {status}")
                    rows.append((cite, "-", status, where))
                    continue
                f = cands[0]
                rel = str(f.relative_to(core))
                a = int(cm.group("a"))
                b = int(cm.group("b") or a)
                lines = read_lines(f)
                if not (1 <= a <= b <= len(lines)):
                    failures.append(f"{where}: {cite}: range outside file ({len(lines)} lines)")
                    rows.append((cite, rel, f"RANGE OUT OF FILE ({len(lines)} lines)", where))
                    continue
                status = "ok"
                if ident:
                    ok_i, note = ident_in_or_encloses(lines, a, b, ident)
                    if ok_i:
                        status = "ok" + note
                    else:
                        status = f"ident? `{ident}` not in range"
                        msg = f"{where}: {cite}: identifier {ident!r} not within cited lines"
                        (failures if args.strict else warnings).append(msg)
                rows.append((cite, rel, status, where))
    w0 = max((len(r[0]) for r in rows), default=8)
    w1 = max((len(r[1]) for r in rows), default=4)
    print(f"  {'citation':<{w0}}  {'file (lido-core/)':<{w1}}  status  [first occurrence]")
    for cite, rel, status, where in sorted(rows):
        print(f"  {cite:<{w0}}  {rel:<{w1}}  {status}  [{where}]")
    print(f"  citations checked: {len(rows)}")

    # ---- 4. release link -----------------------------------------------------------
    print(f"\n== 4. Release link: is the pin part of {RELEASE_TAG}?")
    try:
        try:
            tag_commit = git(root, "rev-parse", f"{RELEASE_TAG}^{{commit}}")
        except subprocess.CalledProcessError:
            if args.no_fetch:
                raise
            print(f"  fetching tag {RELEASE_TAG} from origin ...")
            subprocess.run(["git", "-C", str(core), "fetch", "-q", "origin", "tag", RELEASE_TAG],
                           check=True, capture_output=True, text=True)
            tag_commit = git(root, "rev-parse", f"{RELEASE_TAG}^{{commit}}")
        print(f"  {RELEASE_TAG} -> {tag_commit}")
        anc = subprocess.run(["git", "-C", str(core), "merge-base", "--is-ancestor", pin, tag_commit])
        if anc.returncode != 0:
            failures.append(f"pin {pin} is not an ancestor of {RELEASE_TAG}")
            print(f"  MISMATCH: pin is not reachable from {RELEASE_TAG}")
        elif tag_commit == pin:
            print(f"  ok: {RELEASE_TAG} points exactly at the pin")
        else:
            print(f"  ok: pin is an ancestor of {RELEASE_TAG}")
        stat = git(root, "diff", "--stat", pin, tag_commit, "--", "contracts")
        print("  git diff --stat <pin> v4.0.0 -- contracts:")
        print("    (no differences)" if not stat else "\n".join("    " + l for l in stat.splitlines()))
    except subprocess.CalledProcessError as exc:
        warnings.append(f"could not resolve tag {RELEASE_TAG}: {exc.stderr or exc}")
        print(f"  UNCHECKED: tag {RELEASE_TAG} unavailable ({(exc.stderr or str(exc)).strip()})")

    # ---- summary -------------------------------------------------------------------
    print("\n== Summary")
    for w in warnings:
        print(f"  warning: {w}")
    for f in failures:
        print(f"  FAIL: {f}")
    if failures:
        print(f"  RESULT: {len(failures)} mismatch(es)")
        return 1
    print(f"  RESULT: all checks passed ({len(warnings)} warning(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())
