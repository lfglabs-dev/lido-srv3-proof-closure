#!/usr/bin/env python3
"""Materialize the canonical ALLOC-2 amendment on a fixed validation base."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[4]
DEST = ROOT.parent / 'temp' / 'alloc2-canonical'
BASE = '924891ed58bbd9f424f298dae57b8982a82aad24'
if not DEST.exists():
    subprocess.run(['git', '-C', str(ROOT), 'worktree', 'add', '--detach', str(DEST), BASE], check=True)
if subprocess.check_output(['git', '-C', str(DEST), 'rev-parse', 'HEAD'], text=True).strip() != BASE:
    raise RuntimeError('unexpected canonical validation base')
paths = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', 'LidoSRv3', 'LidoSRv3.lean', 'lakefile.lean', 'lake-manifest.json', 'lean-toolchain'], text=True).splitlines()
files = {}
for path in paths:
    data = (ROOT / path).read_bytes()
    target = DEST / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    files[path] = hashlib.sha256(data).hexdigest()
(Path(__file__).parent / 'source-identity.json').write_text(json.dumps({'base': BASE, 'files': files}, indent=2)+'\n')
print(f'Materialized {len(files)} canonical sources/configs')
