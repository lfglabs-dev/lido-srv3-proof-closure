#!/usr/bin/env python3
"""Reject transitive, staged, vendor and ignored compiler-input mutations."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], stderr=subprocess.DEVNULL).decode().strip()


def initialize(root):
    root.mkdir(parents=True, exist_ok=True)
    git(root, 'init', '-q')
    git(root, 'config', 'user.email', 'fixture@example.invalid')
    git(root, 'config', 'user.name', 'Guard fixture')


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        initialize(root)
        core = root / 'lido-core'
        initialize(core)
        dependency = core / 'contracts/0.8.25/sr/SRStorage.sol'
        dependency.parent.mkdir(parents=True)
        dependency.write_text('// pinned transitive dependency\n')
        git(core, 'add', '.')
        git(core, 'commit', '-qm', 'fixture')
        pin = git(core, 'rev-parse', 'HEAD')
        vendor = root / 'audit/account-fee-distribution/solidity/vendor/Math.sol'
        vendor.parent.mkdir(parents=True)
        vendor.write_text('// pinned vendor\n')
        (root / '.gitignore').write_text('lido-core/\n*.extra.sol\n')
        scripts = root / 'scripts'
        scripts.mkdir()
        guard = scripts / 'check_differential_sources.sh'
        guard.write_text((ROOT / 'scripts/check_differential_sources.sh').read_text().replace(
            '17005714f151e5502c559932319a3f2f74ac2436', pin))
        git(root, 'add', '.')
        git(root, 'commit', '-qm', 'fixture')

        def check(expected):
            result = subprocess.run(['bash', str(guard)], capture_output=True, text=True)
            assert (result.returncode == 0) == expected, result.stdout + result.stderr

        check(True)
        for path, repo in [(dependency, core), (vendor, root)]:
            original = path.read_text()
            path.write_text(original + '// mutation\n')
            check(False)
            git(repo, 'add', str(path.relative_to(repo)))
            check(False)
            git(repo, 'reset', '-q', 'HEAD', '--', str(path.relative_to(repo)))
            path.write_text(original)
            check(True)
        extra = vendor.parent / 'ignored.extra.sol'
        extra.write_text('// unexpected input\n')
        check(False)
        extra.unlink()
        check(True)
    print('differential source guard: clean control passes; transitive/staged/vendor/ignored mutants rejected')


if __name__ == '__main__':
    main()
