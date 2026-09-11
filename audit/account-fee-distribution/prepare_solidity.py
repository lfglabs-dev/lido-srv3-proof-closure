#!/usr/bin/env python3
from pathlib import Path
import base64,hashlib,io,json,re,subprocess,tarfile,urllib.request
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent/'solidity'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
OUT.mkdir(exist_ok=True)
packages={}; receipts={}
for name,version in [('@aragon/os','4.4.0'),('openzeppelin-solidity','2.0.0')]:
    meta=json.loads(urllib.request.urlopen('https://registry.npmjs.org/'+name+'/'+version).read())
    data=urllib.request.urlopen(meta['dist']['tarball']).read();integrity=meta['dist']['integrity'];algo,digest=integrity.split('-',1)
    assert base64.b64encode(hashlib.new(algo,data).digest()).decode()==digest
    tar=tarfile.open(fileobj=io.BytesIO(data),mode='r:gz')
    packages[name]={m.name.removeprefix('package/'):tar.extractfile(m).read() for m in tar.getmembers() if m.isfile()}
    receipts[name]=dict(version=version,tarball=meta['dist']['tarball'],integrity=integrity,sha256=hashlib.sha256(data).hexdigest())
files={}
def visit(path):
    if path in files:return
    if path.startswith('contracts/'):
        data=(CORE/path).read_bytes();assert subprocess.check_output(['git','-C',str(CORE),'show',PIN+':'+path])==data
    else:
        name=next(n for n in packages if path.startswith(n+'/'));data=packages[name][path[len(name)+1:]]
    files[path]=data
    target=OUT/'vendor'/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    for imported in re.findall(r'import\s+(?:[^;]*?from\s+)?[\"\']([^\"\']+)[\"\']',data.decode()):
        if imported.startswith('.'):
            import posixpath
            imported=posixpath.normpath(posixpath.join(posixpath.dirname(path),imported))
        visit(imported)
visit('contracts/0.4.24/StETH.sol')
(OUT/'source-identities.json').write_text(json.dumps(dict(pin=PIN,packages=receipts,sources={p:hashlib.sha256(b).hexdigest() for p,b in files.items()}),indent=2)+'\n')
print(f'PASS: copied {len(files)} complete original source dependencies; npm tarball integrity and pinned core bodies checked.')
