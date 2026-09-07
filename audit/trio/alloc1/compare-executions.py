#!/usr/bin/env python3
"""Compare independently executed Solidity and Verity observations; no model evaluation."""
import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('solidity', type=Path)
parser.add_argument('verity', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
solidity = json.loads(args.solidity.read_text())
verity = json.loads(args.verity.read_text())
assert len(solidity) == len(verity) == 12, 'complete expected fixture set'
assert len({x['name'] for x in solidity}) == 12, 'unique Solidity fixture names'
assert len({x['name'] for x in verity}) == 12, 'unique Verity fixture names'
assert {x['name'] for x in solidity} == {x['name'] for x in verity}, 'matching fixture sets'
checks = []
for actual in solidity:
    peer = next(x for x in verity if x['name'] == actual['name'])
    same = actual['actual'] == peer['actual'] and actual['calls'] == peer['calls']
    checks.append({'name': actual['name'], 'result_and_calls_equal': same})
receipt = {
    'classification': 'SOLIDITY_VERITY_PASS' if all(x['result_and_calls_equal'] for x in checks)
                      else 'SOLIDITY_VERITY_MISMATCH',
    'scope': 'Decoded returns or raw errors, and ordered top-level calls; compiler memory, world preservation and nested callbacks have separate receipts/proofs.',
    'solidity_sha256': hashlib.sha256(args.solidity.read_bytes()).hexdigest(),
    'verity_sha256': hashlib.sha256(args.verity.read_bytes()).hexdigest(),
    'checks': checks,
}
args.output.write_text(json.dumps(receipt, indent=2) + '\n')
print(receipt['classification'])
raise SystemExit(0 if all(x['result_and_calls_equal'] for x in checks) else 1)
