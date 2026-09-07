#!/usr/bin/env python3
"""Isolate physical byte primitives without changing the queued runtime manifest."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[4]
DEST = ROOT.parent / 'temp' / 'alloc2-bytes'
BASE = 'c7adae04416704a839d56333efad003f0a0f46b7'
PRODUCER = '8691c7881a863715ab5ec9b39631ab41243e7c91'
if not DEST.exists():
    subprocess.run(['git', '-C', str(ROOT), 'worktree', 'add', '--detach', str(DEST), BASE], check=True)
if subprocess.check_output(['git', '-C', str(DEST), 'rev-parse', 'HEAD'], text=True).strip() != BASE:
    raise RuntimeError('unexpected verification base')
sources = {}
for name in ('Interface', 'Storage', 'Execution', 'Properties', 'Bytes', 'Memory', 'AllocationMemory'):
    path = f'LidoSRv3/Audit/Source/TrioAlloc1/{name}.lean'
    sources[path] = subprocess.check_output(['git', '-C', str(ROOT), 'show', f'{PRODUCER}:{path}'])
for source in sorted(ROOT.glob('LidoSRv3/Audit/Source/TrioAlloc2/*.lean')):
    sources[str(source.relative_to(ROOT))] = source.read_bytes()
for path in ('audit/trio/alloc2/composition/Composition.lean', 'audit/trio/alloc2/composition/MemoryWrite.lean', 'audit/trio/alloc2/composition/IndexedMemory.lean', 'audit/trio/alloc2/composition/ByteMemory.lean', 'audit/trio/alloc2/composition/ByteIndexed.lean', 'audit/trio/alloc2/composition/ByteVectors.lean', 'audit/trio/alloc2/byte-memory/lakefile.lean'):
    sources[path] = (ROOT / path).read_bytes()
for path, data in sources.items():
    target = DEST / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
(Path(__file__).parent / 'source-identity.json').write_text(json.dumps({
    'base': BASE, 'producer': PRODUCER,
    'files': {path: hashlib.sha256(data).hexdigest() for path, data in sorted(sources.items())},
}, indent=2) + '\n')
print(f'Materialized {len(sources)} source/config files at {DEST}')
