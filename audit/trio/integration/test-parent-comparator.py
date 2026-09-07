#!/usr/bin/env python3
"""Negative comparator tests in a separate clean checkout, using a real VM receipt."""
import argparse
import copy
import json
from pathlib import Path
import subprocess
import sys


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('checkout', type=Path)
    parser.add_argument('vm_receipt', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    checkout = args.checkout.resolve()
    require(checkout != Path(__file__).resolve().parents[3], 'use a separate disposable checkout')
    status = subprocess.check_output(['git', '-C', str(checkout), 'status', '--porcelain'], text=True)
    require(not status, 'disposable checkout must start clean')
    solidity_path = checkout / 'audit/trio/alloc2/parent-execution.json'
    original = solidity_path.read_bytes()
    solidity = json.loads(original)
    vm = json.loads(args.vm_receipt.read_text())
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    vm_path = output / 'fixture-vm.json'
    report = {'classification': 'PARENT_COMPARATOR_REGRESSION_PASS',
              'real_vm_source': vm['validation']['commit'], 'real_vm_job': vm['job_id'], 'tests': []}
    cases = [
        ('baseline', '', ''),
        ('mutated-baseline', 'solidity', 'mutated Solidity cannot establish the baseline'),
        ('changed-original-harness', 'solidity', 'baseline harness differs from the original input'),
        ('changed-mutation-input', 'solidity', 'Solidity harness changed since execution: mutations.cjs'),
        ('empty-solidity', 'solidity', 'incomplete Solidity cases'),
        ('duplicate-solidity', 'solidity', 'incomplete Solidity cases'),
        ('changed-observation', 'solidity', 'different observation actual'),
        ('truncated-vm', 'vm', 'missing or truncated vectors'),
        ('wrong-repository', 'vm', 'wrong VM repository'),
        ('nonterminal-vm', 'vm', 'VM job must have an authoritative terminal result'),
    ]
    try:
        for optimized in [False, True]:
            for name, target, rejection in cases:
                sol, current_vm = copy.deepcopy(solidity), copy.deepcopy(vm)
                if name == 'mutated-baseline':
                    sol['mutation'] = {'name': 'test-only-invalid-baseline'}
                elif name == 'changed-original-harness':
                    sol['originalHarnessSha256'] = '0'*64
                elif name == 'changed-mutation-input':
                    sol['mutationsSha256'] = '0'*64
                elif name == 'empty-solidity':
                    sol['receipts'] = []
                elif name == 'duplicate-solidity':
                    sol['receipts'][1]['name'] = sol['receipts'][0]['name']
                elif name == 'changed-observation':
                    sol['receipts'][0]['actual'] = '0xinvalid-test-fixture'
                elif name == 'truncated-vm':
                    lines = current_vm['log_tail'].splitlines()
                    index = next(i for i, line in enumerate(lines)
                                 if line.startswith('VERITY_PARENT_DIFFERENTIAL_VECTOR '))
                    current_vm['log_tail'] = '\n'.join(lines[:index]+lines[index+1:])
                elif name == 'wrong-repository':
                    current_vm['validation']['repository'] = 'https://example.invalid/test-only.git'
                elif name == 'nonterminal-vm':
                    current_vm['state'], current_vm['exit_code'] = 'running', None
                solidity_path.write_text(json.dumps(sol))
                vm_path.write_text(json.dumps(current_vm))
                command = [sys.executable] + (['-O'] if optimized else []) + [
                    str(checkout / 'audit/trio/integration/compare-parent-executions.py'),
                    str(vm_path), str(output / 'comparison.json')]
                run = subprocess.run(command, capture_output=True, text=True, timeout=30)
                message = run.stdout + run.stderr
                if target:
                    require(run.returncode != 0 and rejection in message,
                            f'{name} optimized={optimized}: wrong rejection: {message}')
                else:
                    require(run.returncode == 0 and 'SOLIDITY_PARENT_VERITY_PASS: 12 cases' in message,
                            f'baseline optimized={optimized} failed: {message}')
                report['tests'].append({'name': name, 'optimized': optimized,
                                        'exit_code': run.returncode, 'output': message.strip()})
    finally:
        solidity_path.write_bytes(original)
    (output / 'report.json').write_text(json.dumps(report, indent=2)+'\n')
    print('PARENT_COMPARATOR_REGRESSION_PASS: 2 baselines, 18 rejected corruptions')


if __name__ == '__main__':
    main()
