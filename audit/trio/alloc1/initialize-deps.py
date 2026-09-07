#!/usr/bin/env python3
"""Initialize private pinned Lake checkouts from a read-only local object cache."""
import argparse
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--cache', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
manifest = json.loads((root / 'lake-manifest.json').read_text())
packages = root / '.lake/packages'
packages.mkdir(parents=True, exist_ok=True)
for pkg in manifest['packages']:
    target = packages / pkg['name']
    if target.exists():
        actual = subprocess.check_output(['git', '-C', str(target), 'rev-parse', 'HEAD'], text=True).strip()
        if actual != pkg['rev']:
            raise SystemExit(f'preserving mismatched existing dependency {target}: {actual}')
    else:
        subprocess.run(['git', 'clone', '--quiet', '--no-hardlinks', '--no-checkout',
                        str(args.cache / pkg['name']), str(target)], check=True)
        subprocess.run(['git', '-C', str(target), 'remote', 'set-url', 'origin', pkg['url']], check=True)
        subprocess.run(['git', '-C', str(target), 'checkout', '--quiet', '--detach', pkg['rev']], check=True)
    print(pkg['name'] + ' ' + pkg['rev'], flush=True)
