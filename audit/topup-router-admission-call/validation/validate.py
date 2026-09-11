#!/usr/bin/env python3
"""Check current normal imports, pinned inputs and ordinary axioms. --write records JSON; default compares."""
from pathlib import Path
import argparse,hashlib,json,subprocess,importlib.util,re
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='d353e85438b3456604a76ee417f9359627751240'
MODULE='LidoSRv3.Tests.TopupRouterAdmissionCallRegression'
NEW=['LidoSRv3/Audit/Source/TopupRouterAdmissionCallGates.lean','LidoSRv3/Audit/Source/TopupRouterAdmissionCall.lean','LidoSRv3/Audit/Guarantees/PTopupRouterAdmissionCall.lean','LidoSRv3/Tests/TopupRouterAdmissionCallRegression.lean']
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
 names.update(namespace+'.'+n for n in re.findall(r'^theorem (\w+)',text,re.M))
 base=p[:-5];st=json.loads((ROOT/'.lake/build/ir'/(base+'.setup.json')).read_text());tr=json.loads((ROOT/'.lake/build/lib/lean'/(base+'.trace')).read_text())
 assert st['options']=={} and st['plugins']==[] and not tr['synthetic'];assert 'skipKernelTC' not in json.dumps(tr)
 artifacts.append(dict(source=p,sha256=sha(ROOT/p),olean_sha256=sha(ROOT/'.lake/build/lib/lean'/(base+'.olean')),setup_sha256=sha(ROOT/'.lake/build/ir'/(base+'.setup.json')),trace_sha256=sha(ROOT/'.lake/build/lib/lean'/(base+'.trace'))))
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.ROOT=ROOT
scopes=c.environment_dependencies(sorted(names),MODULE,None);assert all(a<=c.FOUNDATIONAL_AXIOMS for a in scopes.values())
record('axioms.json',{n:sorted(a) for n,a in scopes.items()});record('build-identities.json',artifacts)
# Read-only default checks current source/provider identities and complete Solidity artifacts.
from Crypto.Hash import keccak
SOL=OUT.parent/'solidity';CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
assert git(CORE,'rev-parse','HEAD').decode().strip()==PIN
inp=json.loads((SOL/'input.json').read_text());output=json.loads((SOL/'output.json').read_text())
oldids=json.loads((ROOT/'audit/topup-module-nocode/compiler-source-identities.json').read_text())['source_sha256']
assert inp['settings']==json.loads((ROOT/'audit/topup-module-nocode/compiler-settings.json').read_text())
normalized={};checked=[]
for name,data in sorted(inp['sources'].items()):
 body=data['content'].encode();h=hashlib.sha256(body).hexdigest()
 assert h==oldids[name],name
 if name.startswith('/tmp/lido-ssz-proof-committed/lido-core/'):
  relative=name.split('/lido-core/',1)[1];assert body==git(CORE,'show',PIN+':'+relative)
 elif name.startswith('/tmp/lido-topup-wei-deps/package/'):
  relative='@openzeppelin/contracts-v5.2/'+name.split('/package/',1)[1]
  assert body==git(ROOT,'show',BASE+':audit/deposit-dsm-call/solidity/src/'+relative)
 else:
  relative=name;assert body==git(ROOT,'show',BASE+':'+relative)
 normalized[relative]=data
 checked.append({'path':relative,'cached_path':name,'sha256':h})
assert len(oldids)==len(checked)
oldkey='audit/topup-batch-consumer/solidity/TopupBatchConsumer.t.sol'
assert output['contracts'][oldkey]['BatchRouter']['irOptimized']==(ROOT/'audit/topup-module-nocode/router-ir.txt').read_text()
routerkey='/tmp/lido-ssz-proof-committed/lido-core/contracts/0.8.25/sr/StakingRouter.sol'
assert output['contracts'][routerkey]['StakingRouter']['irOptimized']==(SOL/'StakingRouter.cached.ir').read_text()
new='audit/topup-router-admission-call/solidity/TopupRouterAdmissionCall.t.sol'
normalized[new]={'content':(ROOT/new).read_text()}
receipt=json.loads((SOL/'receipt.json').read_text())
assert receipt['source_sha256']=={n:hashlib.sha256(v['content'].encode()).hexdigest() for n,v in sorted(normalized.items())}
assert receipt['log_sha256']==sha(SOL/'forge.log')
assert '17 passed; 0 failed; 0 skipped' in (SOL/'forge.log').read_text()
assert '(runs: 256,' in (SOL/'forge.log').read_text()
artifacts=[]
for name,identity in receipt['artifacts'].items():
 p=SOL/(name+'.json');assert sha(p)==identity['sha256']
 artifact=json.loads(p.read_text());meta=json.loads(artifact['rawMetadata'])
 assert meta['compiler']['version']=='0.8.25+commit.b61c2a91'
 assert meta['settings']['optimizer']=={'enabled':True,'runs':200} and meta['settings']['viaIR'] and meta['settings']['evmVersion']=='cancun'
 assert meta['sources']==identity['metadata_sources'] and meta['settings']==identity['settings']
 for source,entry in meta['sources'].items():
  assert entry['keccak256']=='0x'+keccak.new(digest_bits=256,data=normalized[source]['content'].encode()).hexdigest(),source
 if name in ['StakingRouter','BatchRouter']:
  assert artifact['irOptimized']==(SOL/(name+'.ir')).read_text()
 artifacts.append({'name':name,'sha256':sha(p),'source_count':len(meta['sources'])})
