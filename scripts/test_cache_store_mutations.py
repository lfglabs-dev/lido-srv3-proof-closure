#!/usr/bin/env python3
"""Compile the cache leaf, then require concrete store/read mutations to fail."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'LidoSRv3/Audit/Source/TrioComposition/CacheStores.lean'


def main():
    subprocess.run(['lake', 'build', 'LidoSRv3.Audit.Source.TrioComposition.CacheStores'],
                   cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    original = SOURCE.read_text()
    changes = [
        ('overlapping field', 'let a := store memory (p+64) v.share',
         'let a := store memory (p+96) v.share'),
        ('omitted share write', 'let a := store memory (p+64) v.share',
         'let a := memory'),
        ('wrong share read', 'checked ((memory (p+64)).val * total.val)',
         'checked ((memory (p+96)).val * total.val)'),
        ('wrong cache address', '+ 64*(count+1) + 160*index',
         '+ 0*(count+1) + 160*index'),
    ]
    with tempfile.TemporaryDirectory(prefix='lido-cache-mutations-') as directory:
        for name, before, after in changes:
            if original.count(before) != 1:
                raise RuntimeError(f'{name}: mutation target is not unique')
            path = Path(directory) / 'Mutated.lean'
            path.write_text(original.replace(before, after))
            result = subprocess.run(['lake', 'env', 'lean', str(path)], cwd=ROOT,
                                    capture_output=True, text=True)
            if result.returncode == 0 or not any(message in result.stdout for message in
                    ('unsolved goals', 'omega could not prove')):
                raise RuntimeError(f'{name}: did not fail a proof obligation\n{result.stdout}\n{result.stderr}')
            print(f'cache mutation rejected: {name}')


if __name__ == '__main__':
    main()
