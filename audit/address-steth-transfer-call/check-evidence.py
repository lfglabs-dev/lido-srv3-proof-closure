#!/usr/bin/env python3
"""Compare full pinned bodies and reused compiler evidence; no compiler rerun.
Writes this dossier's deterministic compiler-identities.json and two artifacts.
"""
from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
OLD=R/'audit/address-steth-conversion-call';QUOTE=R/'audit/address-steth-quote-call'
BASE='107e57e53ad4b1bd459a062d887bbcac85be6e41';CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def git(repo,*xs):return subprocess.check_output(['git','-C',str(repo),*xs])
def run(*xs):return subprocess.check_output(xs,text=True).strip()
def keccak(b):return run('cast','keccak','0x'+b.hex())
records={'parent':BASE,'core_pin':PIN,'scope':'Reused complete old compiler objects and source bytes, fresh 0.8.9 test compilation only. This is correspondence evidence, not a bytecode-refinement theorem.'}
for dossier in [OLD,QUOTE]:
 receipt=json.loads((dossier/'receipt.json').read_text())
 for p,h in receipt['files'].items():assert sha(R/p)==h and (R/p).read_bytes()==git(R,'show',BASE+':'+p),p
 records[dossier.name+'_receipt_hashes']=len(receipt['files'])
ident=json.loads((QUOTE/'solidity/lido/source-identities.json').read_text());assert ident['core_pin']==PIN and len(ident['sources'])==37
for rel,h in ident['sources'].items():
 p=QUOTE/'solidity/lido/src'/rel
 assert sha(p)==h and p.read_bytes()==git(R,'show',BASE+':'+str(p.relative_to(R))),rel
 if rel.startswith('contracts/'):assert p.read_bytes()==git(CORE,'show',PIN+':'+rel),rel
records['original_full_lido_inputs']=ident
lido=json.loads((QUOTE/'lido-compiler-artifact.json').read_text());m=lido['metadata']
assert len(m['sources'])==37 and m['compiler']['version']=='0.4.24+commit.e67f0147'
assert m['settings']['optimizer']=={'enabled':True,'runs':200} and m['settings']['evmVersion']=='byzantium'
for src,info in m['sources'].items():assert keccak((QUOTE/'solidity/lido'/src).read_bytes())==info['keccak256'],src
assert (QUOTE/'Lido.asm').read_bytes()==(lido['assembly']+'\n').encode()
for name in ['Lido','WstETH']:
 p=O/'solidity/artifacts'/(name+'.json')
 assert p.read_bytes()==(OLD/'solidity/queue/artifacts'/(name+'.json')).read_bytes()
 records[name+'_deployment_sha256']=sha(p)
 if name=='Lido':
  a=json.loads(p.read_text())
  for k in ['bytecode','deployedBytecode']:assert a[k]['object']==lido[k]['object']
  assert a['metadata']==m
records['reused_full_assemblies']={str(p.relative_to(R)):sha(p) for p in [QUOTE/'Lido.asm',QUOTE/'BatchHarness.asm',R/'audit/address-wrapped-token-call/solidity/token/WstETH.asm']}
for p in records['reused_full_assemblies']:assert (R/p).read_bytes()==git(R,'show',BASE+':'+p)
for p in (O/'solidity/src').rglob('*.sol'):assert p.read_bytes()==(OLD/'solidity/queue/src'/p.relative_to(O/'solidity/src')).read_bytes(),p
records['unchanged_queue_inputs']=18
for name,rel in [('BatchHarness','BatchHarness.sol/BatchHarness.json'),('TransferTest','Transfer.t.sol/TransferTest.json')]:
 compiled=O/'solidity/artifacts'/rel
 if not compiled.exists():compiled=O/(name+'-compiler-artifact.json')
 a=json.loads(compiled.read_text());meta=a['metadata']
 assert meta['compiler']['version']=='0.8.9+commit.e5eed63a'
 assert meta['settings']['optimizer']=={'enabled':True,'runs':200} and meta['settings']['evmVersion']=='london'
 for src,info in meta['sources'].items():assert keccak((O/'solidity'/src).read_bytes())==info['keccak256'],src
 if name=='BatchHarness':
  previous=json.loads((QUOTE/'BatchHarness-compiler-artifact.json').read_text())
  for k in ['bytecode','deployedBytecode']:assert a[k]['object']==previous[k]['object']
  assert meta==previous['metadata']
 (O/(name+'-compiler-artifact.json')).write_text(json.dumps(a,separators=(',',':'))+'\n')
 records[name]={'sha256':sha(O/(name+'-compiler-artifact.json')),'compiler':meta['compiler'],'settings':meta['settings'],'source_count':len(meta['sources'])}
