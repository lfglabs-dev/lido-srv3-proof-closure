from pathlib import Path
import runpy,hashlib,json
root=Path.cwd().resolve(); out=root/'audit/account-physical-pause'; captured={}; old=Path.write_text

def compare(self,data,*a,**kw):
 p=self.resolve()
 if p in [out/'source-inputs.json',out/'axioms.json',out/'solidity-identities.json']:
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
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','62669fad69b4bae620458eff7130b2d5e0017720:'+rel]),rel
normal={module:hashlib.sha256((root/'.lake/build/lib/lean'/Path(module.replace('.','/')).with_suffix('.olean')).read_bytes()).hexdigest() for module in ['ReportFeePhysicalPause','LidoSRv3.Audit.Guarantees.PAccount1PhysicalPause','LidoSRv3.Tests.AccountPhysicalPause']}
Path('/tmp/lido-account-pause-integration-identities.json').write_text(json.dumps({'source_commit':'62669fad69b4bae620458eff7130b2d5e0017720','sources':len(captured['source-inputs.json']['entries']),'pins':len(captured['source-inputs.json']['package_pins']),'artifact_hashes':len(r['files']),'scoped_axioms':len(captured['axioms.json']),'normal_olean_sha256':normal},indent=2)+'\n')
Path('/tmp/lido-account-pause-integration-scoped-axioms.json').write_text(json.dumps(captured['axioms.json'],indent=2)+'\n')
print('PASS all source receipt hashes, actual normal oleans recorded; no candidate dossier mutation')
