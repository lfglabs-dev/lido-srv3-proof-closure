from pathlib import Path
import re,posixpath,subprocess,json,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;core=Path('/tmp/lido-ssz-proof-committed/lido-core');vendor=R/'audit/account-fee-distribution/solidity/vendor';seen={}
def walk(p):
 if p in seen:return
 q=core/p if p.startswith('contracts/') else vendor/p
 data=q.read_bytes()
 if p.startswith('contracts/'):assert data==subprocess.check_output(['git','-C',str(core),'show','17005714f151e5502c559932319a3f2f74ac2436:'+p])
 else:
  ident=json.loads((vendor.parent/'source-identities.json').read_text());assert hashlib.sha256(data).hexdigest()==ident['sources'][p]
 seen[p]=hashlib.sha256(data).hexdigest();out=O/'solidity/lido/src'/p;out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data)
 for x in re.findall(r'import\s+(?:[^;]*?from\s+)?[\"\']([^\"\']+)[\"\']',data.decode()):walk(posixpath.normpath(posixpath.join(posixpath.dirname(p),x)) if x.startswith('.') else x)
walk('contracts/0.4.24/Lido.sol')
(O/'solidity/lido/source-identities.json').write_text(json.dumps(dict(core_pin='17005714f151e5502c559932319a3f2f74ac2436',sources=seen,npm_provenance=json.loads((vendor.parent/'source-identities.json').read_text())['packages']),indent=2)+'\n')
(O/'solidity/lido/foundry.toml').write_text('''[profile.default]
src = "src"
out = "out"
solc_version = "0.4.24"
optimizer = true
optimizer_runs = 200
evm_version = "byzantium"
remappings = ["@aragon/os/=src/@aragon/os/", "openzeppelin-solidity/=src/openzeppelin-solidity/"]
''')
(O/'solidity/lido/.gitignore').write_text('out/\ncache/\n')
print('PASS copied',len(seen),'full pinned Lido dependency inputs; offline original npm bodies verified by accepted hashes')
