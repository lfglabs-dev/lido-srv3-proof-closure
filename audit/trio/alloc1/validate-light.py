#!/usr/bin/env python3
"""Bounded Init-only checks. Heavy production/test/trust builds remain remote."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--lean', required=True, type=Path)
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
out = args.output.resolve()
if out.exists():
    raise SystemExit('output must be new; preserve previous receipts')
out.mkdir(parents=True)
objects = out / 'olean'
objects.mkdir()
env = {**os.environ, 'LEAN_PATH': str(objects)}
modules = [
    'Audit/Source/TrioAlloc1/' + name for name in
    ['Interface', 'Storage', 'Execution', 'Properties', 'CapacitySpec', 'Bytes', 'Memory', 'FirstPass', 'Relational', 'Determinism', 'ShareWriter', 'AdmissionChecks', 'ParameterWriter', 'WriterInvariant', 'EnumerationWriter', 'StringStorage', 'AdmissionWriter', 'AdmissionFacts', 'RecordInvariant', 'StatusWriter', 'ACLWriter', 'Initialization', 'CallTree', 'AllocationMemory']
] + ['Tests/TrioAlloc1/' + name for name in ['Execution', 'VectorCases', 'SolidityVectors', 'Correspondence']]
receipt = dict(compiler=subprocess.check_output([str(args.lean), '--version'], text=True).strip(),
               started_at=time.time(), checks=[], classification='IN_PROGRESS')
try:
    for module in modules:
        source = root / ('LidoSRv3/' + module + '.lean')
        for line in source.read_text().splitlines():
            if line.startswith('import ') and not all(
                imported == 'Init' or imported.startswith(('LidoSRv3.Audit.Source.TrioAlloc1.',
                                                            'LidoSRv3.Tests.TrioAlloc1.'))
                for imported in line.split()[1:]):
                raise RuntimeError(f'heavy import requires remote validation: {source}')
        target = objects / ('LidoSRv3/' + module + '.olean')
        target.parent.mkdir(parents=True, exist_ok=True)
        command = [str(args.lean), '-o', str(target), str(source.relative_to(root))]
        run = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True, timeout=30)
        entry = dict(source=str(source.relative_to(root)), source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                     command=command, exit_code=run.returncode, stdout=run.stdout, stderr=run.stderr)
        receipt['checks'].append(entry)
        print(entry['source'] + ' exit=' + str(run.returncode), flush=True)
        if run.returncode:
            raise RuntimeError(run.stdout + run.stderr)
    command = [str(args.lean), '--run', 'LidoSRv3/Tests/TrioAlloc1/SolidityVectors.lean']
    run = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True, timeout=30)
    if run.returncode:
        raise RuntimeError(run.stdout + run.stderr)
    json.loads(run.stdout)
    (out / 'vectors.json').write_text(run.stdout)
    receipt['vector_command'] = command
    receipt['vectors_sha256'] = hashlib.sha256(run.stdout.encode()).hexdigest()
    receipt['classification'] = 'LIGHT_INIT_ONLY_PASS'
except Exception as exc:
    receipt['classification'] = 'LIGHT_CHECK_FAILED'
    receipt['failure'] = str(exc)
    raise
finally:
    receipt['finished_at'] = time.time()
    (out / 'receipt.json').write_text(json.dumps(receipt, indent=2)+'\n')
