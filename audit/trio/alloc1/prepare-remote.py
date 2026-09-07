#!/usr/bin/env python3
"""Create a private complete-source remote snapshot; never copy compiled caches.

Dependencies are copied from immutable Git objects at lake-manifest revisions.
Only snapshot manifests change Git dependencies to path dependencies. The mission
checkout and canonical manifests are untouched. No credential files are read.
"""
import argparse
import hashlib
import io
import json
import re
from pathlib import Path
import subprocess
import tarfile

parser = argparse.ArgumentParser()
parser.add_argument('--destination', required=True, type=Path)
parser.add_argument('--dependency-cache', required=True, type=Path)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[3]
dest = args.destination.resolve()
if dest.exists():
    raise SystemExit('destination must not exist (preserve existing snapshots)')
dest.mkdir(parents=True)

def git(cwd, *argv):
    return subprocess.check_output(['git', '-C', str(cwd), *argv])

def export(source, rev, target):
    data = git(source, 'archive', '--format=tar', rev)
    target.mkdir(parents=True, exist_ok=True)
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:
        archive.extractall(target, filter='data')

head = git(repo, 'rev-parse', 'HEAD').decode().strip()
export(repo, head, dest)
# Include tracked edits and untracked Lean files while retaining the pinned base.
paths = git(repo, 'ls-files', '-z').split(b'\0')
paths += git(repo, 'ls-files', '--others', '--exclude-standard', '-z').split(b'\0')
for raw in paths:
    if not raw:
        continue
    path = Path(raw.decode())
    source = repo / path
    if source.is_file() and not source.is_symlink():
        target = dest / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(source.read_bytes())
    elif not source.exists() and (dest / path).is_file():
        (dest / path).unlink()
# Flatten pinned Solidity submodule rather than sending a gitlink as a regular file.
solidity_rev = git(repo, 'rev-parse', 'HEAD:lido-core').decode().strip()
export(repo / 'lido-core', solidity_rev, dest / 'lido-core')
manifest = json.loads((repo / 'lake-manifest.json').read_text())
identities = {}
for pkg in manifest['packages']:
    name, rev = pkg['name'], pkg['rev']
    source = args.dependency_cache / name
    # archive itself checks the requested immutable object exists.
    export(source, rev, dest / 'remote-deps' / name)
    identities[name] = rev
# Lake resolves the complete manifest directly, including inherited packages.
manifest['packages'] = [dict(type='path', name=p['name'], scope=p.get('scope', ''),
    dir='remote-deps/' + p['name'], inherited=p['inherited'],
    manifestFile=p['manifestFile'], configFile=p['configFile']) for p in manifest['packages']]
(dest / 'lake-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
# Transport requires regular files. Dereference only links within this snapshot.
materialized_links = []
for path in dest.rglob('*'):
    if path.is_symlink():
        resolved = path.resolve()
        if not resolved.is_relative_to(dest) or not resolved.is_file():
            raise SystemExit(f'unsafe or missing symlink target: {path.relative_to(dest)}')
        data = resolved.read_bytes()
        materialized_links.append(str(path.relative_to(dest)))
        path.unlink()
        path.write_bytes(data)
# The transport rejects URL-router punctuation even in non-Lean documentation.
# Preserve those bytes under safe names and record the bijective relocation map.
relocated = {}
for path in list(dest.rglob('*')):
    if not path.is_file():
        continue
    rel = path.relative_to(dest)
    if any(not re.fullmatch(r'[A-Za-z0-9_.-]+', part) or part.startswith('-') for part in rel.parts):
        if path.suffix in {'.lean', '.c', '.h', '.toml'} or path.name == 'lake-manifest.json':
            raise SystemExit(f'build input needs original unsafe path: {rel}')
        safe = Path('remote-transport-files') / hashlib.sha256(str(rel).encode()).hexdigest()
        (dest / safe).parent.mkdir(exist_ok=True)
        path.rename(dest / safe)
        relocated[str(rel)] = str(safe)
identity = dict(candidate_head=head, solidity=solidity_rev, dependencies=identities,
    materialized_symlinks=materialized_links, relocated_nonbuild_files=relocated,
    transport_only_changes=['flatten lido-core gitlink', 'materialize remote-deps from pinned Git objects',
                            'replace root Lake manifest entries with local paths'])
(dest / 'remote-source-identity.json').write_text(json.dumps(identity, indent=2)+'\n')
subprocess.run(['git', 'init', '-q', str(dest)], check=True)
subprocess.run(['git', '-C', str(dest), 'remote', 'add', 'origin',
                'https://github.com/lfglabs-dev/lido-srv3-proof-closure.git'], check=True)
subprocess.run(['git', '-C', str(dest), 'add', '-f', '.'], check=True)
subprocess.run(['git', '-C', str(dest), '-c', 'user.name=Remote source snapshot',
                '-c', 'user.email=source-snapshot@localhost', 'commit', '-qm',
                'Complete remote source for '+head], check=True)
files = [p for p in dest.rglob('*') if p.is_file() and '.git' not in p.parts]
identity['snapshot_head'] = git(dest, 'rev-parse', 'HEAD').decode().strip()
identity['files'] = len(files)
identity['bytes'] = sum(p.stat().st_size for p in files)
identity['root_manifest_sha256'] = hashlib.sha256((dest/'lake-manifest.json').read_bytes()).hexdigest()
print(json.dumps(identity, indent=2))
