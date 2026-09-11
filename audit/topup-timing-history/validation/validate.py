#!/usr/bin/env python3
"""Check current normal imports, pinned inputs and ordinary axioms. --write records JSON; default compares."""
from pathlib import Path
import argparse,hashlib,json,subprocess,importlib.util,re
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='367412569a2dd85972ab8bdab8304d261fa7b4ec'
MODULE='LidoSRv3.Tests.TopupTimingHistory'
NEW=['LidoSRv3/Audit/Source/TopupTimingHistory.lean','LidoSRv3/Audit/Guarantees/PTopupTimingHistory.lean','LidoSRv3/Tests/TopupTimingHistory.lean']
write=argparse.ArgumentParser();write.add_argument('--write',action='store_true');write=write.parse_args().write
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def git(repo,*a):return subprocess.check_output(['git','-C',str(repo),*a])
def record(name,data):
 text=json.dumps(data,indent=2,sort_keys=True)+'\n';p=OUT/name
 if write:p.write_text(text)
 else:assert p.read_text()==text,name
pins={p['name']:p['rev'] for p in json.loads((ROOT/'lake-manifest.json').read_text())['packages']}
for name,pin in pins.items():assert git(ROOT/'.lake/packages'/name,'rev-parse','HEAD').decode().strip()==pin
setup=json.loads((ROOT/'.lake/build/ir'/Path(MODULE.replace('.','/')+'.setup.json')).read_text());entries=[]
for name,arts in setup['importArts'].items():
 prefix,suffix=arts[0].split('/.lake/build/lib/lean/');actual=Path(prefix)/Path(suffix).with_suffix('.lean')
 if not actual.exists():actual=Path(prefix)/'audit/trio/account-address'/Path(suffix).with_suffix('.lean')
 assert actual.exists(),(name,actual)
 if '/.lake/packages/' in str(actual):
  pkg,rel=str(actual).split('/.lake/packages/',1)[1].split('/',1);local=ROOT/'.lake/packages'/pkg/rel
  assert local.read_bytes()==actual.read_bytes()==git(ROOT/'.lake/packages'/pkg,'show',pins[pkg]+':'+rel),name
  relative='.lake/packages/'+pkg+'/'+rel
 else:
  local=ROOT/Path(suffix).with_suffix('.lean')
  if not local.exists():local=ROOT/'audit/trio/account-address'/Path(suffix).with_suffix('.lean')
  assert local.read_bytes()==actual.read_bytes(),name;relative=str(local.relative_to(ROOT))
  assert Path(arts[0]).read_bytes()==(ROOT/'.lake/build/lib/lean'/suffix).read_bytes(),name
  if relative not in NEW:assert git(ROOT,'show',BASE+':'+relative)==local.read_bytes(),relative
 entries.append(dict(module=name,path=relative,sha256=sha(local)))
for p in NEW:
 if not any(e['path']==p for e in entries):entries.append(dict(module=p[:-5].replace('/','.'),path=p,sha256=sha(ROOT/p)))
