#!/usr/bin/env python3
"""Default compares; --write records this new dossier. No builds or compiler runs.
The only execution is ordinary temporary Lean axiom queries against real imports.
"""
from pathlib import Path
import argparse,hashlib,importlib.util,json,re,subprocess,tarfile
from Crypto.Hash import keccak
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='1cd11a4719ce9dec72f0c7dcffde5bcd7848f28d'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
MODULES=['audit.trio.consolidation.PhysicalQuotaSettlement','LidoSRv3.Audit.Guarantees.PConsolidationEth1PhysicalQuota','LidoSRv3.Tests.TrioConsolidation.PhysicalQuotaSettlement']
NEW={m.replace('.','/')+'.lean' for m in MODULES}
p=argparse.ArgumentParser();p.add_argument('--write',action='store_true');WRITE=p.parse_args().write
sha=lambda b:hashlib.sha256(b).hexdigest()
git=lambda repo,*args:subprocess.check_output(['git','-C',str(repo),*args])
def record(name,data):
 text=json.dumps(data,indent=2,sort_keys=True)+'\n';p=OUT/name
 if WRITE:p.write_text(text)
 else:assert p.read_text()==text,name
pins={p['name']:p['rev'] for p in json.loads((ROOT/'lake-manifest.json').read_text())['packages']}
for name,pin in pins.items():assert git(ROOT/'.lake/packages'/name,'rev-parse','HEAD').decode().strip()==pin
setup=json.loads((ROOT/'.lake/build/ir'/(MODULES[-1].replace('.','/')+'.setup.json')).read_text())
entries=[]
for module,arts in setup['importArts'].items():
 prefix,suffix=arts[0].split('/.lake/build/lib/lean/');actual=Path(prefix)/Path(suffix).with_suffix('.lean')
 if not actual.exists():actual=Path(prefix)/'audit/trio/account-address'/Path(suffix).with_suffix('.lean')
 assert actual.exists(),(module,actual)
 if '/.lake/packages/' in str(actual):
  name,rel=str(actual).split('/.lake/packages/',1)[1].split('/',1);local=ROOT/'.lake/packages'/name/rel
  assert local.read_bytes()==actual.read_bytes()==git(ROOT/'.lake/packages'/name,'show',pins[name]+':'+rel),module
  relative='.lake/packages/'+name+'/'+rel
 else:
  local=ROOT/Path(suffix).with_suffix('.lean')
  if not local.exists():local=ROOT/'audit/trio/account-address'/Path(suffix).with_suffix('.lean')
  assert local.read_bytes()==actual.read_bytes(),module
  assert Path(arts[0]).read_bytes()==(ROOT/'.lake/build/lib/lean'/suffix).read_bytes(),module
  relative=str(local.relative_to(ROOT))
  if relative not in NEW:assert local.read_bytes()==git(ROOT,'show',BASE+':'+relative),relative
 entries.append({'module':module,'path':relative,'sha256':sha(local.read_bytes())})
for rel in sorted(NEW):
 if not any(x['path']==rel for x in entries):entries.append({'module':rel[:-5].replace('/','.'),'path':rel,'sha256':sha((ROOT/rel).read_bytes())})
record('source-inputs.json',{'base':BASE,'pins':pins,'sources':sorted(entries,key=lambda x:x['path'])})
names=set();normal=[]
for module in MODULES:
 rel=module.replace('.','/');body=(ROOT/(rel+'.lean')).read_text();ns=re.search(r'^namespace (\S+)',body,re.M)[1]
 bare=re.sub(r'/\-.*?\-/','',body,flags=re.S);bare=re.sub(r'--[^\n]*','',bare)
 assert not re.search(r'\b(sorry|admit|axiom|native_decide|unsafe|implemented_by)\b',bare),rel
 for n in re.findall(r'^#print axioms (\S+)',body,re.M):names.add(ns+'.'+n)
 if '/Tests/' in rel:
  names.update(ns+'.'+n for n in re.findall(r'^theorem (\w+)',body,re.M))
 st=ROOT/'.lake/build/ir'/(rel+'.setup.json');tr=ROOT/'.lake/build/lib/lean'/(rel+'.trace');o=ROOT/'.lake/build/lib/lean'/(rel+'.olean')
 sj=json.loads(st.read_text());tj=json.loads(tr.read_text());assert sj['options']=={} and sj['plugins']==[] and not tj['synthetic'] and 'skipKernelTC' not in json.dumps(tj)
 assert all(e.get('level')!='error' for e in tj['log']) and 'sorryAx' not in json.dumps(tj),rel
 normal.append({'source':rel+'.lean','source_sha256':sha((ROOT/(rel+'.lean')).read_bytes()),'setup_sha256':sha(st.read_bytes()),'trace_sha256':sha(tr.read_bytes()),'olean_sha256':sha(o.read_bytes())})
