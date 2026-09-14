#!/usr/bin/env python3
"""Check that every registered Lake reproduction names existing project modules."""
import json
from pathlib import Path
import shlex

ROOT = Path(__file__).resolve().parent.parent


def check(root):
    rows = json.loads((root / 'audit/guarantees.yaml').read_text())['guarantees']
    count = 0
    for row in rows:
        command = row.get('reproduction', {}).get('command', '')
        for token in shlex.split(command):
            if token.startswith('LidoSRv3.'):
                module = token.split(':', 1)[0]
                path = root / (module.replace('.', '/') + '.lean')
                if not path.is_file():
                    raise ValueError(f"{row['id']}: missing reproduction target {module}")
                count += 1
    return count


if __name__ == '__main__':
    print(f'reproduction targets: {check(ROOT)} registered module references exist')
