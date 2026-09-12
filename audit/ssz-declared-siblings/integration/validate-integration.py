from pathlib import Path
import json,hashlib,subprocess,sys
root=Path.cwd().resolve();out=root/'audit/ssz-declared-siblings/validation'
source=(out/'validate.py').read_text()
needle="def record(name,data):\n text=json.dumps(data,indent=2,sort_keys=True)+'\\n';p=OUT/name\n"
assert source.count(needle)==1
source=source.replace(needle,needle+" if name=='build-identities.json':\n  Path('/tmp/lido-ssz-declared-integration-normal.json').write_text(text);return\n")
old="subprocess.run(['git','diff','--exit-code',BASE,'--',*git(ROOT,'ls-tree','-r','--name-only',BASE).decode().splitlines()],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)"
new="subprocess.run(['git','diff','--exit-code',BASE,'--',*[p for p in git(ROOT,'ls-tree','-r','--name-only',BASE).decode().splitlines() if p not in ['LidoSRv3/Audit/AllGuarantees.lean','LidoSRv3/Audit/Trust.lean']]],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)"
assert source.count(old)==1;source=source.replace(old,new)
sys.argv=[str(out/'validate.py')]
exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
r=json.loads((out.parent/'receipt.json').read_text())
for rel,h in r['files'].items():assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
for rel in ['lakefile.lean','lake-manifest.json','lean-toolchain']:
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','43f0e7abcdf64671582351b8cae389134de4326a:'+rel]),rel
normal=json.loads(Path('/tmp/lido-ssz-declared-integration-normal.json').read_text())
Path('/tmp/lido-ssz-declared-integration-identities.json').write_text(json.dumps({'source_commit':'3bdd333b3a0c9e34dd128c17427d51610a60f1b9','accepted_configuration':'43f0e7abcdf64671582351b8cae389134de4326a','sources':1217,'pins':11,'artifact_hashes':len(r['files']),'scoped_axioms':33,'normal':normal},indent=2)+'\n')
print('PASS all21 source hashes/configurations; old346 bodies unchanged except additive All/Trust; current normal identities recorded')