record('normal-identities.json',normal)
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.ROOT=ROOT
scopes=c.environment_dependencies(sorted(names),MODULES[-1],None);assert all(a<=c.FOUNDATIONAL_AXIOMS for a in scopes.values())
record('axioms.json',{n:sorted(a) for n,a in scopes.items()})
# Complete accepted consumer types remain unchanged and are both consumed.
for rel in ['audit/trio/consolidation/GatewaySettlement.lean','audit/trio/consolidation/SettlementRequests.lean','LidoSRv3/Audit/Guarantees/PConsolidationEth1Requests.lean']:
 assert (ROOT/rel).read_bytes()==git(ROOT,'show',BASE+':'+rel)
pub=(ROOT/'LidoSRv3/Audit/Guarantees/PConsolidationEth1PhysicalQuota.lean').read_text()
assert 'GatewaySettlement.Success callee callee sexternal ctx vault gateway inbox recipient msgValue groups afterQuota ∧' in pub
assert 'SettlementRequests.Effects callee sexternal ctx vault gateway inbox recipient msgValue groups afterQuota' in pub
SOL=OUT.parent/'solidity';info=json.loads((SOL/'build-info.json').read_text());inputs=info['input']['sources'];pinned=json.loads((SOL/'pinned-sources.json').read_text());receipt=json.loads((SOL/'receipt.json').read_text())
assert len(inputs)==24 and set(inputs)==set(receipt['sources'])
tar=tarfile.open(SOL/'openzeppelin-contracts-5.2.0.tgz')
pack=json.loads((SOL/'pack.json').read_text())[0]
import base64
tgz=(SOL/'openzeppelin-contracts-5.2.0.tgz').read_bytes()
assert 'sha512-'+base64.b64encode(hashlib.sha512(tgz).digest()).decode()==pack['integrity']
assert sha(tgz)==pinned['oz_tgz_sha256'] and pack['version']=='5.2.0'
checked=[]
for name,item in sorted(inputs.items()):
 body=item['content'].encode();assert sha(body)==receipt['sources'][name]
 if name.startswith('contracts/'):assert body==git(CORE,'show',PIN+':'+name)
 elif name.startswith('@openzeppelin/'):assert body==tar.extractfile('package/'+name.split('/',2)[2]).read()
 else:assert body==(SOL/name.split('/')[-1]).read_bytes()
 if name in pinned['sources']:assert item==pinned['sources'][name]
 checked.append({'path':name,'sha256':sha(body)})
assert len(pinned['sources'])==22
for name,h in receipt['artifacts'].items():
 a=json.loads((SOL/(name+'.json')).read_text());assert sha((SOL/(name+'.json')).read_bytes())==h
 m=json.loads(a['rawMetadata']);assert m['compiler']['version']=='0.8.25+commit.b61c2a91'
 assert m['settings']['viaIR'] and m['settings']['optimizer']=={'enabled':True,'runs':200} and m['settings']['evmVersion']=='cancun'
 for n,v in m['sources'].items():assert v['keccak256']=='0x'+keccak.new(digest_bits=256,data=inputs[n]['content'].encode()).hexdigest()
 full=info['output']['contracts']['test/PhysicalQuotaHarness.sol' if name=='PhysicalQuotaHarness' else 'test/PhysicalQuota.t.sol'][name]
 assert a['bytecode']['object'].removeprefix('0x')==full['evm']['bytecode']['object']
