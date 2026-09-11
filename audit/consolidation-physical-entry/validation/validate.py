#!/usr/bin/env python3
"""Default compares; --write records this new dossier. No builds or compiler runs.
The only execution is ordinary temporary Lean axiom queries against real imports.
"""
from pathlib import Path
import argparse,hashlib,importlib.util,json,re,subprocess,tarfile
from Crypto.Hash import keccak
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='82051ab0a552734712b8f33e3f96f0074bf9ee39'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
MODULES=['audit.trio.consolidation.PhysicalEntrySettlement','LidoSRv3.Audit.Guarantees.PConsolidationEth1PhysicalEntry','LidoSRv3.Tests.TrioConsolidation.PhysicalEntrySettlement']
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
OLD=ROOT/'audit/consolidation-physical-quota';SOL=OUT.parent/'solidity'
oldreceipt=json.loads((OLD/'receipt.json').read_text())
for rel,h in oldreceipt['files'].items():assert sha((ROOT/rel).read_bytes())==h and (ROOT/rel).read_bytes()==git(ROOT,'show',BASE+':'+rel),rel
for rel,h in oldreceipt['config_sha256'].items():assert sha((ROOT/rel).read_bytes())==h and (ROOT/rel).read_bytes()==git(ROOT,'show',BASE+':'+rel),rel
oldpub=(ROOT/'LidoSRv3/Audit/Guarantees/PConsolidationEth1PhysicalQuota.lean').read_text()
prior=oldpub.split('theorem actual_physical_quota_settlement_requests',1)[1].split(' :\n',1)[1].split(' := by',1)[0]
assert (OUT/'prior-conclusion.txt').read_text()==prior.strip()+'\n'
pub=(ROOT/'LidoSRv3/Audit/Guarantees/PConsolidationEth1PhysicalEntry.lean').read_text()
assert '('+prior.strip()+') := by' in pub
info=json.loads((SOL/'build-info.json').read_text());inputs=info['input']['sources'];receipt=json.loads((SOL/'receipt.json').read_text());pinned=json.loads((OLD/'solidity/pinned-sources.json').read_text())
assert len(inputs)==25 and set(inputs)==set(receipt['sources'])
assert len(pinned['sources'])==22
import base64
tgz=(OLD/'solidity/openzeppelin-contracts-5.2.0.tgz').read_bytes();pack=json.loads((OLD/'solidity/pack.json').read_text())[0]
assert sha(tgz)==pinned['oz_tgz_sha256'] and pack['version']=='5.2.0'
assert 'sha512-'+base64.b64encode(hashlib.sha512(tgz).digest()).decode()==pack['integrity']
tar=tarfile.open(OLD/'solidity/openzeppelin-contracts-5.2.0.tgz')
checked=[]
for name,item in sorted(inputs.items()):
 body=item['content'].encode();assert sha(body)==receipt['sources'][name]
 if name.startswith('contracts/'):assert body==git(CORE,'show',PIN+':'+name)
 elif name.startswith('@openzeppelin/'):assert body==tar.extractfile('package/'+name.split('/',2)[2]).read()
 elif name=='test/PhysicalQuotaHarness.sol':assert body==(OLD/'solidity/PhysicalQuotaHarness.sol').read_bytes()
 else:assert body==(SOL/name.split('/')[-1]).read_bytes()
 if name in pinned['sources']:assert item==pinned['sources'][name]
 checked.append({'path':name,'sha256':sha(body)})
for name,h in receipt['artifacts'].items():
 a=json.loads((SOL/(name+'.json')).read_text());assert sha((SOL/(name+'.json')).read_bytes())==h
 m=json.loads(a['rawMetadata']);assert m['compiler']['version']=='0.8.25+commit.b61c2a91'
 assert m['settings']['viaIR'] and m['settings']['optimizer']=={'enabled':True,'runs':200} and m['settings']['evmVersion']=='cancun'
 for n,v in m['sources'].items():assert v['keccak256']=='0x'+keccak.new(digest_bits=256,data=inputs[n]['content'].encode()).hexdigest()
 full=info['output']['contracts']['test/PhysicalEntryHarness.sol' if name=='PhysicalEntryHarness' else 'test/PhysicalEntry.t.sol'][name]
 assert a['bytecode']['object'].removeprefix('0x')==full['evm']['bytecode']['object']
