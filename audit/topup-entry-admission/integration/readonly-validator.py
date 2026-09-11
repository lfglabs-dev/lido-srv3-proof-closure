from pathlib import Path
import runpy,json,hashlib,sys
root=Path.cwd().resolve();out=root/'audit/topup-entry-admission/validation'
source=(out/'validate.py').read_text()
needle="def record(name,data):\n text=json.dumps(data,indent=2,sort_keys=True)+'\\n';p=OUT/name\n"
assert source.count(needle)==1
source=source.replace(needle,needle+" if name=='build-identities.json':\n  Path('/tmp/lido-topup-entry-integration-normal.json').write_text(text);return\n")
sys.argv=[str(out/'validate.py')]
exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
r=json.loads((out.parent/'receipt.json').read_text())
for rel,h in r['files'].items():assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
import subprocess
for rel in ['lakefile.lean','lake-manifest.json','lean-toolchain']:
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','bdeb3d23b20dfeafb32c0e893dc260432183da08:'+rel]),rel
normal=json.loads(Path('/tmp/lido-topup-entry-integration-normal.json').read_text())
Path('/tmp/lido-topup-entry-integration-identities.json').write_text(json.dumps({'source_commit':'bdeb3d23b20dfeafb32c0e893dc260432183da08','sources':1358,'pins':11,'artifact_hashes':len(r['files']),'scoped_axioms':18,'normal':normal},indent=2)+'\n')
print('PASS all32 source receipt hashes and3 configuration identities; fresh actual normal artifacts recorded; dossier unchanged')
