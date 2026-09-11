#!/usr/bin/env python3
"""Check current normal imports, pinned inputs and ordinary axioms. --write records JSON; default compares."""
from pathlib import Path
import argparse,hashlib,json,subprocess,importlib.util,re
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='295e6c676b61de1815b7027a49ed8bc5fe5b8b3f'
MODULE='LidoSRv3.Tests.TopupRouterLocatorCall'
NEW=['LidoSRv3/Audit/Source/TopupRouterLocatorCall.lean','LidoSRv3/Audit/Guarantees/PTopupRouterLocatorCall.lean','LidoSRv3/Tests/TopupRouterLocatorCall.lean']
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
selector=keccak.new(digest_bits=256,data=b'stakingRouter()').hexdigest()[:8];assert selector=='ef6c064c'
record('compiler-check.json',dict(scope='Reused byte-identical complete 2519-line GatewayWitnessHarness IR; exact22 pinned/vendored fixture bodies and metadata; no solc or Forge rerun',sources=checked,ir_sha256=sha(SOL/'GatewayWitnessHarness.ir'),selector=selector))
# Retained full compiler IR and exact full335 public conjunction.
kept=['input.json','output.json','GatewayWitnessHarness.ir','compiler-identities.json','compile.py']
for n in kept:assert (SOL/n).read_bytes()==git(ROOT,'show',BASE+':'+str((SOL/n).relative_to(ROOT)))
ir=(SOL/'GatewayWitnessHarness.ir').read_text();assert len(ir.splitlines())==2519
plain=re.sub(r'/\*.*?\*/','',ir,flags=re.S);plain=re.sub(r'\s+','',plain)
# Full ordered entry segment, including temporal prefix and address consumption.
loc=plain.index('mstore(_21,shl(226,0x3bdb0193))')
get=plain.index('mstore(_24,shl(224,0xf85c6ceb))')
assert plain.index('ifgt(sum,0xffffffffffffffff)')<plain.index('gt(timestamp(),and(sum,0xffffffffffffffff))')<plain.index('mstore(_20,shl(225,0x588a30eb))')<loc<get
segment=plain[loc:get]
assert 'extcodesize' not in segment
assert 'staticcall(gas(),and(loadimmutable("3343"),sub(shl(160,1),1)),_21,4,_21,32)' in segment
assert 'returndatacopy(pos,0,returndatasize())revert(pos,returndatasize())' in segment
assert segment.index('finalize_allocation(_21,_23)')<segment.index('ifslt(sub(add(_21,_23),_21),32)')<segment.index('letvalue_2:=mload(_21)')<segment.index('ifiszero(eq(value_2,and(value_2,sub(shl(160,1),1))))')
assert 'letexpr_7:=0' in segment and 'expr_7:=value_2' in segment
assert 'let_24:=mload(64)' in segment
assert 'staticcall(gas(),and(expr_7,sub(shl(160,1),1)),_24,36,_24,32)' in plain[get:]
assert 'mstore(add(memPtr_3,32),expr_8)' in plain
old=(ROOT/'LidoSRv3/Audit/Guarantees/PTopupTimingHistory.lean').read_text()
a=old.index('    IntermediateEffects credentialCursor',old.index('theorem actual_timing_'))
old=old[a:old.index(' := by',a)]
new=(ROOT/NEW[1]).read_text();a=new.index('    IntermediateEffects credentialCursor')
new=new[a:new.index('\ntheorem actual_locator_',a)].rstrip()
assert old==new
# Fresh fixture evidence, separate from the unchanged 2519-line compiled mapping.
F=ROOT/'audit/topup-router-locator-call/solidity';fresh=json.loads((F/'receipt.json').read_text())
from Crypto.Hash import keccak
fixture='audit/topup-router-locator-call/solidity/TopupRouterLocator.t.sol'
expected={n:hashlib.sha256(v['content'].encode()).hexdigest() for n,v in inp['sources'].items()}
expected[fixture]=sha(ROOT/fixture);assert expected==fresh['source_sha256']
assert sha(F/'forge.log')==fresh['log_sha256']
assert '[PASS]' in (F/'forge.log').read_text() and '8 passed; 0 failed' in (F/'forge.log').read_text()
for name,info in fresh['artifacts'].items():
 assert sha(F/(name+'.json'))==info['sha256']
 artifact=json.loads((F/(name+'.json')).read_text());meta=json.loads(artifact['rawMetadata'])
 assert meta['compiler']['version']=='0.8.25+commit.b61c2a91'
 assert meta['sources']==info['metadata_sources'] and meta['settings']==info['settings']
 assert meta['settings']['optimizer']=={'enabled':True,'runs':200} and meta['settings']['viaIR'] and meta['settings']['evmVersion']=='cancun'
 for name,data in meta['sources'].items():
  body=(ROOT/fixture).read_bytes() if name==fixture else inp['sources'][name]['content'].encode()
  assert '0x'+keccak.new(digest_bits=256,data=body).hexdigest()==data['keccak256']
