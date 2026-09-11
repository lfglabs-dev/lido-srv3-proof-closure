#!/usr/bin/env python3
"""Exact source/metadata/layout bindings; no rebuild or runtime claims."""
from pathlib import Path
import hashlib,json,base64,subprocess,tarfile,re
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
def sha(b):return hashlib.sha256(b).hexdigest()
sol=OUT/'solidity';entries=[];packages={}
for project,version,coreversion,ozprefix in [('token','3.4.0','0.6.12','@openzeppelin/contracts/'),('queue','4.4.1','0.8.9','@openzeppelin/contracts-v4.4/')]:
 archive=sol/'packages'/('openzeppelin-contracts-'+version+'.tgz')
 meta=json.loads((sol/'packages'/('npm-pack-'+version+'.json')).read_text())[0]
 assert meta['version']==version
 assert 'sha512-'+base64.b64encode(hashlib.sha512(archive.read_bytes()).digest()).decode()==meta['integrity']
 packages[version]={k:meta[k] for k in ['name','version','shasum','integrity']}
 with tarfile.open(archive) as tar:
  for p in sorted((sol/project/'src').rglob('*.sol')):
   rel=str(p.relative_to(sol/project/'src'))
   if rel.startswith('core/'):
    source='contracts/'+coreversion+'/'+rel[len('core/'):]
    expected=subprocess.check_output(['git','-C',str(CORE),'show',PIN+':'+source]);origin=PIN+':'+source
   elif rel.startswith(ozprefix):
    source='package/'+rel[len(ozprefix):];expected=tar.extractfile(source).read();origin='npm@'+version+':'+source
   else:continue
   assert p.read_bytes()==expected,p
   entries.append(dict(path=str(p.relative_to(ROOT)),origin=origin,sha256=sha(expected)))
artifacts={}
for project,p in [('token',sol/'queue/artifacts/WstETH.json'),('queue',sol/'queue/compiler-artifact.json')]:
 artifact=json.loads(p.read_text());meta=artifact['metadata'];sources={}
 for rel,v in meta['sources'].items():
  data=(sol/project/rel).read_bytes()
  actual=subprocess.check_output(['cast','keccak','0x'+data.hex()],text=True).strip()
  assert actual==v['keccak256'],rel
  sources[rel]=actual
 artifacts[project]=dict(path=str(p.relative_to(ROOT)),sha256=sha(p.read_bytes()),compiler=meta['compiler'],settings=meta['settings'],sources=sources)
layout=json.loads((sol/'token/storage-layout.json').read_text())
slots={s['label']:(int(s['slot']),s['offset']) for s in layout['storage']}
assert slots['_balances']==(0,0) and slots['_totalSupply']==(2,0) and slots['stETH']==(7,0)
source=(ROOT/'LidoSRv3/Audit/Source/AddressWrappedTokenCalls.lean').read_text()
assert 'Compiler.Proofs.mappingSlotLocation 0 owner.val 0' in source
assert re.search(r'def supplySlot : Nat := 2\b',source) and re.search(r'def stETHSlot : Nat := 7\b',source)
selectors={signature:subprocess.check_output(['cast','sig',signature],text=True).strip() for signature in ['unwrap(uint256)','getPooledEthByShares(uint256)','transfer(address,uint256)']}
bridge=(ROOT/'LidoSRv3/Audit/Verity/AddressRecipientCallBridge.lean').read_text()
assert selectors['unwrap(uint256)'] in source
assert re.search('def getPooledEthBySharesSelector : Nat := '+selectors['getPooledEthByShares(uint256)'],bridge)
assert re.search('def erc20TransferSelector : Nat := '+selectors['transfer(address,uint256)'],bridge)
# The queue deploys this exact checked 0.6.12 creation artifact, without changing its bytecode.
test=(sol/'queue/test/ActualWrappedToken.t.sol').read_text();assert 'vm.getCode("artifacts/WstETH.json")' in test
result=dict(pin=PIN,sources=entries,packages=packages,compiler_artifacts=artifacts,layout=slots,selectors=selectors,scope='Current exact Git/npm source and compiler metadata identities. Layout/selector binding and actual cross-compiler artifact path; no general compiler or deployed identity theorem.')
(OUT/'correspondence-inputs.json').write_text(json.dumps(result,indent=2)+'\n')
print(f'PASS {len(entries)} vendored dependencies; token {len(artifacts["token"]["sources"])} and queue {len(artifacts["queue"]["sources"])} compiler source identities; layout 0/2/7 and 3 selectors.')
