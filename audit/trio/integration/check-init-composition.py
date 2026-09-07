#!/usr/bin/env python3
"""Bounded Init-only composition elaboration, never a full build receipt."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
out = args.output.resolve()
out.mkdir(parents=True, exist_ok=False)
objects = out / 'olean'
objects.mkdir()
lean = subprocess.check_output(['elan', 'which', 'lean'], cwd=root, text=True).strip()
env = {**os.environ, 'LEAN_PATH': str(objects)}
receipt = {'classification': 'INCOMPLETE_INIT_ONLY', 'head': subprocess.check_output(
    ['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
    'compiler': subprocess.check_output([lean, '--version'], text=True).strip(), 'checks': []}
visited = set()

def check(module):
    if module == 'Init' or module in visited:
        return
    if not module.startswith(('LidoSRv3.Audit.Source.TrioAlloc1.',
                              'LidoSRv3.Audit.Source.TrioAlloc2.',
                              'LidoSRv3.Tests.TrioIntegration.',
                              'LidoSRv3.Audit.Source.TrioComposition.',
                              'audit.trio.alloc2.composition.',
                              'audit.trio.integration.IndexedParentBridge')):
        raise RuntimeError(f'Non-Init closure requires full validation: {module}')
    visited.add(module)
    relative = Path(*module.split('.')).with_suffix('.lean')
    source = root / relative
    for line in source.read_text().splitlines():
        if line.startswith('import '):
            for dependency in line.split()[1:]:
                check(dependency)
    target = (objects / relative).with_suffix('.olean')
    target.parent.mkdir(parents=True, exist_ok=True)
    command = [lean, '-o', str(target), str(relative)]
    run = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True, timeout=30)
    receipt['checks'].append({'source': str(relative),
        'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'command': command, 'exit_code': run.returncode,
        'stdout': run.stdout, 'stderr': run.stderr})
    print(f'{module}: {run.returncode}', flush=True)
    if run.returncode:
        raise RuntimeError(run.stdout + run.stderr)

try:
    check('LidoSRv3.Tests.TrioIntegration.LibraryABI')
    check('LidoSRv3.Audit.Source.TrioAlloc2.ABIComposition')
    check('LidoSRv3.Tests.TrioIntegration.MemoryComposition')
    check('LidoSRv3.Tests.TrioIntegration.Parent')
    check('LidoSRv3.Audit.Source.TrioComposition.ParentDeterminism')
    check('LidoSRv3.Audit.Source.TrioComposition.ParentABI')
    check('LidoSRv3.Audit.Source.TrioComposition.AllocationExtent')
    check('LidoSRv3.Audit.Source.TrioComposition.ParentCalls')
    check('LidoSRv3.Audit.Source.TrioComposition.AllocationParentCalls')
    check('LidoSRv3.Tests.TrioIntegration.AllocationGuards')
    check('LidoSRv3.Tests.TrioIntegration.ReturnMemory')
    check('LidoSRv3.Tests.TrioIntegration.RowMemory')
    check('LidoSRv3.Tests.TrioIntegration.MemoryProducer')
    check('LidoSRv3.Audit.Source.TrioComposition.MemoryParentCalls')
    check('LidoSRv3.Audit.Source.TrioComposition.WriterMemory')
    check('LidoSRv3.Audit.Source.TrioComposition.CallerMemory')
    check('LidoSRv3.Audit.Source.TrioAlloc1.ACLWriter')
    check('LidoSRv3.Audit.Source.TrioAlloc1.ProxyGenesis')
    check('LidoSRv3.Audit.Source.TrioComposition.WriterExtent')
    check('LidoSRv3.Audit.Source.TrioAlloc2.ParentValues')
    check('LidoSRv3.Audit.Source.TrioAlloc1.AdmissionWriter')
    check('LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts')
    check('audit.trio.alloc2.composition.ParentErrors')
    check('audit.trio.alloc2.composition.ParentInversion')
    check('audit.trio.alloc2.composition.ParentPostconditions')
    check('audit.trio.alloc2.composition.ParentVectors')
    check('audit.trio.alloc2.composition.MemoryVectors')
    check('audit.trio.alloc2.composition.LibraryABIVectors')
    check('audit.trio.integration.IndexedParentBridge')
    check('LidoSRv3.Tests.TrioIntegration.FinalMemory')
    check('LidoSRv3.Tests.TrioIntegration.FinalMemoryStoredProducer')
    check('LidoSRv3.Tests.TrioIntegration.MemoryTransport')
    check('LidoSRv3.Audit.Source.TrioComposition.MemoryTransportCall')
    check('LidoSRv3.Audit.Source.TrioComposition.MemoryTransportConversion')
    check('LidoSRv3.Audit.Source.TrioComposition.LifecycleHistory')
    check('LidoSRv3.Audit.Source.TrioComposition.CacheRepresentation')
    check('audit.trio.alloc2.composition.ProducerMemoryVectors')
    check('audit.trio.alloc2.composition.MemoryWriteVectors')
    check('LidoSRv3.Tests.TrioIntegration.FinalMemoryStoredParent')
    # ByteVectors executes 129 physical-byte rows; run it only on the remote runner.
    check('audit.trio.alloc2.composition.ByteProducer')
    receipt['classification'] = 'PASS_INIT_ONLY_COMPOSITION'
finally:
    (out / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
