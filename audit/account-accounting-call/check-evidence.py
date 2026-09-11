#!/usr/bin/env python3
"""Check reused full-Lido identities and fresh actual getter/proxy fixtures; no compile."""
from pathlib import Path
import base64,hashlib,json,subprocess,tarfile
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
B=Path('/tmp/lido-address-steth-quote');A=B/'audit/address-steth-quote-call';PIN='ee24f9dc158ed25cec118a8ab8cd3a4fc59942f1'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');COREPIN='17005714f151e5502c559932319a3f2f74ac2436'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def git(repo,*args):return subprocess.check_output(['git','-C',str(repo),*args])
def keccak(data):return subprocess.check_output(['cast','keccak'],input='0x'+data.hex(),text=True).strip()
receipt=json.loads((A/'receipt.json').read_text())
for rel,h in receipt['files'].items():
 assert sha(B/rel)==h and (B/rel).read_bytes()==git(B,'show',PIN+':'+rel),rel
original=json.loads((A/'lido-compiler-artifact.json').read_text())
assert len(original['metadata']['sources'])==37
for rel,info in original['metadata']['sources'].items():assert keccak((A/'solidity/lido'/rel).read_bytes())==info['keccak256'],rel
assert (O/'solidity/artifacts/Lido.json').read_bytes()==(A/'solidity/queue/artifacts/Lido.json').read_bytes()
assert (R/'audit/account-physical-pause/Lido.asm').read_bytes()==(A/'Lido.asm').read_bytes()
assert (O/'solidity/src/DistributionHarness.sol').read_bytes()==(R/'audit/account-physical-pause/solidity/src/DistributionHarness.sol').read_bytes()
assert keccak(b'lido.Lido.lidoLocatorAndMaxExternalRatio')=='0xd92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223'
assert git(CORE,'rev-parse','HEAD').decode().strip()==COREPIN
freshSources=json.loads((O/'fresh-source-identities.json').read_text())
tarpath=Path('/tmp/lido-address-request-oz/openzeppelin-contracts-4.4.1.tgz')
assert sha(tarpath)==freshSources['openzeppelin_tarball_sha256']
pack=freshSources['openzeppelin_pack_record']
assert pack['version']=='4.4.1' and pack['name']=='@openzeppelin/contracts'
assert hashlib.sha1(tarpath.read_bytes()).hexdigest()==pack['shasum']
assert 'sha512-'+base64.b64encode(hashlib.sha512(tarpath.read_bytes()).digest()).decode()==pack['integrity']
with tarfile.open(tarpath) as tf:
 for rel,h in freshSources['sources'].items():
  data=(O/'solidity/src'/rel).read_bytes();assert hashlib.sha256(data).hexdigest()==h
  if rel.startswith('contracts/'):
   assert data==git(CORE,'show',COREPIN+':'+rel)
  else:
   assert data==tf.extractfile('package/'+rel.removeprefix('@openzeppelin/contracts-v4.4/')).read()
records={}
for source,name in [('LidoLocator.sol','LidoLocator'),('OssifiableProxy.sol','OssifiableProxy'),('DistributionHarness.sol','DistributionHarness'),('AccountingCall.t.sol','AccountingCallTest'),('AccountingCall.t.sol','RawLocator')]:
 artifact=json.loads((O/'solidity/artifacts'/source/(name+'.json')).read_text())
 meta=artifact['metadata']
 assert meta['compiler']['version']=='0.8.9+commit.e5eed63a'
 assert meta['settings']['optimizer']=={'enabled':True,'runs':200}
 assert meta['settings']['evmVersion']=='byzantium'
 for rel,info in meta['sources'].items():assert keccak((O/'solidity'/rel).read_bytes())==info['keccak256'],rel
 snapshot=O/(name+'-compiler-artifact.json');snapshot.write_text(json.dumps(artifact,separators=(',',':'))+'\n')
 if name in ['LidoLocator','OssifiableProxy']:(O/(name+'.asm')).write_text(artifact['assembly']+'\n')
 records[name]={'sources':len(meta['sources']),'artifact_sha256':sha(snapshot),'compiler':meta['compiler'],'settings':meta['settings']}
assert records['LidoLocator']['sources']==2 and records['OssifiableProxy']['sources']==7 and records['AccountingCallTest']['sources']==11
(O/'compiler-identities.json').write_text(json.dumps({'borrowed_provider':PIN,'borrowed_path':str(B),'borrowed_receipt_hashes':len(receipt['files']),'full_Lido_inputs':37,'core_pin':COREPIN,'lido_compiler':original['metadata']['compiler'],'lido_settings':original['metadata']['settings'],'full_Lido_assembly_path':'audit/account-physical-pause/Lido.asm','full_Lido_assembly_sha256':sha(A/'Lido.asm'),'Lido_deployment_artifact_sha256':sha(O/'solidity/artifacts/Lido.json'),'fresh_source_bodies':len(freshSources['sources']),'fresh_artifacts':records,'forge':subprocess.check_output(['forge','--version'],text=True).strip()},indent=2)+'\n')
print('PASS: 111 reused provider hashes, all37 full-Lido metadata inputs and exact full deployment/assembly; nine exact getter/proxy source bodies; fresh2/7/11-input artifacts and exact physical locator Keccak. No compiler or Forge run in checker.')
