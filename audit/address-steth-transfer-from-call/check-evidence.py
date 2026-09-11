#!/usr/bin/env python3
"""Compare full pinned bodies and reused compiler evidence; no compiler rerun.
Writes this dossier's deterministic compiler-identities.json and two artifacts.
"""
from pathlib import Path
import hashlib,json,re,subprocess,sys
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
OLD=R/'audit/address-steth-conversion-call';QUOTE=R/'audit/address-steth-quote-call'
BASE='f1d91e3a8ad9829e92ab2e8ff443e391449a36bc';CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
READONLY='--readonly' in sys.argv
def emit(p,text):
 if READONLY:assert p.read_text()==text,p
 else:p.write_text(text)
def git(repo,*xs):return subprocess.check_output(['git','-C',str(repo),*xs])
def run(*xs):return subprocess.check_output(xs,text=True).strip()
def keccak(b):return run('cast','keccak','0x'+b.hex())
records={'parent':BASE,'core_pin':PIN,'scope':'Reused complete old compiler objects and source bytes, fresh 0.8.9 test compilation only. This is correspondence evidence, not a bytecode-refinement theorem.'}
for dossier in [OLD,QUOTE,R/'audit/address-steth-transfer-call']:
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
for name,rel in [('BatchHarness','BatchHarness.sol/BatchHarness.json'),('TransferFromTest','TransferFrom.t.sol/TransferFromTest.json')]:
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
 emit(O/(name+'-compiler-artifact.json'),json.dumps(a,separators=(',',':'))+'\n')
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
# Additional actual transferFrom path, full-Lido assembly source/profile reused.
entry=tag(149,152)
assert entry.index('caller')<entry.index('tag_492')<entry.index('tag_494')<entry.index('0x1')
spend=tag(492,494)
assert spend.count('keccak256')==2 and spend.count('sload')==1
assert re.search(r'allowances \*/\s+0x1',spend)
assert spend.index('sload')<spend.index('not(0x0)')<spend.index('tag_453')<spend.index('ALLOWANCE_EXCEEDED')<spend.index('tag_423')
assert 'currentAllowance - _amount */\n      sub' in spend
approve=tag(423,427)
assert approve.index('APPROVE_FROM_ZERO_ADDR')<approve.index('APPROVE_TO_ZERO_ADDR')<approve.index('sstore')<approve.index('log3')
assert approve.count('keccak256')==2 and approve.count('sstore')==1 and approve.count('log3')==1
assert re.search(r'allowances \*/\s+0x1',approve)
assert run('cast','sig','transferFrom(address,address,uint256)')=='0x23b872dd'
vs=json.loads((O/'nested-vectors.json').read_text())
for v in vs:
 a,b=int(v['owner']),int(v['spender']);inner=a.to_bytes(32,'big')+(1).to_bytes(32,'big')
 assert v['inner_preimage']==inner.hex() and v['inner_hash']==keccak(inner)
 outer=b.to_bytes(32,'big')+bytes.fromhex(v['inner_hash'][2:])
 assert v['outer_preimage']==outer.hex() and v['outer_hash']==keccak(outer)
records['nested_vectors']=vs;records['active_slot']=active
records['event_topics']={s:keccak(s.encode()) for s in ['Approval(address,address,uint256)','Transfer(address,address,uint256)','TransferShares(address,address,uint256)']}
assert records['event_topics']['Approval(address,address,uint256)'][2:] in approve
for s in ['Transfer(address,address,uint256)','TransferShares(address,address,uint256)']:assert records['event_topics'][s][2:] in events
records['assembly_checks']=['transferFrom149 calls allowance492 before transfer494; caller operand is actual msg.sender; true32 return493','full Lido nested allowance base1 clean160 owner/spender, two64-byte Keccak preimages, fullWord SLOAD','infinite not(0) skips approve, finite allowance guard then raw safe-by-guard SUB; owner/spender guards then SSTORE+Approval LOG3','accepted transfer494→forward137→movement603→events605 reused byte-identically, debit before fresh recipient SLOAD/checkadd','same actual allowance-returned World consumed by conversion and movement; no nonalias or stage/frame premise']
records['permit_fixture_boundary']='New FixtureDomain only supplies standard domain/hash; actual full Lido permit/nonces/signature/_approve execute. No general formal permit/crypto theorem.'
records['tools']={'forge':run('forge','--version'),'cast':run('cast','--version')}
emit(O/'compiler-identities.json',json.dumps(records,indent=2)+'\n')
print('PASS parent45 + conversion91 + quote111 hashes; exact37 full Lido sources/metadata and deployed artifacts; three full assemblies; unchanged18 queue inputs/objects; fresh19-source fixture; allowance-first/infinity/approval order, nested4 vectors and topics')