# Primary correspondence checks the complete *fresh* production router IR.
ir=(SOL/'StakingRouter.ir').read_text()
plain=re.sub(r'/\*.*?\*/','',ir,flags=re.S);plain=re.sub(r'///[^\n]*','',plain);plain=re.sub(r'\s+','',plain)
entry=plain[plain.index('case0x3e7ae601{'):plain.index('case',plain.index('case0x3e7ae601{')+10)]
ordered=['ifcallvalue()','0x3224316f','staticcall(','abi_decode_address_fromMemory','fun_checkAppAuth','0x626c4319','0x07e11acb','0x500585ad','fun_requireModuleIdExists','shr(224,','0x21','0x322e64fb','shr(232,','0x0b972523','0xf2cfa87d','delegatecall(','0xe78a5875','abi_decode_bool_fromMemory','0x5609c247','0x783b8a65','call(gas(),']
pos=0
for token in ordered:
 found=entry.find(token,pos);assert found>=0,(token,pos);pos=found+len(token)
def fn(name):
 start=plain.index('function'+name+'(');end=plain.find('function',start+8);return plain[start:end if end>=0 else None]
assert 'ifiszero(eq(value,iszero(iszero(value))))' in fn('abi_decode_bool_fromMemory')
# Constructor has a one-argument same-name decoder; select the runtime signature.
a=plain.index('functionabi_decode_address_fromMemory(headStart,dataEnd)');b=plain.find('function',a+8);addressbody=plain[a:b]
assert 'ifslt(sub(dataEnd,headStart),32)' in addressbody and 'ifiszero(eq(value,and(value,sub(shl(160,1),1))))' in addressbody
assert 'caller()' in fn('fun_checkAppAuth') and '0xea8e4eb5' in fn('fun_checkAppAuth')
assert '0x6a0eb141' in fn('fun_requireModuleIdExists')
assert 'or(gt(newFreePtr,0xffffffffffffffff),lt(newFreePtr,memPtr))' in fn('finalize_allocation') and '0x41' in fn('finalize_allocation')
selectors={signature:keccak.new(digest_bits=256,data=signature.encode()).hexdigest()[:8] for signature in ['topUpGateway()','canDeposit()','EmptyKeysList()','ArraysLengthMismatch()','WrongPubkeyLength()','StakingModuleUnregistered()','StakingModuleNotActive()','WrongWithdrawalCredentialsType()','LidoDepositsPaused()','NotAuthorized()']}
gates=(ROOT/NEW[0]).read_text()
for value in selectors.values():assert '0x'+value in gates,value
prior=(ROOT/'LidoSRv3/Audit/Guarantees/PTopupEntryAdmission.lean').read_text();a=prior.index('    TopupEntryAdmission.Admitted');b=prior.index(' := by',a)
assert prior[a:b] in (ROOT/NEW[2]).read_text(),'entire TOPUP342 conclusion must be retained'
record('compiler-check.json',{'scope':'28 cached full input identities reused from accepted no-code packet; 29 fresh Forge sources and five metadata-checked artifacts; complete fresh router/callee fixture IR; no cached/fresh bytecode identity claim.', 'pin':PIN,'cached_sources':checked,'fresh_artifacts':artifacts,'selectors':selectors,'ir_sha256':sha(SOL/'StakingRouter.ir'),'ir_lines':len(ir.splitlines())})
# Existing tree content remains unchanged; authorized work is additive.
subprocess.run(['git','diff','--exit-code',BASE,'--',*[p for p in git(ROOT,'ls-tree','-r','--name-only',BASE).decode().splitlines()]],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
record('summary.json',{'status':'PASS','base':BASE,'base_tree':git(ROOT,'rev-parse',BASE+'^{tree}').decode().strip(),'normal_modules':len(NEW),'ordinary_scopes':len(scopes),'actual_source_inputs':len(entries),'package_pins':len(pins),'solidity_tests':17,'solidity_fuzz_runs':256,'full_prior_conjunction':True,'unchanged_trust_checker_sha256':sha(ROOT/'scripts/check_trust_axioms.py')})
print('PASS: normal providers, ordinary axioms, exact old inputs/pins, full TOPUP342 conjunction, fresh full-router Solidity artifacts and error/decoder order')