a=json.loads((SOL/'PhysicalEntryHarness.json').read_text());ir=(SOL/'PhysicalEntryHarness.ir').read_text()
assert ir==a['irOptimized']+'\n'==info['output']['contracts']['test/PhysicalEntryHarness.sol']['PhysicalEntryHarness']['irOptimized']+'\n'
assert sha((SOL/'build-info.json').read_bytes())==receipt['build_info_sha256']
assert sha((SOL/'forge.log').read_bytes())==receipt['log_sha256'] and '8 passed; 0 failed' in (SOL/'forge.log').read_text() and 'runs: 1024' in (SOL/'forge.log').read_text()
# Cached deployed support artifacts are retained inputs from8205, not new compiles.
legacy={}
oldinfo=json.loads((OLD/'solidity/build-info.json').read_text())
for name in ['QuotaInbox','QuotaRefund','SettlementVaultHarness']:
 raw=(OLD/('solidity/'+name+'.json')).read_bytes();art=json.loads(raw);m=json.loads(art['rawMetadata'])
 if name!='SettlementVaultHarness':
  assert m['compiler']['version']=='0.8.25+commit.b61c2a91'
  for n,v in m['sources'].items():assert v['keccak256']=='0x'+keccak.new(digest_bits=256,data=oldinfo['input']['sources'][n]['content'].encode()).hexdigest()
  assert art['bytecode']['object'].removeprefix('0x')==oldinfo['output']['contracts']['test/PhysicalQuota.t.sol'][name]['evm']['bytecode']['object']
 else:
  assert sha(raw)==receipt['legacy_sha256'] and m['compiler']['version']=='0.8.9+commit.e5eed63a'
  assert m['settings']['optimizer']=={'enabled':True,'runs':200} and m['settings']['evmVersion']=='london'
  for n,v in m['sources'].items():
   body=(ROOT/'audit/consolidation-settlement/solidity'/n).read_bytes();assert body==git(ROOT,'show',BASE+':audit/consolidation-settlement/solidity/'+n)
   assert v['keccak256']=='0x'+keccak.new(digest_bits=256,data=body).hexdigest()
 legacy[name]={'sha256':sha(raw),'compiler':m['compiler'],'sources':m['sources']}
