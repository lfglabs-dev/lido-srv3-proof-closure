#!/usr/bin/env python3
"""Check current normal imports, pinned inputs and ordinary axioms. --write records JSON; default compares."""
from pathlib import Path
import argparse,hashlib,json,subprocess,importlib.util,re
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='53871e66833bd45190eb83dffc15439ceafa9c42'
MODULE='LidoSRv3.Tests.TopupEntryAdmission'
NEW=['LidoSRv3/Audit/Source/TopupEntryAdmission.lean','LidoSRv3/Audit/Guarantees/PTopupEntryAdmission.lean','LidoSRv3/Tests/TopupEntryAdmission.lean']
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
selector=keccak.new(digest_bits=256,data=b'AccessControlUnauthorizedAccount(address,bytes32)').hexdigest()[:8];assert selector=='e2517d3f'
record('compiler-check.json',dict(scope='Reused byte-identical complete 2519-line GatewayWitnessHarness IR; exact22 pinned/vendored fixture bodies and metadata; no solc or Forge rerun',sources=checked,ir_sha256=sha(SOL/'GatewayWitnessHarness.ir'),selector=selector))

# Complete inherited compiler identity plus direct entry-guard lowering.
for n in ['input.json','output.json','GatewayWitnessHarness.ir','compiler-identities.json','compile.py']:
 assert (SOL/n).read_bytes()==git(ROOT,'show',BASE+':'+str((SOL/n).relative_to(ROOT)))
ir=(SOL/'GatewayWitnessHarness.ir').read_text();assert len(ir.splitlines())==2519
plain=re.sub(r'/\*.*?\*/','',ir,flags=re.S);plain=re.sub(r'\s+','',plain)
entry=plain[plain.index('case0x1141aa5a{'):plain.index('case0x150',plain.index('case0x1141aa5a{'))] if 'case0x150' in plain else plain[plain.index('case0x1141aa5a{'):]
assert entry.index('ifcallvalue()')<entry.index('let_9:=0x5e4bd437')<entry.index('mstore(0,_9)')<entry.index('let_10:=keccak256(0,64)')<entry.index('mstore(0,caller())')<entry.index('mstore(32,_10)')<entry.index('and(sload(keccak256(0,64)),0xff)')<entry.index('mstore(_11,shl(224,0xe2517d3f))')<entry.index('fun_checkResumed()')<entry.index('ifiszero(expr_length)')
assert 'mstore(32,1295953201772911215391058989745868821651057887752387839782086074958115661824)' in entry
assert int('02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800',16)==1295953201772911215391058989745868821651057887752387839782086074958115661824
pause=plain[plain.index('functionfun_checkResumed()'):plain.index('functionread_from_calldatat_bool')]
assert 'lt(timestamp(),sload(0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02))' in pause
assert 'mstore(_1,shl(227,0x0286f073))revert(_1,4)' in pause
assert (0x0286f073<<3)==0x14378398
assert keccak.new(digest_bits=256,data=b'TOP_UP_ROLE').hexdigest()=='5e4bd437d29fad01c10cdcfff414f0d6b0e84b96d2dade88d780d45b5630696b'
assert keccak.new(digest_bits=256,data=b'ResumedExpected()').hexdigest()[:8]=='14378398'
# Every byte of the complete prior public conclusion remains in the consumer.
prior=(ROOT/'LidoSRv3/Audit/Guarantees/PTopupRouterLocatorCall.lean').read_text();start=prior.index('theorem actual_locator_');decl=prior[start:prior.index(' := by',start)];conclusion=decl.split(' :\n',1)[1].strip()
assert '('+conclusion+') := by' in (ROOT/NEW[1]).read_text()
vectors=json.loads((OUT/'mapping-vectors.json').read_text());tsv=''
for v in vectors:
 inner=bytes.fromhex(v['inner_hex']);outer=bytes.fromhex(v['outer_hex']);assert len(inner)==len(outer)==64
 ih=keccak.new(digest_bits=256,data=inner).hexdigest();oh=keccak.new(digest_bits=256,data=outer).hexdigest()
 assert '0x'+ih==v['inner_hash'] and int(oh,16)==int(v['slot']) and int.from_bytes(outer[:32],'big')==int(v['caller']) and outer[32:]==bytes.fromhex(ih)
 assert inner[:32]==bytes.fromhex('5e4bd437d29fad01c10cdcfff414f0d6b0e84b96d2dade88d780d45b5630696b') and int.from_bytes(inner[32:],'big')==int('02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800',16)
 tsv+=v['caller']+'\t'+v['slot']+'\n'
assert (OUT/'mapping-vectors.tsv').read_text()==tsv
record('correspondence.json',dict(core=PIN,full_prior_conclusion=True,compiler_ir_sha256=sha(SOL/'GatewayWitnessHarness.ir'),mapping_vectors=4,
 source_mapping={'TopUpGateway160 / fullIR337-370':'typed outer head precedes role; two64-byte Keccaks role/base then caller/inner; SLOAD lowbyte admission; full68-byte error',
 'AccessControlUpgradeable hasRole/_checkRole':'actual namespace role mapping, msg.sender, lowbyte not entireword or canonical1',
 'PausableUntil / fullIR1864-1876':'timestamp < full256-bit resume word; equality resumes; exact4-byte14378398; before arraylengths/lookup',
 'public consumer':'entire prior338 conclusion plus executed physical gates and same actual suffix result/world'}))
P=ROOT/'.lake/packages/evmyul'
ffi=['EvmYul/FFI/ffi.lean','EvmYul/FFI/ffi.c','sha2/sha-256.c','sha2/sha-256.h','keccak256/sha3.c','keccak256/sha3.h']
record('runtime-inputs.json',dict(files={x:sha(P/x) for x in ffi},repositories={n:git(P/n,'rev-parse','HEAD').decode().strip() for n in ['sha2','keccak256']},vectors={n:sha(OUT/n) for n in ['mapping-vectors.json','mapping-vectors.tsv']}))
print('PASS',len(entries),'sources,',len(pins),'pins,',len(scopes),'ordinary scopes,',len(checked),'exact reused compiler inputs; full old public conclusion, both mapping preimages and physical guard lowering')
