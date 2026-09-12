#!/usr/bin/env python3
"""Offline identities and source order; not a Solidity/Lean equivalence proof."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'audit/topup-gateway-witness-batch'
r = json.loads((BASE / 'receipt.json').read_text())
s = json.loads((BASE / 'source-check.json').read_text())
def digest(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
for group in ('validated_inputs', 'evidence_sha256'):
    for path, expected in r[group].items():
        assert digest(path) == expected, path
listed = dict((line.split('  ', 1)[1], line.split('  ', 1)[0])
              for line in (BASE / 'validated-inputs.sha256').read_text().splitlines())
assert listed == r['validated_inputs']
for path, expected in s['source_sha256'].items():
    assert digest(path) == expected, path
for path, tokens in s['source_order'].items():
    txt = (ROOT / path).read_text()
    pos = 0
    for token in tokens:
        pos = txt.index(token, pos) + len(token)
for path in r['source_files']:
    txt = (ROOT / path).read_text()
    assert not re.search(r'\b(sorry|admit|native_decide|bv_decide)\b', txt), path
    assert not re.search(r'^\s*axiom\s', txt, re.M), path
log = (BASE / 'validation.log').read_text()
assert f"Build completed successfully ({r['lean']['jobs']} jobs)." in log
assert not re.search(r'(warning|error): LidoSRv3/(Audit/Source|Tests)/TopupGateway', log)
axioms = re.findall(r'depends on axioms: \[([^\]]+)\]', (BASE / 'axioms.log').read_text())
assert len(axioms) == r['lean']['axiom_queries']
assert {a.strip() for group in axioms for a in group.split(',')} <= {'propext', 'Classical.choice', 'Quot.sound'}
sol = json.loads((BASE / 'solidity/receipt.json').read_text())
assert sol['tests'] == 7 and sol['fuzz_properties'] == 3 and sol['fuzz_runs_each'] == 1024
assert sol['test_exit_code'] == 0
for name, expected in sol['artifacts'].items():
    assert digest(str((BASE / 'solidity' / name).relative_to(ROOT))) == expected, name
print(json.dumps({'passed': True, 'validated_inputs': len(listed),
    'evidence_files': len(r['evidence_sha256']), 'axiom_queries': len(axioms),
    'source_order_files': len(s['source_order']), 'solidity_tests': sol['tests']}, indent=2))
