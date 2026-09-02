#!/usr/bin/env python3
"""Negative regressions for the Python complexity and file-length ratchet."""

from __future__ import annotations

import contextlib
import io
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import check_python_quality  # noqa: E402  (sibling module, located above)

DENSE = "def dense(x):\n    return " + " or ".join(f"x == {n}" for n in range(24)) + "\n"


def invoke(*argv: str) -> tuple[bool, str]:
    out = io.StringIO()
    saved = sys.argv
    sys.argv = ["check_python_quality.py", *argv]
    try:
        with contextlib.redirect_stdout(out):
            check_python_quality.main()
        return True, out.getvalue()
    except SystemExit as stop:
        return False, f"{stop}"
    finally:
        sys.argv = saved


def expect(succeeds: bool, diagnostic: str, *argv: str) -> None:
    ok, text = invoke(*argv)
    if ok != succeeds:
        raise SystemExit(f"unexpected result ({ok}) for {argv}: {text}")
    if diagnostic not in text:
        raise SystemExit(f"missing diagnostic {diagnostic!r}: {text}")


def check_pinned_tree(fixture: Path) -> None:
    """A verbatim copy of scripts/ and the baseline passes; touching the baseline fails."""
    shutil.copytree(ROOT / "scripts", fixture / "scripts")
    (fixture / "audit").mkdir()
    baseline = fixture / "audit/python-quality-baseline.txt"
    shutil.copy2(ROOT / "audit/python-quality-baseline.txt", baseline)
    expect(True, "python-quality ok", "--root", str(fixture))
    original = baseline.read_text(encoding="utf-8")
    baseline.write_text(original + "# bypass\n", encoding="utf-8")
    expect(False, "does not match pinned blob", "--root", str(fixture))
    baseline.write_text(original, encoding="utf-8")


def check_ratchet(fixture: Path) -> None:
    scripts = fixture / "scripts"
    override = fixture / "override.txt"
    shutil.copy2(fixture / "audit/python-quality-baseline.txt", override)
    args = ("--root", str(fixture), "--baseline", str(override))
    expect(True, "python-quality ok", *args)

    dense = scripts / "zz_dense.py"
    dense.write_text(DENSE, encoding="utf-8")
    expect(False, "zz_dense.py:dense = 24, limit 22, and it is not baseline debt", *args)
    long = scripts / "zz_long.py"
    long.write_text("# pad\n" * 501, encoding="utf-8")
    dense.unlink()
    expect(False, "zz_long.py = 501, limit 500, and it is not baseline debt", *args)
    long.unlink()

    rows = override.read_text(encoding="utf-8")
    override.write_text(rows.replace("audit_metadata.py:rendered 30", "audit_metadata.py:rendered 29"), encoding="utf-8")
    expect(False, "audit_metadata.py:rendered = 30 grew past its baseline 29", *args)
    override.write_text(rows + "zz_gone.py:missing 40\n", encoding="utf-8")
    expect(False, "baseline row zz_gone.py:missing names nothing in scripts/; delete it and re-pin", *args)
    override.write_text(rows + "check_import_dag.py:layer_of 30\n", encoding="utf-8")
    expect(False, "check_import_dag.py:layer_of = 18 is under the limit; delete its baseline row and re-pin", *args)
    override.write_text(rows + "malformed row here\n", encoding="utf-8")
    expect(False, "expected `<file>[:<function>] <value>`", *args)
    override.unlink()
    expect(False, "missing baseline", *args)

    written = fixture / "written.txt"
    expect(True, "pin BASELINE_BLOB =", "--root", str(fixture), "--baseline", str(written), "--write-baseline")
    if written.read_text(encoding="utf-8") != rows:
        raise SystemExit("--write-baseline did not reproduce the checked-in baseline")


def check_metric() -> None:
    import ast
    source = ("def f(a, b):\n    if a and b:\n        return [x for x in a if x]\n"
              "    for _ in b:\n        pass\n    while a:\n        a = a if b else 0\n"
              "    try:\n        pass\n    except ValueError:\n        pass\n"
              "    match a:\n        case 1:\n            pass\n        case _:\n            pass\n"
              "    with open(b):\n        pass\n    assert a\n    return 0\n")
    (function,) = ast.parse(source).body
    if check_python_quality.complexity(function) != 13:
        raise SystemExit(f"complexity metric drifted: {check_python_quality.complexity(function)}")


with tempfile.TemporaryDirectory() as tmp:
    fixture = Path(tmp)
    check_pinned_tree(fixture)
    check_ratchet(fixture)
check_metric()
print("python-quality mutants ok: pinned baseline, new dense function, new long script, growth "
      "past baseline, stale row, retired-but-listed row, malformed row, missing baseline, "
      "baseline rewrite, and the branch metric")
