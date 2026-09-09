#!/usr/bin/env python3
"""Offline identity/order checks. This script does not prove source equivalence."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'audit/topup-router-continuation'
receipt = json.loads((BASE / 'receipt.json').read_text())
source = json.loads((BASE / 'source-check.json').read_text())


def digest(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


for path, expected in receipt['validated_inputs'].items():
    assert digest(path) == expected, path
for path, expected in receipt['evidence_sha256'].items():
    assert digest(path) == expected, path
listed = dict((line.split('  ', 1)[1], line.split('  ', 1)[0])
              for line in (BASE / 'validated-inputs.sha256').read_text().splitlines())
assert listed == receipt['validated_inputs']
for path, expected in source['source_sha256'].items():
    assert digest(path) == expected, path
for path, tokens in source['source_order'].items():
    text = (ROOT / path).read_text()
    pos = 0
    for token in tokens:
        pos = text.index(token, pos) + len(token)
for path in receipt['source_files']:
    text = (ROOT / path).read_text()
    assert not re.search(r'\b(sorry|admit|native_decide|bv_decide)\b', text), path
    assert not re.search(r'^\s*axiom\s', text, re.M), path
log = (BASE / 'validation.log').read_text()
assert 'Build completed successfully (1272 jobs).' in log
assert not re.search(r'(warning|error): LidoSRv3/(Audit/Source|Tests)/TopupRouter', log)
axioms = re.findall(r'depends on axioms: \[([^\]]+)\]', (BASE / 'axioms.log').read_text())
assert len(axioms) == 9
assert {a.strip() for group in axioms for a in group.split(',')} <= {
    'propext', 'Classical.choice', 'Quot.sound'}
print(json.dumps({'passed': True, 'validated_inputs': len(listed),
                  'evidence_files': len(receipt['evidence_sha256']),
                  'axiom_queries': len(axioms),
                  'source_order_files': len(source['source_order'])}, indent=2))
