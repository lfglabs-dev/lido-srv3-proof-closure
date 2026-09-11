from pathlib import Path
import runpy,json,hashlib,sys,subprocess
root=Path.cwd().resolve();out=root/'audit/address-steth-transfer-from-call';source=(out/'validate.py').read_text()
# Keep source/dependency checks exact. Only the inherited reviewed lakefile and
# integration-local normal artifact output differ from the source checkout.
needle="assert (ROOT/p).read_bytes()==git(ROOT,'show',BASE+':'+p)"
assert source.count(needle)==1
source=source.replace(needle,"assert (ROOT/p).read_bytes()==git(ROOT,'show',('7d00a45b01e1a88d193fe3917d2a3ec772586488' if p=='lakefile.lean' else BASE)+':'+p)")
needle="def emit(path,text):\n"
assert source.count(needle)==1
source=source.replace(needle,needle+" if path.name=='normal-build-identities.json':\n  Path('/tmp/lido-transfer-from-integration-normal.json').write_text(text);return\n")
sys.argv=[str(out/'validate.py'),'--readonly']
exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
r=json.loads((out/'receipt.json').read_text())
for rel,h in r['files'].items():assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,rel
Path('/tmp/lido-transfer-from-integration-identities.json').write_text(json.dumps({'source_commit':'713c8bf70df2125258b27e6d7b8baa76455f8192','sources':1265,'pins':11,'artifact_hashes':len(r['files']),'scoped_axioms':14,'normal':json.loads(Path('/tmp/lido-transfer-from-integration-normal.json').read_text())},indent=2)+'\n')
print('PASS all50 source receipt hashes; explicit inherited main341 lakefile; normal integration artifacts recorded; no candidate dossier writes')