record('source-inputs.json',dict(scope='Actual registered regression importArts plus regression; all old local bodies at exact selected base; selected normal oleans compared; package sources at Git pins.',base=BASE,entries=sorted(entries,key=lambda x:x['path']),package_pins=pins))
artifacts=[];names=set()
for p in NEW:
 text=(ROOT/p).read_text();bare=re.sub(r'/\-.*?\-/','',text,flags=re.S);bare=re.sub(r'--[^\n]*','',bare)
 assert not re.search(r'\b(sorry|admit|axiom|native_decide|unsafe|implemented_by)\b',bare),p
 namespace=re.search(r'^namespace (\S+)',text,re.M)[1]
 for n in re.findall(r'^#print axioms (\S+)',text,re.M):names.add(n if n.startswith('LidoSRv3.') else namespace+'.'+n)
 if '/Tests/' in p:
  names.update(namespace+'.'+n for n in re.findall(r'^theorem (\w+)',text,re.M))
 base=p[:-5];st=json.loads((ROOT/'.lake/build/ir'/(base+'.setup.json')).read_text());tr=json.loads((ROOT/'.lake/build/lib/lean'/(base+'.trace')).read_text())
 assert st['options']=={} and st['plugins']==[] and not tr['synthetic'];assert 'skipKernelTC' not in json.dumps(tr)
 artifacts.append(dict(source=p,sha256=sha(ROOT/p),olean_sha256=sha(ROOT/'.lake/build/lib/lean'/(base+'.olean')),setup_sha256=sha(ROOT/'.lake/build/ir'/(base+'.setup.json')),trace_sha256=sha(ROOT/'.lake/build/lib/lean'/(base+'.trace'))))
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.ROOT=ROOT
scopes=c.environment_dependencies(sorted(names),MODULE,None);assert all(a<=c.FOUNDATIONAL_AXIOMS for a in scopes.values())
record('axioms.json',{n:sorted(a) for n,a in scopes.items()});record('build-identities.json',artifacts)
# Exact compiler artifacts and source identities; does not rerun solc.
from Crypto.Hash import keccak
SOL=ROOT/'audit/topup-credential-call/solidity';inp=json.loads((SOL/'input.json').read_text());output=json.loads((SOL/'output.json').read_text());ids=json.loads((SOL/'compiler-identities.json').read_text());checked=[]
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
HARNESS='audit/topup-gateway-witness-batch/solidity/TopupGatewayWitnessBatch.t.sol'
artifact=output['contracts'][HARNESS]['GatewayWitnessHarness'];meta=json.loads(artifact['metadata'])
assert meta['compiler']['version']=='0.8.25+commit.b61c2a91'
assert inp['settings']['optimizer']=={'enabled':True,'runs':200} and inp['settings']['viaIR'] and inp['settings']['evmVersion']=='cancun'
old=json.loads((ROOT/'audit/topup-gateway-witness-batch/solidity/receipt.json').read_text())
for name,data in sorted(inp['sources'].items()):
 body=data['content'].encode();h=hashlib.sha256(body).hexdigest();k=keccak.new(digest_bits=256,data=body).hexdigest()
 if name.startswith('contracts/'):
  assert body==git(CORE,'show',PIN+':'+name);oldname='lido-core/'+name
 elif name.startswith('@openzeppelin/'):
  assert body==git(ROOT,'show',BASE+':audit/deposit-dsm-call/solidity/src/'+name)
  oldname='/tmp/lido-topup-wei-deps/package/'+name.split('/',2)[2]
 else:assert body==git(ROOT,'show',BASE+':'+name);oldname=name
 assert h==ids['sources'][name]['sha256']==old['source_sha256'][oldname]
 assert '0x'+k==meta['sources'][name]['keccak256']
 checked.append(dict(path=name,sha256=h,keccak256=k))