record('correspondence.json',dict(core=PIN,selector=selector,
 compiler_artifacts={str((SOL/n).relative_to(ROOT)):sha(SOL/n) for n in kept},
 full_prior_public_conjunction_byte_identity=True,fresh_runtime_inputs=len(expected),fresh_fixture_receipt_sha256=sha(F/'receipt.json'),
 source_mapping={'topUp163-184;IR372-479':'length/config, block distance, uint64 root-age and prior timestamp before locator',
  'topUp185;IR480-511':'actual gateway STATICCALL immutable locator,4-byte ef6c064c, bubble then min32 allocation then signed head then canonical160',
  'topUp189;IR512-538':'decoded expr7 is actual credentials target; _24 free pointer is next from locator allocation; actual bytes32 word consumed by witness leaf',
  'IR1685-1695':'actual scalar allocation, checked64 next and unsigned wrap guard; bounds derived under success',
  'existing entire335 suffix':'selected ctx.sender qualifies physical router storage/module caller/block cap/continuation; exact intermediate world, attempts and produced total retained in public',
  'topUp233-235;IR1113-1130':'same actual loop total controls final fresh postmodule packed history and event'},
 boundaries=['Locator immutable address is supplied; arbitrary STATIC callee is not deployed locator body refinement',
  'ctx.sender becomes decoded router for the covered inner path; no claim of executing the omitted outer gateway-to-router topUp CALL or closing role/pause',
  'Locator cursor is an explicit scalar phase input, actual next consumed by credentials getter; module returnBuffer remains separate; full memory/gas not modeled',
  'Inherited typed calls, SHA/root proof and physical-storage hash semantics; no new frame, stage, fit, role equality or successful lookup premise',
  'Fresh Forge8 runtime fixtures do not constitute Lean kernel proofs or production bytecode correspondence']))
P=ROOT/'.lake/packages/evmyul'
ffi=['EvmYul/FFI/ffi.lean','EvmYul/FFI/ffi.c','sha2/sha-256.c','sha2/sha-256.h','keccak256/sha3.c','keccak256/sha3.h']
prior=ROOT/'audit/topup-credential-call/validation';vectors=['root.bin','proof-0.bin','proof-1.bin','proof-2.bin','vector.json','make-vector.py']
for n in vectors:assert (prior/n).read_bytes()==git(ROOT,'show',BASE+':'+str((prior/n).relative_to(ROOT)))
record('runtime-inputs.json',dict(scope='Fresh8 native FFI IO diagnostics; unchanged independently generated f008 SHA tree/proofs; no native theorem axiom',
 vectors={str((prior/n).relative_to(ROOT)):sha(prior/n) for n in vectors},files={x:sha(P/x) for x in ffi},
 repositories={n:git(P/n,'rev-parse','HEAD').decode().strip() for n in ['sha2','keccak256']}))
print('PASS',len(entries),'sources,',len(pins),'pins,',len(scopes),'ordinary foundation-only scopes,',len(checked),'exact reused compiler inputs, 3 normal modules')
