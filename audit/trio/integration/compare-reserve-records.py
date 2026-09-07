#!/usr/bin/env python3
"""Independently compare recorded reserve cases; this does not execute either VM."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
EVENTS = {
    'DepositedPostReportUpdated': 'contracts/0.4.24/Lido.sol',
    'DepositedValidatorsChanged': 'contracts/0.4.24/Lido.sol',
    'Unbuffered': 'contracts/0.4.24/Lido.sol',
    'DepositsReserveSet': 'contracts/0.4.24/Lido.sol',
    'DepositableEthReceived': 'contracts/0.8.25/sr/ISRBase.sol',
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def word(value):
    return int(value).to_bytes(32, 'big')


def normalized(row, topics):
    fault = row['result'].get('fault')
    returned = []
    if fault and fault['kind'] == 'bubbled':
        returned = fault['data']
    elif fault and fault['kind'] == 'reason':
        reason = fault['reason'].encode()
        returned = list(bytes.fromhex('08c379a0') + word(32) + word(len(reason))
                        + reason + bytes((-len(reason)) % 32))
    else:
        require(not fault or fault['kind'] == 'empty', 'unknown fault encoding')
    logs = []
    for event in row['logs']:
        require(event['name'] in topics and len(event['values']) == 1, 'unknown event encoding')
        logs.append({'emitter': event['emitter'], 'topics': [topics[event['name']]],
                     'data': '0x' + word(event['values'][0]).hex()})
    return {**{k: row[k] for k in ['name', 'storage', 'balances', 'calls', 'nested']},
            'success': row['result']['success'], 'returned': returned, 'logs': logs}


def main():
    receipt, output = map(Path, sys.argv[1:])
    context = json.loads((receipt / 'context.json').read_text())
    require(context['exit'] == 0 and context['finished_utc'], 'execution not successful/terminal')
    sha = context['source_commit']
    require(re.fullmatch('[0-9a-f]{40}', sha), 'invalid execution commit')
    for name, expected_hash in context['source_hashes'].items():
        blob = subprocess.check_output(['git', 'show', f'{sha}:{name}'], cwd=ROOT)
        require(digest(blob) == expected_hash, 'execution source hash differs: ' + name)
        if name.endswith('.lean') or name.endswith('.sol'):
            require(digest((ROOT / name).read_bytes()) == expected_hash, 'current source differs: ' + name)
    topics = {}
    for event, source in EVENTS.items():
        blob = subprocess.check_output(['git', '-C', str(ROOT / 'lido-core'), 'show',
                                       context['solidity_pin'] + ':' + source]).decode()
        require(re.search(r'event\s+' + event + r'\(uint256\s+\w+\);', blob), 'event declaration differs')
        topics[event] = subprocess.check_output(['cast', 'keccak', event + '(uint256)'], text=True).strip()
    inputs = json.loads((receipt / 'differential-input.json').read_text())
    actual = json.loads((receipt / 'differential-verity.json').read_text())
    expected = json.loads((receipt / 'differential-solidity.json').read_text())
    require(len(inputs) == len(actual) == len(expected) == 51, 'incomplete case coverage')
    names = [row['name'] for row in inputs]
    require(len(set(names)) == 51, 'duplicate input names')
    require([row['name'] for row in actual] == [row['name'] for row in expected] == names,
            'case identity/order differs')
    for got, wanted in zip(actual, expected):
        require(normalized(got, topics) == wanted, 'differential mismatch: ' + got['name'])
    mutants = json.loads((receipt / 'mutation-verity.json').read_text())
    mutations = json.loads((receipt / 'mutation-input.json').read_text())
    require(len(mutants) == len(mutations) == 7, 'incomplete mutation coverage')
    for got, mutation in zip(mutants, mutations):
        require(got['name'] == mutation['name'], 'mutation identity differs')
        require(normalized(got, topics) != expected[names.index(got['name'])], 'mutant survived')
    files = ['context.json', 'differential-input.json', 'differential-verity.json',
             'differential-solidity.json', 'mutation-input.json', 'mutation-verity.json']
    report = {'status': 'PASS_RECORDED_RESERVE_COMPARISON', 'source_commit': sha,
              'cases': 51, 'mutants': 7, 'event_topics': topics,
              'source_pipeline_cases': sum(row['sourcePipeline'] for row in actual),
              'scope': 'Independent comparison of recorded execution outputs, including ABI bytes/events. '
                       'Not fresh VM execution, final-head validation, or universal correspondence.',
              'files': {name: digest((receipt / name).read_bytes()) for name in files}}
    output.write_text(json.dumps(report, indent=2) + '\n')
    print('PASS_RECORDED_RESERVE_COMPARISON: 51 cases, 7 mutants')


if __name__ == '__main__':
    main()
