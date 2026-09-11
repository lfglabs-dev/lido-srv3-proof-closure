#!/usr/bin/env python3
"""Reuse the existing explicit FFI loader on the repaired diagnostic input."""
from pathlib import Path

OUT = Path(__file__).resolve().parent
loader = OUT.parent / 'run-diagnostics.py'
source = loader.read_text()
old = "'audit/address-request-call/diagnostics.lean'"
assert source.count(old) == 1
source = source.replace(old, "'audit/address-request-call/repair/diagnostics.lean'")
exec(compile(source, str(loader), 'exec'), {'__file__': str(loader), '__name__': '__main__'})
