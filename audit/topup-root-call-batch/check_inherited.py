#!/usr/bin/env python3
"""Identity-only reuse of historical Solidity checks; does not execute Solidity."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
CORE = Path(os.environ.get('LIDO_CORE_SOURCE', '/tmp/lido-ssz-proof-committed/lido-core'))
PIN = '17005714f151e5502c559932319a3f2f74ac2436'
assert subprocess.check_output(['git','-C',str(CORE),'rev-parse','HEAD'],text=True).strip() == PIN

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def source(path):
    if path.startswith('lido-core/'):
        return CORE / path.removeprefix('lido-core/')
    return ROOT / path

receipts = [
 'audit/ssz-root-call-composition/solidity/compiler-input-identities.json',
 'audit/topup-gateway-witness-batch/solidity/receipt.json',
 'audit/topup-batch-consumer/solidity/receipt.json',
]
checks = {}
records = []
for receipt in receipts:
    d=json.loads((ROOT/receipt).read_text())
    expected=d.get('source_sha256') or {p:v['sha256'] for p,v in d['sources'].items()}
    used={}
    for path,digest in expected.items():
        if path == 'foundry.toml':
            continue # Historical harness configuration is retained, not current root config.
        p=source(path)
        assert sha(p)==digest, path
        if path.startswith('lido-core/') and '/openzeppelin/' not in path:
            body=subprocess.check_output(['git','-C',str(CORE),'show',PIN+':'+path.removeprefix('lido-core/')])
            assert body==p.read_bytes(),path
        used[path]=digest
        checks[path]=digest
    records.append({'receipt':receipt,'sha256':sha(ROOT/receipt),'source_checks':len(used),
                    'historical_test_count':d.get('tests',9)})
(OUT/'inherited-validation.json').write_text(json.dumps({
 'fresh_solidity_execution':False,'source_pin':PIN,'receipts':records,
 'scope':'Identity-only reuse of existing SSZ root, gateway loop, and module-batch Solidity checks. New typed composition is kernel-tested; no compiled composition refinement claimed.',
 'source_sha256':checks},indent=2)+'\n')
print(f'PASS: {len(checks)} unchanged compiler source/fixture identities across {len(records)} inherited receipts; no fresh Solidity run.')
