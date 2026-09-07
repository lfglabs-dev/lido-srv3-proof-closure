#!/usr/bin/env python3
"""Regression for the model-only P-ORACLE-SANITY-1 receipt claim."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CHECKER = ROOT / "scripts/check_validation_receipt.py"

spec = importlib.util.spec_from_file_location("check_validation_receipt", CHECKER)
if spec is None or spec.loader is None:
    raise SystemExit("could not load validation-receipt checker")
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)

with tempfile.TemporaryDirectory() as tmp:
    fixture = Path(tmp)
    receipt = fixture / "audit/validation-receipt.txt"
    receipt.parent.mkdir(parents=True)
    source = (ROOT / "audit/validation-receipt.txt").read_text(encoding="utf-8")
    receipt.write_text(
        source.replace(
            "supplemental guarantee at `[.model]`.",
            "supplemental guarantee at `[.model, .source]`.",
            1,
        ),
        encoding="utf-8",
    )
    checker.ROOT = fixture
    checker.RECEIPT = Path("audit/validation-receipt.txt")
    argv = sys.argv
    try:
        sys.argv = [str(CHECKER)]
        try:
            checker.main()
        except SystemExit as exc:
            if "P-ORACLE-SANITY-1's model-only" not in str(exc):
                raise
        else:
            raise SystemExit("source-layer receipt mutant unexpectedly passed")
    finally:
        sys.argv = argv

print("validation receipt regression ok: P-ORACLE-SANITY-1 source-layer mutant fails closed")
