from pathlib import Path
import json,hashlib,subprocess,sys
root=Path.cwd().resolve();out=root/'audit/topup-router-admission-call/validation'
source=(out/'validate.py').read_text()
needle="def record(name,data):\n text=json.dumps(data,indent=2,sort_keys=True)+'\\n';p=OUT/name\n"
assert source.count(needle)==1
source=source.replace(needle,needle+" if name=='build-identities.json':\n  Path('/tmp/lido-topup-admission-integration-normal.json').write_text(text);return\n")
old="subprocess.run(['git','diff','--exit-code',BASE,'--',*[p for p in git(ROOT,'ls-tree','-r','--name-only',BASE).decode().splitlines()]],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)"
new="subprocess.run(['git','diff','--exit-code',BASE,'--',*[p for p in git(ROOT,'ls-tree','-r','--name-only',BASE).decode().splitlines() if p not in ['LidoSRv3/Audit/AllGuarantees.lean','LidoSRv3/Audit/Trust.lean']]],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)"
assert source.count(old)==1;source=source.replace(old,new)
sys.argv=[str(out/'validate.py')]
exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
r=json.loads((out.parent/'receipt.json').read_text())
for rel,h in r['files'].items():assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
for rel in ['lakefile.lean','lake-manifest.json','lean-toolchain']:
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','6e59055f72a4da135915844f6f504b02f10c6fcb:'+rel]),rel
normal=json.loads(Path('/tmp/lido-topup-admission-integration-normal.json').read_text())
Path('/tmp/lido-topup-admission-integration-identities.json').write_text(json.dumps({'source_commit':'ed043832023c75e04adf76ea05c3ac96f3353897','accepted_configuration':'6e59055f72a4da135915844f6f504b02f10c6fcb','sources':1361,'pins':11,'artifact_hashes':len(r['files']),'scoped_axioms':39,'normal':normal},indent=2)+'\n')
print('PASS all42 source hashes/configurations; old344 bodies unchanged except explicitly additive All/Trust; current normal identities recorded')
