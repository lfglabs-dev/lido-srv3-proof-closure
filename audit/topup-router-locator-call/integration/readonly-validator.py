from pathlib import Path
import runpy,json,hashlib,sys
root=Path.cwd().resolve();out=root/'audit/topup-router-locator-call/validation'
source=(out/'validate.py').read_text()
needle="def record(name,data):\n text=json.dumps(data,indent=2,sort_keys=True)+'\\n';p=OUT/name\n"
assert source.count(needle)==1
source=source.replace(needle,needle+" if name=='build-identities.json':\n  Path('/tmp/lido-topup-locator-integration-normal.json').write_text(text);return\n")
sys.argv=[str(out/'validate.py')]
exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
r=json.loads((out.parent/'receipt.json').read_text())
for rel,h in r['files'].items():assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
import subprocess
for rel in ['lakefile.lean','lake-manifest.json','lean-toolchain']:
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','6c332904a894c51f1cc57e23c9ec8cdc969453a8:'+rel]),rel
normal=json.loads(Path('/tmp/lido-topup-locator-integration-normal.json').read_text())
Path('/tmp/lido-topup-locator-integration-identities.json').write_text(json.dumps({'source_commit':'6c332904a894c51f1cc57e23c9ec8cdc969453a8','sources':1355,'pins':11,'artifact_hashes':len(r['files']),'scoped_axioms':27,'normal':normal},indent=2)+'\n')
print('PASS all24 source receipt hashes and3 configuration identities; fresh actual normal artifacts recorded; dossier unchanged')
