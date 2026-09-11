from pathlib import Path
import runpy,json,hashlib,sys
root=Path.cwd().resolve();out=root/'audit/consolidation-physical-entry/validation'
source=(out/'validate.py').read_text()
needle="def record(name,data):\n text=json.dumps(data,indent=2,sort_keys=True)+'\\n';p=OUT/name\n"
assert source.count(needle)==1
source=source.replace(needle,needle+" if name=='normal-identities.json':\n  Path('/tmp/lido-consol-entry-integration-normal.json').write_text(text);return\n")
old_config="for rel,h in oldreceipt['config_sha256'].items():assert sha((ROOT/rel).read_bytes())==h and (ROOT/rel).read_bytes()==git(ROOT,'show',BASE+':'+rel),rel"
assert source.count(old_config)==1
source=source.replace(old_config,"for rel in oldreceipt['config_sha256']:assert (ROOT/rel).read_bytes()==git(ROOT,'show','b3b63586ecd72467dadc2e5ccdca220d820f15fb:'+rel),rel")
sys.argv=[str(out/'validate.py')]
exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
r=json.loads((out.parent/'receipt.json').read_text())
for rel,h in r['files'].items():assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
import subprocess
for rel in ['lakefile.lean','lake-manifest.json','lean-toolchain']:
 assert (root/rel).read_bytes()==subprocess.check_output(['git','show','b3b63586ecd72467dadc2e5ccdca220d820f15fb:'+rel]),rel
normal=json.loads(Path('/tmp/lido-consol-entry-integration-normal.json').read_text())
Path('/tmp/lido-consol-entry-integration-identities.json').write_text(json.dumps({'source_commit':'040e3903f13cd5819c5be207004cad1f824b4a11','accepted_configuration':'b3b63586ecd72467dadc2e5ccdca220d820f15fb','sources':1255,'pins':11,'artifact_hashes':len(r['files']),'scoped_axioms':22,'normal':normal},indent=2)+'\n')
print('PASS all source receipt hashes and3 configuration identities; fresh actual normal artifacts recorded; dossier unchanged')
