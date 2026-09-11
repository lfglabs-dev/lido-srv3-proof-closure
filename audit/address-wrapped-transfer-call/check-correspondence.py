#!/usr/bin/env python3
"""Read exact pinned sources, artifact metadata, layout and legacy assembly.
Only write this new dossier. Does not execute or rebuild a Solidity contract."""
from pathlib import Path
import hashlib,json,base64,subprocess,tarfile
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
OLD=ROOT/'audit/address-wrapped-token-call';SOL=OUT/'solidity'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
BASE='1d0709e937934bd9d8eaaaa84dd59504d9810255'
def git(repo,*args):return subprocess.check_output(['git','-C',str(repo),*args])
def sha(data):return hashlib.sha256(data).hexdigest()
def keccak(data):return subprocess.check_output(['cast','keccak','0x'+data.hex()],text=True).strip()
reused={}
def exact_old(p):
 rel=str(p.relative_to(ROOT));assert p.read_bytes()==git(ROOT,'show',BASE+':'+rel)
 reused[rel]=sha(p.read_bytes());return p
sources=[];packages={}
for project,version,coreversion,prefix in [('token','3.4.0','0.6.12','@openzeppelin/contracts/'),('queue','4.4.1','0.8.9','@openzeppelin/contracts-v4.4/')]:
 archive=exact_old(OLD/'solidity/packages'/('openzeppelin-contracts-'+version+'.tgz'))
 meta=json.loads(exact_old(OLD/'solidity/packages'/('npm-pack-'+version+'.json')).read_text())[0]
 assert 'sha512-'+base64.b64encode(hashlib.sha512(archive.read_bytes()).digest()).decode()==meta['integrity']
 packages[version]={k:meta[k] for k in ['version','integrity']}
 folder=OLD/'solidity/token/src' if project=='token' else SOL/'src'
 with tarfile.open(archive) as tar:
  for p in sorted(folder.rglob('*.sol')):
   rel=str(p.relative_to(folder))
   if project=='token':exact_old(p)
   else:assert p.read_bytes()==exact_old(OLD/'solidity/queue/src'/rel).read_bytes()
   if rel.startswith('core/'):
    origin=PIN+':contracts/'+coreversion+'/'+rel[5:];expected=git(CORE,'show',origin)
   elif rel.startswith(prefix):
    origin='npm@'+version+':'+rel[len(prefix):];expected=tar.extractfile('package/'+rel[len(prefix):]).read()
   else:continue
   assert p.read_bytes()==expected
   sources.append(dict(path=str(p.relative_to(ROOT)),sha256=sha(expected),origin=origin))
oldtoken=exact_old(OLD/'solidity/queue/artifacts/WstETH.json')
assert oldtoken.read_bytes()==(SOL/'artifacts/WstETH.json').read_bytes()
assert (SOL/'test/ActualWrappedToken.t.sol').read_bytes()==exact_old(OLD/'solidity/queue/test/ActualWrappedToken.t.sol').read_bytes()
artifacts={}
for name,artifact,folder in [('token',oldtoken,OLD/'solidity/token'),('queue',SOL/'compiler-artifact.json',SOL),('tests',SOL/'test-compiler-artifact.json',SOL)]:
 meta=json.loads(artifact.read_text())['metadata']
 for rel,item in meta['sources'].items():assert keccak((folder/rel).read_bytes())==item['keccak256'],rel
 artifacts[name]=dict(path=str(artifact.relative_to(ROOT)),sha256=sha(artifact.read_bytes()),metadata=meta)
layout=json.loads(exact_old(OLD/'solidity/token/storage-layout.json').read_text())
slots={s['label']:(int(s['slot']),s['offset']) for s in layout['storage']}
assert slots['_balances']==(0,0) and slots['_allowances']==(1,0)
source=(ROOT/'LidoSRv3/Audit/Source/AddressWrappedTransferCalls.lean').read_text()
oldsource=exact_old(ROOT/'LidoSRv3/Audit/Source/AddressWrappedTokenCalls.lean').read_text()
assert 'Compiler.Proofs.mappingSlotLocation 0 owner.val 0' in oldsource
assert 'Compiler.Proofs.nestedMappingSlotLocation 1 owner.val spender.val 0' in source
selector=subprocess.check_output(['cast','sig','transferFrom(address,address,uint256)'],text=True).strip();assert selector=='0x23b872dd' and selector in source
# Independent canonical mapping preimages for the executed native fixture.
enc=lambda n:n.to_bytes(32,'big')
first=keccak(enc(1)+enc(1));nested=keccak(enc(99)+bytes.fromhex(first[2:]));balance=keccak(enc(1)+enc(0))
asm=exact_old(OLD/'solidity/token/WstETH.asm').read_text()
assert '_transfer(sender, recipient, amount)' in asm and '_allowances[sender][_msgSender()]' in asm
assert '_balances[sender] = _balances[sender].sub' in asm and '_balances[recipient].add' in asm
result=dict(core_pin=PIN,base_commit=BASE,exact_old_inputs=reused,sources=sources,packages=packages,compiler_artifacts=artifacts,layout=slots,transferFrom_selector=selector,independent_preimages=dict(balance_owner1=balance,allowance_owner1_inner=first,allowance_owner1_spender99=nested),scope='Actual token artifact/legacy assembly/layout reused byte-identically from 1d07; all token/npm/core sources rechecked. Queue and extended tests freshly compiled. Existing source helpers consume ordered physical locations; no deployed identity or full compiler-equivalence theorem.')
(OUT/'correspondence-inputs.json').write_text(json.dumps(result,indent=2)+'\n')
print(f'PASS {len(reused)} exact prior inputs; {len(sources)} Git/npm source bodies; token/queue/test metadata {len(artifacts["token"]["metadata"]["sources"])}/{len(artifacts["queue"]["metadata"]["sources"])}/{len(artifacts["tests"]["metadata"]["sources"])}; balances0 allowances1 nested preimages and selector.')
