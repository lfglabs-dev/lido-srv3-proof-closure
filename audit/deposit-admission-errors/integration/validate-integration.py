from pathlib import Path
import runpy,json,hashlib,sys
root=Path.cwd().resolve();out=root/'audit/deposit-admission-errors/validation'
source=(out/'validate.py').read_text()
needle="def record(name,data):\n text=json.dumps(data,indent=2,sort_keys=True)+'\\n';p=OUT/name\n"
assert source.count(needle)==1
source=source.replace(needle,needle+" if name=='normal-identities.json':\n  Path('/tmp/lido-deposit-errors-integration-normal.json').write_text(text);return\n")
sys.argv=[str(out/'validate.py')]
exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
r=json.loads((out.parent/'receipt.json').read_text())
for rel,h in r['files'].items():assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
import subprocess
for rel in ['lakefile.lean','lake-manifest.json','lean-toolchain']:
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','4207bb0578b0a6821cd1d78b1f3a4bb08f277905:'+rel]),rel
normal=json.loads(Path('/tmp/lido-deposit-errors-integration-normal.json').read_text())
Path('/tmp/lido-deposit-errors-integration-identities.json').write_text(json.dumps({'source_commit':'a279b5661f5b1f6c588bacd2918dd2e0cd14cb2d','accepted_configuration':'4207bb0578b0a6821cd1d78b1f3a4bb08f277905','sources':1317,'pins':11,'artifact_hashes':len(r['files']),'scoped_axioms':25,'normal':normal},indent=2)+'\n')
print('PASS all18 source receipt hashes and3 configuration identities; fresh actual normal artifacts recorded; dossier unchanged')
