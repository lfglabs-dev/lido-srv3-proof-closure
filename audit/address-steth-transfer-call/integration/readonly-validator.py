from pathlib import Path
import runpy,hashlib,json
root=Path.cwd().resolve(); out=root/'audit/address-steth-transfer-call'; captured={}; old=Path.write_text

def compare(self,data,*a,**kw):
 p=self.resolve()
 if p in [out/'source-inputs.json',out/'axioms.json',out/'runtime-inputs.json']:
  assert p.read_text()==data,p
  captured[p.name]=json.loads(data)
  return len(data)
 assert root not in p.parents,p
 return old(self,data,*a,**kw)
Path.write_text=compare
try: runpy.run_path(str(out/'validate.py'),run_name='__main__')
finally: Path.write_text=old
r=json.loads((out/'receipt.json').read_text())
for rel,h in r['files'].items(): assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
for rel in ['lake-manifest.json','lean-toolchain']:
 import subprocess
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','f1d91e3a8ad9829e92ab2e8ff443e391449a36bc:'+rel]),rel
assert (root/'lakefile.lean').read_bytes()==subprocess.check_output(['git','show','7f369fc63f5cdf32436693130e298a8e835d3f33:lakefile.lean'])
normal={rel:hashlib.sha256((root/'.lake/build/lib/lean'/Path(rel).with_suffix('.olean')).read_bytes()).hexdigest() for rel in r['files'] if rel.endswith('.lean') and rel.startswith('LidoSRv3/')}
Path('/tmp/lido-address-transfer-integration-identities.json').write_text(json.dumps({'source_commit':'f1d91e3a8ad9829e92ab2e8ff443e391449a36bc','sources':len(captured['source-inputs.json']['entries']),'pins':len(captured['source-inputs.json']['package_pins']),'artifact_hashes':len(r['files']),'scoped_axioms':len(captured['axioms.json']),'normal_olean_sha256':normal},indent=2)+'\n')
Path('/tmp/lido-address-transfer-integration-scoped-axioms.json').write_text(json.dumps(captured['axioms.json'],indent=2)+'\n')
print('PASS all source receipt hashes, actual normal oleans recorded; no candidate dossier mutation')
