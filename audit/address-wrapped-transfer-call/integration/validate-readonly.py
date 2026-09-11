from pathlib import Path
import runpy,hashlib,json
root=Path.cwd().resolve(); out=root/'audit/address-wrapped-transfer-call'; captured={}; old=Path.write_text

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
for rel,h in r['hashes'].items(): assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
for rel,h in r['config_hashes'].items(): assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
normal={rel:hashlib.sha256((root/'.lake/build/lib/lean'/Path(rel).with_suffix('.olean')).read_bytes()).hexdigest() for rel in r['hashes'] if rel.endswith('.lean') and rel.startswith('LidoSRv3/')}
Path('/tmp/lido-address-transfer-integration-identities.json').write_text(json.dumps({'source_commit':'a9c6e2b1f7d3edcf5764082d7e266bb1df8fb42a','sources':len(captured['source-inputs.json']['entries']),'pins':len(captured['source-inputs.json']['package_pins']),'artifact_hashes':len(r['hashes']),'scoped_axioms':len(captured['axioms.json']),'normal_olean_sha256':normal},indent=2)+'\n')
Path('/tmp/lido-address-transfer-integration-scoped-axioms.json').write_text(json.dumps(captured['axioms.json'],indent=2)+'\n')
print('PASS all source receipt hashes, actual normal oleans recorded; no candidate dossier mutation')
