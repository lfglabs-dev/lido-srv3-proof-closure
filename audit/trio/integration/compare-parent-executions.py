#!/usr/bin/env python3
"""Compare recorded Solidity observations with actual parent VM execution output."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def vectors(log, prefix, count):
    rows = [json.loads(match[1]) for line in log.splitlines()
            if (match := re.search(r'(?:^|: )' + prefix + r' (.+)$', line))]
    require(len(rows) == count, f'{prefix}: missing or truncated vectors')
    require(len({row['name'] for row in rows}) == count, f'{prefix}: duplicate names')
    return {row['name']: row for row in rows}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('vm_receipt', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    receipt = json.loads(args.vm_receipt.read_text())
    require(receipt['state'] in ('succeeded', 'failed') and receipt['exit_code'] is not None,
            'VM job must have an authoritative terminal result')
    validation = receipt['validation']
    require(validation['toolchain'] == 'leanprover/lean4:v4.31.0', 'wrong VM toolchain')
    require(validation['repository'] == 'https://github.com/lfglabs-dev/lido-srv3-proof-closure.git',
            'wrong VM repository')
    commit = validation['commit']
    require(re.fullmatch('[0-9a-f]{40}', commit), 'missing exact VM source commit')
    command = validation['command']
    prefix = ['lake', 'env', 'lean', '--run']
    require(command in [prefix + ['audit/trio/integration/RunVerityParent.lean'],
                        prefix + ['audit/trio/integration/RunValidation.lean']], 'wrong VM command')
    if command[-1].endswith('/RunValidation.lean'):
        require('INTEGRATION_GATE_EXIT 0 lake env lean --run audit/trio/integration/RunVerityParent.lean'
                in receipt['log_tail'].splitlines(), 'parent VM gate did not pass')
    else:
        require(receipt['state'] == 'succeeded' and receipt['exit_code'] == 0, 'parent VM run failed')
    checked = {}

    def check_source(path):
        if path in checked:
            return
        local = (root / path).read_bytes()
        pinned = subprocess.check_output(['git', '-C', str(root), 'show', f'{commit}:{path}'])
        require(local == pinned, f'VM source changed since execution: {path}')
        checked[path] = digest(local)
        if path.endswith('.lean'):
            for line in local.decode().splitlines():
                if line.startswith('import '):
                    for module in line.split()[1:]:
                        if module.startswith('LidoSRv3.'):
                            check_source(module.replace('.', '/') + '.lean')

    for path in ['LidoSRv3/Tests/TrioIntegration/ParentDifferential.lean',
                 command[-1], 'audit/trio/integration/RunVerityParent.lean',
                 'lean-toolchain', 'lake-manifest.json']:
        check_source(path)
    actual = vectors(receipt['log_tail'], 'VERITY_PARENT_DIFFERENTIAL_VECTOR', 12)
    solidity_path = root / 'audit/trio/alloc2/parent-execution.json'
    solidity = json.loads(solidity_path.read_text())
    require(solidity['mutation'] is None, 'mutated Solidity cannot establish the baseline')
    require(solidity['originalHarnessSha256'] == solidity['harnessSha256'],
            'baseline harness differs from the original input')
    for field, filename in [('harnessSha256', 'Harness.sol'), ('runnerSha256', 'run.cjs'),
                            ('lockSha256', 'package-lock.json'), ('mutationsSha256', 'mutations.cjs')]:
        require(digest((root / 'solidity/trio-alloc2/parent' / filename).read_bytes()) == solidity[field],
                f'Solidity harness changed since execution: {filename}')
    model_path = root / f"audit/trio/alloc2/receipt-{solidity['model']['job']}.json"
    require(digest(model_path.read_bytes()) == solidity['model']['receiptSha256'],
            'Solidity input receipt hash mismatch')
    model = json.loads(model_path.read_text())
    require(model['job_id'] == solidity['model']['job'], 'wrong input fixture job')
    require(model['state'] == 'succeeded' and model['exit_code'] == 0, 'input fixture run failed')
    inputs = vectors(model['log_tail'], 'ALLOC2_PARENT_VECTOR', 8)
    memory_inputs = vectors(model['log_tail'], 'ALLOC2_MEMORY_VECTOR', 4)
    require(not (inputs.keys() & memory_inputs.keys()), 'overlapping fixture names')
    inputs.update(memory_inputs)
    expected = {row['name']: row for row in solidity['receipts']}
    require(len(solidity['receipts']) == len(expected) == 12, 'incomplete Solidity cases')
    require(actual.keys() == inputs.keys() == expected.keys(), 'fixture sets differ')
    pin = '17005714f151e5502c559932319a3f2f74ac2436'
    require(solidity['pin'] == pin, 'wrong Solidity pin')
    for path, sha in solidity['sources'].items():
        if path.startswith('contracts/'):
            blob = subprocess.check_output(['git', '-C', str(root / 'lido-core'), 'show', f'{pin}:{path}'])
            require(digest(blob) == sha, f'Solidity source hash mismatch: {path}')
    for name, row in actual.items():
        for key in ('count', 'unit', 'amount'):
            require(int(row[key]) == int(inputs[name][key]), f'{name}: different input {key}')
        if name in memory_inputs:
            require(int(row['count']) > 0 and row['calls'] == [], f'{name}: memory guard reached calls')
        else:
            for key in ('shares', 'summaries', 'reject1'):
                require(row[key] == inputs[name][key], f'{name}: different input {key}')
        for key in ('actual', 'reverted', 'calls'):
            require(row[key] == expected[name][key], f'{name}: different observation {key}')
    args.output.write_text(json.dumps({
        'classification': 'SOLIDITY_PARENT_VERITY_PASS', 'vm_source': commit,
        'vm_job': receipt['job_id'], 'vm_receipt_sha256': digest(args.vm_receipt.read_bytes()),
        'solidity_receipt_sha256': digest(solidity_path.read_bytes()),
        'scope': 'Twelve matched parent inputs, raw return/revert bytes and ordered module calls, '
                 'including four early allocation/division failures. The modeled producer guards use pointer 128. '
                 'Compiler memory, deployed delegatecall and recursive world observations remain separate.',
        'cases': sorted(actual), 'vm_source_hashes': checked,
    }, indent=2) + '\n')
    print('SOLIDITY_PARENT_VERITY_PASS: 12 cases')


if __name__ == '__main__':
    main()