layout=a['storageLayout'];assert [(x['label'],x['slot'],x['offset']) for x in layout['storage']]==[('_roles','0',0),('_roleMembers','1',0)]
roleType=next(v for v in layout['types'].values() if v.get('label')=='struct AccessControl.RoleData')
assert roleType['members'][0]['label']=='hasRole' and roleType['members'][0]['slot']=='0' and roleType['members'][0]['offset']==0
plain=re.sub(r'/\*.*?\*/','',ir,flags=re.S);plain=re.sub(r'///[^\n]*','',plain);plain=re.sub(r'\s+','',plain)
actual=plain[plain.index('case0x7328fa92{'):];actual=actual[:actual.index('case0x',6)]
assert actual.index('fun_checkRole_24096()')<actual.index('selfbalance()')<actual.index('checked_sub_uint256(')<actual.index('fun_checkResumed()')<actual.index('iszero(callvalue())')<actual.index('fun_consumeConsolidationRequestLimit(')
rolebody=plain[plain.index('functionfun_checkRole_24096()'):plain.index('functionfun_checkRole_24102()')]
for needle in ['mstore(0x00,_1)','mstore(0x20,0x00)','keccak256(0x00,0x40)','mstore(0x00,caller())','mstore(0x20,_2)','and(sload(keccak256(0x00,0x40)),0xff)','0xe2517d3f','revert(_3,68)']:assert needle in rolebody,needle
pause=plain[plain.index('functionfun_checkResumed()'):plain.index('functionabi_decode_address_fromMemory(')]
assert 'lt(timestamp(),sload(0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02))' in pause
assert 'shl(227,0x0286f073)' in pause and 'revert(_1,4)' in pause
for signature,value in [('AccessControlUnauthorizedAccount(address,bytes32)','e2517d3f'),('ResumedExpected()','14378398')]:assert keccak.new(digest_bits=256,data=signature.encode()).hexdigest()[:8]==value
role=keccak.new(digest_bits=256,data=b'ADD_CONSOLIDATION_REQUEST_ROLE').digest();assert role.hex()=='2893ea78cf4b35bcb6ca1f49c79c387fe7f3d8fd18fe56f2424c792c6a8207d2'
assert keccak.new(digest_bits=256,data=b'lido.PausableUntil.resumeSinceTimestamp').hexdigest()=='e8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02'
record('compiler-identities.json',{'core':PIN,'inputs':checked,'full_ir_lines':len(ir.splitlines()),'ir_sha256':sha(ir.encode()),'cached_support':legacy,'old_full24input_build_sha256':sha((OLD/'solidity/build-info.json').read_bytes()),'old_full2456ir_sha256':sha((OLD/'solidity/PhysicalQuotaHarness.ir').read_bytes())})
record('correspondence.json',{'core':PIN,'ir':'Actual Gateway selector704–728: ABI head/typed decoder precede role; role711,balance713–715,pause717,zero719. Complete role1771–1799; full-word resume2156–2168. Typed new entry selector653–669 shares same actual modifiers. Full inherited actual Gateway body and helpers retained.',
 'layout':'NON-upgradeable OZ5.2 AccessControlEnumerable: _roles base0, RoleData.hasRole offset0, _roleMembers base1. Nested role32/base032 then actual caller32/inner32. Low byte nonzero, no injectivity/nonalias premise.',
 'consumer':'Only whole actual entry outcome premise; derives role/balance/resume and preserves verbatim full8205 existential conjunction and exact returned prior result. Calls actual post-quota settlement with unchanged original arguments. Omitted DSM/locator/witness remain explicit; pure balance/count replay. Complete original credited-world rollback, no final quota/role/pause frame.',
 'runtime':'8 actual Solidity cases/1024 raw role-resume fuzz. Nonempty typed suffix uses cached actual vault plus cached recording inbox/refund. Synthetic damaged-balance experiment failed and removed, never credited. Kernel/native arbitrary-entry balance priority retained.'})
assert 'PASS 6 pure-native execution groups' in (OUT/'native.log').read_text()
vectors=json.loads((OUT/'mapping-vectors.json').read_text())
assert len(vectors)==4
rows=[]
for v in vectors:
 caller=int(v['caller']);inner=role+bytes(32);ih=keccak.new(digest_bits=256,data=inner).digest();outer=caller.to_bytes(32,'big')+ih
 assert v['inner_hex']==inner.hex() and v['inner_hash']==ih.hex() and v['outer_hex']==outer.hex()
 assert int(v['slot'])==int.from_bytes(keccak.new(digest_bits=256,data=outer).digest(),'big')
 rows.append(v['caller']+'\t'+v['slot'])
assert (OUT/'mapping-vectors.tsv').read_text()=='\n'.join(rows)+'\n'
record('reuse-identities.json',{'base':BASE,'old_receipt_sha256':sha((OLD/'receipt.json').read_bytes()),'old_files':oldreceipt['files'],'configs':oldreceipt['config_sha256'],'prior_conclusion_sha256':sha(prior.encode()),'runtime_log_sha256':sha((OUT/'native.log').read_bytes())})
print(f'PASS {len(entries)} actual sources/{len(pins)} pins/{len(scopes)} ordinary foundation scopes;3 normal modules;full8205 conjunction and42files unchanged;25 fresh compiler inputs/2 artifacts/full IR;3 cached support artifacts;8 Solidity cases/1024 raw fuzz;6 native groups/4 independent vectors')
