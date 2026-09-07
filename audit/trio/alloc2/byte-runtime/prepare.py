#!/usr/bin/env python3
"""Materialize the byte denotation bridge without changing other live manifests."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[4]
DEST = ROOT.parent / 'temp' / 'alloc2-byte-runtime'
BASE = 'c7adae04416704a839d56333efad003f0a0f46b7'
VERITY = 'e977aaad6e1a9e92e0132d41b3d33a14135a4d46'
if not DEST.exists():
    subprocess.run(['git', '-C', str(ROOT), 'worktree', 'add', '--detach', str(DEST), BASE], check=True)
if subprocess.check_output(['git', '-C', str(DEST), 'rev-parse', 'HEAD'], text=True).strip() != BASE:
    raise RuntimeError('unexpected verification base')
identity = json.loads((ROOT / 'audit/trio/alloc2/byte-memory/source-identity.json').read_text())
sources = {}
for path, expected in identity['files'].items():
    data = (subprocess.check_output(['git', '-C', str(ROOT), 'show', f"{identity['producer']}:{path}"])
            if '/TrioAlloc1/' in path else (ROOT / path).read_bytes())
    if hashlib.sha256(data).hexdigest() != expected:
        raise RuntimeError('stale byte source identity: '+path)
    sources[path] = data
for path in ('audit/trio/alloc2/runtime/ByteMemory.lean', 'audit/trio/alloc2/runtime/ByteLoop.lean', 'audit/trio/alloc2/runtime/ByteInitialize.lean', 'audit/trio/alloc2/runtime/ByteVectors.lean', 'audit/trio/alloc2/runtime/ByteCoverage.lean', 'audit/trio/alloc2/byte-runtime/lakefile.lean', 'audit/trio/alloc2/byte-runtime/lake-manifest.json'):
    sources[path] = (ROOT / path).read_bytes()
for path, data in sources.items():
    target = DEST / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
(Path(__file__).parent / 'source-identity.json').write_text(json.dumps({
    'base': BASE, 'producer': identity['producer'], 'verity': VERITY,
    'files': {path: hashlib.sha256(data).hexdigest() for path, data in sorted(sources.items())},
}, indent=2) + '\n')
print(f'Materialized {len(sources)} source/config files at {DEST}')
