#!/usr/bin/env python3
"""Check the canonical remote build against the current source identity."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[4]
identity = json.loads(Path(__file__).with_name('source-identity.json').read_text())
receipt = json.loads(Path(sys.argv[1]).read_text())
if receipt['state'] != 'succeeded' or receipt['exit_code'] != 0:
    raise SystemExit('canonical build did not succeed')
submission = json.loads(Path(__file__).with_name('submission.json').read_text())
validation = receipt['validation']
if submission['job_id'] != receipt['job_id'] or submission['validation'] != validation:
    raise SystemExit('remote receipt differs from recorded submission')
expected_command = ['lake', 'build', 'LidoSRv3', 'LidoSRv3Test', 'LidoSRv3Audit']
if validation['command'] != expected_command or validation['commit'] != identity['base']:
    raise SystemExit('wrong canonical build command/base')
if validation['toolchain'] != 'leanprover/lean4:v4.31.0':
    raise SystemExit('wrong canonical toolchain')
manifest = hashlib.sha256(b'sandboxed-source-bundle-v1\n')
changed = []
for path, expected in sorted(identity['files'].items()):
    data = (ROOT / path).read_bytes()
    if hashlib.sha256(data).hexdigest() != expected:
        raise SystemExit('stale canonical source: '+path)
    baseline = subprocess.check_output(['git', '-C', str(ROOT), 'show', f"{identity['base']}:{path}"])
    if baseline != data:
        manifest.update(path.encode()+b'\0'+expected.encode()+b'\n')
        changed.append(path)
if submission['source_bundle_sha256'] != manifest.hexdigest():
    raise SystemExit('canonical source overlay mismatch')
print(json.dumps({'job': receipt['job_id'], 'source_overlay': manifest.hexdigest(),
                  'canonical_files': len(identity['files']), 'amended_files': changed,
                  'command': expected_command}, indent=2))
