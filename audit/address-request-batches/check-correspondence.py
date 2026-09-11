#!/usr/bin/env python3
"""Pinned source/metadata and reused actual token identity; writes this dossier only."""
from pathlib import Path
import subprocess,json,hashlib,tarfile,base64
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;S=O/'solidity'
OLD=R/'audit/address-wrapped-token-call';CORE=Path('/tmp/lido-ssz-proof-committed/lido-core')
BASE='ae30a086154dc78196034657953b9a09cc75b48b';PIN='17005714f151e5502c559932319a3f2f74ac2436'
def git(repo,*a):return subprocess.check_output(['git','-C',str(repo),*a])
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def kec(data):return subprocess.check_output(['cast','keccak','0x'+data.hex()],text=True).strip()
reused={}
def old(p):
 rel=str(p.relative_to(R));assert p.read_bytes()==git(R,'show',BASE+':'+rel);reused[rel]=sha(p);return p
sources=[];packages={}
for folder,version,prefix,coreversion in [(OLD/'solidity/token/src','3.4.0','@openzeppelin/contracts/','0.6.12'),(S/'src','4.4.1','@openzeppelin/contracts-v4.4/','0.8.9')]:
 archive=old(OLD/'solidity/packages'/f'openzeppelin-contracts-{version}.tgz');meta=json.loads(old(OLD/'solidity/packages'/f'npm-pack-{version}.json').read_text())[0]
 assert meta['integrity']=='sha512-'+base64.b64encode(hashlib.sha512(archive.read_bytes()).digest()).decode();packages[version]=meta['integrity']
 with tarfile.open(archive) as tar:
  for p in sorted(folder.rglob('*.sol')):
   rel=str(p.relative_to(folder))
   if rel=='BatchHarness.sol':continue
   if folder==S/'src':assert p.read_bytes()==old(OLD/'solidity/queue/src'/rel).read_bytes()
   else:old(p)
   if rel.startswith('core/'):
    origin=PIN+':contracts/'+coreversion+'/'+rel[5:];expected=git(CORE,'show',origin)
   elif rel.startswith(prefix):
    origin='npm@'+version+':'+rel[len(prefix):];expected=tar.extractfile('package/'+rel[len(prefix):]).read()
   else:continue
   assert p.read_bytes()==expected
   sources.append(dict(path=str(p.relative_to(R)),sha256=sha(p),origin=origin))
token=old(OLD/'solidity/queue/artifacts/WstETH.json');assert token.read_bytes()==(S/'artifacts/WstETH.json').read_bytes()
for p in ['storage-layout.json','WstETH.asm']:old(OLD/'solidity/token'/p)
artifacts={}
for name,p,folder in [('token',token,OLD/'solidity/token'),('queue',O/'compiler-artifact.json',S),('test',O/'test-compiler-artifact.json',S)]:
 meta=json.loads(p.read_text())['metadata']
 for rel,info in meta['sources'].items():assert kec((folder/rel).read_bytes())==info['keccak256'],rel
 artifacts[name]=dict(path=str(p.relative_to(R)),sha256=sha(p),metadata=meta)
slot=kec(b'lido.PausableUntil.resumeSinceTimestamp');assert slot=='0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02'
assert slot in (R/'LidoSRv3/Audit/Source/AddressRequestBatches.lean').read_text()
selectors={sig:subprocess.check_output(['cast','sig',sig],text=True).strip() for sig in ['requestWithdrawals(uint256[],address)','requestWithdrawalsWstETH(uint256[],address)','ResumedExpected()']}
asm=(O/'BatchHarness.asm').read_text();assert 'data_ba930d38d363826ce600a5728c59ce313a9b3e31d7a4a14f9fe10008fda6890b '+slot[2:] in asm
for snippet in ['new uint256[](_amounts.length)','_checkResumed()','_checkWithdrawalRequestAmount(_amounts[i])','++i','requestIds[i]']:
 assert snippet in asm,snippet
result=dict(base=BASE,core_pin=PIN,resume_slot=slot,selectors=selectors,packages=packages,reused_inputs=reused,pinned_sources=sources,compiler_artifacts=artifacts,assembly_sha256=sha(O/'BatchHarness.asm'),scope='Full legacy assembly and exact source bodies/metadata. Typed-loop proof omits actual array allocator, ABI/gas/memory and general compiler equivalence. Experimental IR inspection failed; no IR result credited.')
(O/'correspondence-inputs.json').write_text(json.dumps(result,indent=2)+'\n')
print('PASS',len(reused),'reused inputs;',len(sources),'pinned Git/npm bodies; metadata',*[len(v['metadata']['sources']) for v in artifacts.values()],'; physical resume slot/selectors/full legacy assembly')