# Full-Lido actual transfer tags, not standalone-StETH storage assumptions.
asm=(QUOTE/'Lido.asm').read_text()
def tag(n,end):return asm.split('    tag_'+str(n)+':',1)[1].split('    tag_'+str(end)+':',1)[0]
body=tag(494,511);assert body.index('tag_137')<body.index('tag_603')<body.index('tag_605')
move=tag(603,605)
order=['TRANSFER_FROM_ZERO_ADDR','TRANSFER_TO_ZERO_ADDR','TRANSFER_TO_STETH_CONTRACT','_whenNotStopped()','shares[_sender]','BALANCE_EXCEEDED','currentSenderShares.sub(_sharesAmount)','sstore','shares[_recipient]','sload','shares[_recipient].add(_sharesAmount)']
pos=0
for part in order:pos=move.index(part,pos)+len(part)
assert move.count('sstore')==2 and move.count('sload')==2
sender=tag(1093,1094);assert re.search(r'shares \*/\s+0x0',sender) and sender.index('mstore')<sender.index('keccak256')<sender.index('sload')
debit=tag(1095,1096);assert debit.index('sstore')<debit.index('keccak256',debit.index('sstore'))<debit.index('sload')
assert re.search(r'uint256 data.*?tag_430:\s*/\*.*?\*/\s+sload',asm,re.S)
pause=tag(397,399);assert 'tag_430' in pause and 'iszero\n      iszero' in pause and 'and' not in re.sub(r'/\*.*?\*/','',pause,flags=re.S)
assert '0x1' in tag(422,123) and 'tag_422' in tag(307,310)
events=tag(605,609);assert events.count('log3')==2 and events.index('Transfer(_from')<events.index('TransferShares(_from')
active=keccak(b'lido.Pausable.activeFlag');assert active=='0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece' and active[2:] in asm
assert run('cast','sig','transfer(address,uint256)')=='0xa9059cbb'
vectors=[]
for a in [0,3,99,2**160-1]:
 data=a.to_bytes(32,'big')+bytes(32);assert len(data)==64
 vectors.append({'owner':str(a),'preimage_hex':data.hex(),'keccak256':keccak(data)})
records['mapping_vectors']=vectors;records['active_slot']=active
records['event_topics']={s:keccak(s.encode()) for s in ['Transfer(address,address,uint256)','TransferShares(address,address,uint256)']}
for h in records['event_topics'].values():assert h[2:] in events
records['assembly_checks']=['transfer307→494→forward137→movement603→events605→true422','full Lido mapping base0; clean160/key MSTORE+base MSTORE→KECCAK64→qualified SLOAD','sender debit SSTORE before fresh recipient KECCAK/SLOAD; checked add then recipient SSTORE','whole-word active flag SLOAD430/nonzero; all guard priorities','Transfer then TransferShares LOG3 actual token/share quantities']
records['tools']={'forge':run('forge','--version'),'cast':run('cast','--version')}
(O/'compiler-identities.json').write_text(json.dumps(records,indent=2)+'\n')
print('PASS parent91 + quote111 receipt hashes; exact37 full Lido sources/metadata; unchanged full Lido/WstETH deployments and three full assemblies; unchanged18 queue inputs/objects; fresh19-source test metadata; active preimage, selector, two event topics, four exact64-byte mapping vectors, actual legacy transfer order.')
