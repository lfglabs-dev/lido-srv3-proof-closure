#!/usr/bin/env python3
"""Materialize the exact composition and pinned Verity runtime dependency closure."""
import hashlib
import json
from pathlib import Path
import subprocess
ROOT = Path(__file__).resolve().parents[4]
DEST = ROOT.parent / 'temp/alloc2-runtime'
BASE = 'c7adae04416704a839d56333efad003f0a0f46b7'
def main():
    assert subprocess.check_output(['git','-C',str(DEST),'rev-parse','HEAD'],text=True).strip() == BASE
    identity = json.loads((ROOT/'audit/trio/alloc2/composition/source-identity.json').read_text())
    files = {}
    for name, digest in identity['files'].items():
        data = subprocess.check_output(['git','-C',str(ROOT),'show',identity['producer']+':'+name]) if '/TrioAlloc1/' in name else (ROOT/name).read_bytes()
        assert hashlib.sha256(data).hexdigest() == digest, name
        files[name] = data
    for name in ('Library.lean','Vectors.lean','lakefile.lean','lake-manifest.json'):
        source = Path(__file__).parent/name
        files[str(source.relative_to(ROOT))] = source.read_bytes()
    for name, data in files.items():
        target = DEST/name
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(data)
    result = {'base':BASE,'producer':identity['producer'],'verity':'e977aaad6e1a9e92e0132d41b3d33a14135a4d46',
              'files':{name:hashlib.sha256(data).hexdigest() for name,data in sorted(files.items())}}
    (Path(__file__).parent/'source-identity.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'Materialized {len(files)} runtime source/config files')
if __name__ == '__main__':
    main()
