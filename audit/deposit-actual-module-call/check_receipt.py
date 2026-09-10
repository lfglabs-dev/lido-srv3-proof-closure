#!/usr/bin/env python3
"""Read-only source/artifact hash verification. Does not rerun Lean or solc."""
from pathlib import Path
import hashlib,json
here=Path(__file__).resolve().parent;root=here.parent.parent
receipt=json.loads((here/'receipt.json').read_text())
for name,expected in receipt['artifacts_sha256'].items():
    actual=hashlib.sha256((root/name).read_bytes()).hexdigest()
    assert actual==expected,f'artifact drift: {name}'
for name,item in json.loads((here/'dependency-inputs.json').read_text()).items():
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==item['source_sha256'],name
assert all(c['exit_code']==0 for c in receipt['checks'])
print(f"Receipt hashes valid: {len(receipt['artifacts_sha256'])} artifacts, {receipt['local_imported_sources']} local sources")