assert set(inp['sources'])==set(meta['sources'])==set(ids['sources'])
assert artifact['irOptimized']+'\n'==(SOL/'GatewayWitnessHarness.ir').read_text()
selector=keccak.new(digest_bits=256,data=b'getStakingModuleWithdrawalCredentials(uint256)').hexdigest()[:8];assert selector=='f85c6ceb'
record('compiler-check.json',dict(scope='Reused byte-identical complete 2519-line GatewayWitnessHarness IR; exact22 pinned/vendored fixture bodies and metadata; no solc or Forge rerun',sources=checked,ir_sha256=sha(SOL/'GatewayWitnessHarness.ir'),selector=selector))
# Retained whole compiler artifact identity, namespace/topic and exact relevant IR.
kept=['input.json','output.json','GatewayWitnessHarness.ir','compiler-identities.json','compile.py']
for n in kept:assert (SOL/n).read_bytes()==git(ROOT,'show',BASE+':'+str((SOL/n).relative_to(ROOT)))
K=lambda b:keccak.new(digest_bits=256,data=b).hexdigest()
seed=int(K(b'lido.TopUpGateway.storage'),16)
root=int(K((seed-1).to_bytes(32,'big')),16)&~255
assert root==int('22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200',16)
ir=(SOL/'GatewayWitnessHarness.ir').read_text()
ir=re.sub(r'/\*.*?\*/','',ir,flags=re.S)
ir=re.sub(r'\s+','',ir)
topic=K(b'LastTopUpChanged(uint256)');assert topic=='4f63efa973ce717a91d9f49d732d45ad08e7847c64ed5633ad99f38424322c55'
assert topic in ir and 'ifgt(sum,0xffffffffffffffff)' in ir
assert 'checked_sub_uint256(number(),value)' in ir
assert 'ifiszero(iszero(var_totalLimits))' in ir
assert 'not(0xffffffffffffffff0000000000000000)' in ir
assert 'and(shl(64,timestamp()),0xffffffff0000000000000000)' in ir
assert 'and(shl(96,number()),shl(96,0xffffffff))' in ir
errors={x:K((x+'()').encode())[:8] for x in ['MinBlockDistanceNotMet','RootIsTooOld','RootPrecedesLastTopUp']}
# Compare whole retained public statement; no dropped old conjunct.
old=(ROOT/'LidoSRv3/Audit/Guarantees/PTopupPhysicalCredentialGetter.lean').read_text()
old=old[old.index('    checkLengths'):old.index(' := by',old.index('    checkLengths'))]
new=(ROOT/NEW[1]).read_text();new=new[new.index('    checkLengths'):new.index('\ndef HistoryEffects')].rstrip()
assert old==new
record('correspondence.json',dict(core=PIN,gateway_root=hex(root),event_topic=topic,error_selectors=errors,
  compiler_artifacts={str((SOL/n).relative_to(ROOT)):sha(SOL/n) for n in kept},
  original_fixture_receipt_sha256=sha(ROOT/'audit/topup-gateway-witness-batch/solidity/receipt.json'),
  full_prior_public_conjunction_byte_identity=True,
  source_mapping={'Storage42-48':'uint32 timestamp bits64/block bits96; uint16 distance128/age144',
    'topUp163-175;IR372-479':'physical lengths/config then short-circuit checked distance then uint64 checked age, old root, prior timestamp',
    '_isBlockDistancePassed323-325;IR2152-2170':'zero last block skips subtraction; checked_sub_uint256; distance comparison',
    '_verifyRootAge380-388;IR450-479':'uint64 ADD overflow before RootIsTooOld then RootPrecedesLastTopUp; no future-time guard',
    'topUp204-228;IR590-995':'same executed loop output; actual witness limits accumulator retained',
    'topUp231-235;IR1113-1130':'executed totalLimits nonzero, fresh packed post-world read, coalesced write, full timestamp event'},
  boundaries=['Typed gateway/router entry composition retains omitted outer router CALL and memory/gas boundary; IR1102-1110 allocator is not executed by this model',
    'LOG represented by existing semantic Log; memory allocation, topic/data byte refinement and gas not claimed',
    'arbitrary callback metadata preserved; timestamp/block history reads actual returned World; no frame premise']))
P=ROOT/'.lake/packages/evmyul'
ffi=['EvmYul/FFI/ffi.lean','EvmYul/FFI/ffi.c','sha2/sha-256.c','sha2/sha-256.h','keccak256/sha3.c','keccak256/sha3.h']
prior=ROOT/'audit/topup-credential-call/validation';vectors=['root.bin','proof-0.bin','proof-1.bin','proof-2.bin','vector.json','make-vector.py']
for n in vectors:assert (prior/n).read_bytes()==git(ROOT,'show',BASE+':'+str((prior/n).relative_to(ROOT)))
record('runtime-inputs.json',dict(scope='Fresh native FFI IO diagnostic; unchanged independently generated f008 SHA tree/proofs; no native theorem axiom',
 vectors={str((prior/n).relative_to(ROOT)):sha(prior/n) for n in vectors},files={x:sha(P/x) for x in ffi},
 repositories={n:git(P/n,'rev-parse','HEAD').decode().strip() for n in ['sha2','keccak256']}))
print('PASS',len(entries),'sources,',len(pins),'pins,',len(scopes),'ordinary foundation-only scopes,',len(checked),'exact reused compiler inputs, 3 normal modules')