ir=(SOL/'PhysicalQuotaHarness.ir').read_text();a=json.loads((SOL/'PhysicalQuotaHarness.json').read_text());assert ir==a['irOptimized']+'\n'
assert ir==info['output']['contracts']['test/PhysicalQuotaHarness.sol']['PhysicalQuotaHarness']['irOptimized']+'\n'
assert sha((SOL/'build-info.json').read_bytes())==receipt['build_info_sha256']
assert sha((SOL/'forge.log').read_bytes())==receipt['log_sha256'] and '12 passed; 0 failed' in (SOL/'forge.log').read_text() and 'runs: 1024' in (SOL/'forge.log').read_text()
legacy=json.loads((SOL/'SettlementVaultHarness.json').read_text());lm=json.loads(legacy['rawMetadata']);assert sha((SOL/'SettlementVaultHarness.json').read_bytes())==receipt['legacy_sha256']
assert lm['compiler']['version']=='0.8.9+commit.e5eed63a' and lm['settings']['evmVersion']=='london' and lm['settings']['optimizer']=={'enabled':True,'runs':200}
for n,v in lm['sources'].items():
 body=(ROOT/'audit/consolidation-settlement/solidity'/n).read_bytes();assert body==git(ROOT,'show',BASE+':audit/consolidation-settlement/solidity/'+n)
 assert v['keccak256']=='0x'+keccak.new(digest_bits=256,data=body).hexdigest()
record('compiler-identities.json',{'core':PIN,'inputs':checked,'full_ir_lines':len(ir.splitlines()),'ir_sha256':sha(ir.encode()),'legacy_sources':lm['sources'],'legacy_sha256':receipt['legacy_sha256']})
plain=re.sub(r'/\*.*?\*/','',ir,flags=re.S);plain=re.sub(r'///[^\n]*','',plain);plain=re.sub(r'\s+','',plain)
consume=plain[plain.index('functionfun_consumeConsolidationRequestLimit('):plain.index('functionfun_checkFee(')]
assert consume.index('fun_getStorageLimit()')<consume.index('leave')<consume.index('fun_calculateCurrentLimit(')<consume.index('lt(expr,var_requestsCount)')<consume.index('0xd0e5bff5')<consume.index('checked_sub_uint256(expr,var_requestsCount)')<consume.index('0x1930e3c9')<consume.index('checked_div_uint256(')<consume.index('letproduct_raw:=mul(')<consume.index('letsum:=add(')<consume.index('sstore(')
assert 'letcleaned:=and(checked_div_uint256(expr_1,and(mload(_6),_1)),_1)' in consume
assert 'and(_9,shl(160,0xffffffffffffffffffffffff))' in consume
assert 'ifiszero(eq(product,product_raw))' in consume and 'ifgt(sum,_1)' in consume
load=plain[plain.index('functionfun_getStorageLimit()'):plain.index('functionchecked_div_uint256(')]
for offset in [32,64,96,128]:assert f'and(shr({offset},_1),_2)' in load
calc_start=plain.index('functionfun_calculateCurrentLimit(')
calc=plain[calc_start:plain.index('functionfun_grantRole(',calc_start)]
assert calc.index('checked_sub_uint256(')<calc.index('leave')<calc.index('checked_div_uint256(')<calc.index('checked_add_uint256(')
for signature,value in [('ConsolidationRequestsLimitExceeded(uint256,uint256)','d0e5bff5'),('LimitExceeded()','3261c792')]:assert keccak.new(digest_bits=256,data=signature.encode()).hexdigest()[:8]==value
assert keccak.new(digest_bits=256,data=b'lido.ConsolidationGateway.maxConsolidationRequestLimit').hexdigest()=='dbb01bb6dca1179d47b58b17828e02dd61fb4c11ad515bab6e3e9ce25440d797'
record('correspondence.json',{'core':PIN,'full_gateway_ir_sha256':sha(ir.encode()),'layout_bits':{'maxLimit':0,'prevLimit':32,'prevTimestamp':64,'frameDurationInSec':96,'itemsPerFrame':128,'preserved_upper':160},
 'gateway_source':'pure guards/count189-199; omitted preconditions201,locator203,witness205-207; consume209 then quote211,vault220,refund222',
 'ir':'actual inherited entry quota1158 precedes quote1159; full consume1699-1780; getStorageLimit2061-2076; calculateCurrentLimit2089-2129; all full compiler bodies retained',
 'proof':'actual quota owner ctx.self; full unchanged Success and Effects consumed on postQuota; public rollback restores original credited entry; no final quota frame or stage-success premise',
 'runtime':'12 cases/1024 bounded initialized-state replenishment fuzz plus explicit arbitrary bad-state extremes; 2-source cached0.8.9 vault; quote/inbox/refund observe quota; late failure restores; accepted callback may mutate quota'})
print(f'PASS {len(entries)} actual sources, {len(pins)} pins, {len(scopes)} ordinary foundation-only scopes;3 normal modules;24 fresh compiler inputs/full IR/4 artifacts;2 legacy cached inputs;12 Solidity tests/1024 fuzz;entire prior consumer unchanged')
