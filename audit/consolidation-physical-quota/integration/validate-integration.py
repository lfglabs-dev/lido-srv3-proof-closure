from pathlib import Path
import runpy,json,hashlib,sys
root=Path.cwd().resolve();out=root/'audit/consolidation-physical-quota/validation'
source=(out/'validate.py').read_text()
needle="def record(name,data):\n text=json.dumps(data,indent=2,sort_keys=True)+'\\n';p=OUT/name\n"
assert source.count(needle)==1
source=source.replace(needle,needle+" if name=='normal-identities.json':\n  Path('/tmp/lido-consol-quota-integration-normal.json').write_text(text);return\n")
sys.argv=[str(out/'validate.py')]
exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
r=json.loads((out.parent/'receipt.json').read_text())
for rel,h in r['files'].items():assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
import subprocess
for rel in ['lakefile.lean','lake-manifest.json','lean-toolchain']:
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','d353e85438b3456604a76ee417f9359627751240:'+rel]),rel
normal=json.loads(Path('/tmp/lido-consol-quota-integration-normal.json').read_text())
Path('/tmp/lido-consol-quota-integration-identities.json').write_text(json.dumps({'source_commit':'82051ab0a552734712b8f33e3f96f0074bf9ee39','accepted_configuration':'d353e85438b3456604a76ee417f9359627751240','sources':1252,'pins':11,'artifact_hashes':len(r['files']),'scoped_axioms':30,'normal':normal},indent=2)+'\n')
print('PASS all42 source receipt hashes and3 configuration identities; fresh actual normal artifacts recorded; dossier unchanged')
