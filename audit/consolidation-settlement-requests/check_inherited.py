#!/usr/bin/env python3
"""Recheck unchanged exact compiler/fixture artifacts; no Solidity execution."""
from pathlib import Path
import hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
assert subprocess.check_output(['git','-C',str(CORE),'rev-parse','HEAD'],text=True).strip()==PIN
records=[];checks={}
for name in ['consolidation-settlement','consolidation-gateway-call']:
    d=ROOT/'audit'/name;r=json.loads((d/'receipt.json').read_text())
    for path,expected in (r.get('artifacts') or r['files']).items():
        assert sha(d/path)==expected,str(d/path)
        checks[str((d/path).relative_to(ROOT))]=expected
    records.append(dict(receipt=str((d/'receipt.json').relative_to(ROOT)),sha256=sha(d/'receipt.json'),historical_solidity_tests=9 if name=='consolidation-settlement' else 5))
pins=json.loads((ROOT/'audit/consolidation-settlement/solidity/source-identities.json').read_text())['full_pinned_sources']
for path,expected in pins.items():
    p=CORE/path;assert sha(p)==expected,path
    assert subprocess.check_output(['git','-C',str(CORE),'show',PIN+':'+path])==p.read_bytes(),path
(OUT/'inherited-validation.json').write_text(json.dumps(dict(source_pin=PIN,source_sha256=pins,receipts=records,artifact_sha256=checks,fresh_solidity_execution=False,scope='Identity-only reuse of retained 312 settlement and corrected295/derived gateway CALL fragment fixtures, compiler inputs and source receipts. No full compiled composition proof.'),indent=2)+'\n')
print(f'PASS: {len(checks)} exact retained artifact/fixture hashes; {len(pins)} pinned Solidity bodies; two historical test packets (9 + 5), no fresh execution.')
