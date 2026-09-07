#!/usr/bin/env python3
"""Run source executions with strict Cancun limits and durable per-command evidence."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

p = argparse.ArgumentParser()
p.add_argument('--output', type=Path, required=True)
p.add_argument('--dependencies', type=Path, required=True)
p.add_argument('--proxy-dependencies', type=Path, required=True)
p.add_argument('--source-vectors', type=Path, required=True)
p.add_argument('--verity-vectors', type=Path, required=True)
a = p.parse_args()
a.output.mkdir(parents=True, exist_ok=False)
root = Path(__file__).resolve().parents[3]
sha = lambda f: hashlib.sha256(f.read_bytes()).hexdigest()
source_files = sorted((root / 'solidity/trio-alloc1').glob('*.cjs')) + sorted((root / 'solidity/trio-alloc1').glob('*.sol')) + sorted((root / 'solidity/trio-alloc1').glob('package*.json')) + [Path(__file__).resolve()]
identities = {str(f.relative_to(root)): sha(f) for f in source_files}
env = {**os.environ, 'ALLOC1_EVM': 'cancun', 'NODE_PATH': str(a.dependencies.resolve() / 'node_modules')}
steps = [
    ('capacity', ['node', 'solidity/trio-alloc1/run.cjs', str(a.output/'capacity'), str(a.source_vectors.resolve())], 0),
    ('callback', ['node', 'solidity/trio-alloc1/check-callback.cjs', str(a.output/'callback')], 0),
    ('writer', ['node', 'solidity/trio-alloc1/check-writer.cjs', str(a.output/'writer')], 0),
    ('proxy', ['node', 'solidity/trio-alloc1/check-proxy-initialization.cjs', str(a.output/'proxy'), str(a.proxy_dependencies.resolve())], 0),
    ('target-mutant', ['node', 'solidity/trio-alloc1/run.cjs', str(a.output/'target-mutant'), str(a.source_vectors.resolve()), 'target-only'], 1),
    ('order-mutant', ['node', 'solidity/trio-alloc1/run.cjs', str(a.output/'order-mutant'), str(a.source_vectors.resolve()), 'stake-before-subtraction'], 1),
    ('verity-comparison', ['python3', 'audit/trio/alloc1/compare-executions.py', str(a.output/'capacity/executions.json'), str(a.verity_vectors.resolve()), str(a.output/'verity-comparison.json')], 0),
]
receipt = {'scope': 'Cancun source executions; prior Verity execution reused, not a fresh Lean build or universal compiler correspondence',
           'head_at_start': subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
           'source_sha256': identities, 'source_vectors_sha256':sha(a.source_vectors),
           'verity_vectors_sha256':sha(a.verity_vectors), 'steps': []}
for name, cmd, expected_exit in steps:
    started = time.time()
    with (a.output/(name+'.stdout')).open('w') as stdout, (a.output/(name+'.stderr')).open('w') as stderr:
        result = subprocess.run(cmd, cwd=root, env=env, stdout=stdout, stderr=stderr)
    passed = result.returncode == expected_exit
    if expected_exit == 1:
        executed = a.output/name/'executions.json'
        evidence = json.loads(executed.read_text()) if executed.exists() else []
        passed = passed and any(x['actual'] != x['expected'] or x['calls'] != x['expectedCalls'] for x in evidence)
    receipt['steps'].append({'name':name, 'command':cmd, 'exit_code':result.returncode,
                             'expected_exit':expected_exit, 'passed':passed, 'elapsed_seconds':time.time()-started})
    (a.output/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print(name, 'PASS' if passed else 'FAIL', flush=True)
receipt['source_unchanged'] = identities == {str(f.relative_to(root)):sha(f) for f in source_files}
receipt['artifacts'] = {str(f.relative_to(a.output)):sha(f) for f in sorted(a.output.rglob('*')) if f.is_file() and f.name != 'receipt.json'}
receipt['passed'] = receipt['source_unchanged'] and all(x['passed'] for x in receipt['steps'])
(a.output/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
raise SystemExit(0 if receipt['passed'] else 1)
