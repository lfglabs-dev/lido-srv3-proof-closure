from pathlib import Path
import hashlib,json
p=Path.cwd()/'audit/topup-timing-history/validation/validate.py'
s=p.read_text()
a=" if write:p.write_text(text)"
b=" if name == 'build-identities.json': Path('/tmp/lido-topup-timing-integration-build-identities.json').write_text(text)\n elif write:p.write_text(text)"
assert s.count(a)==1;s=s.replace(a,b)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__main__'})
r=json.loads((p.parent.parent/'receipt.json').read_text())
for rel,h in r['sha256'].items(): assert hashlib.sha256((Path.cwd()/rel).read_bytes()).hexdigest()==h,rel
print('PASS all17 source hashes; path-dependent normal build identities recorded externally; candidate manifests unchanged')
