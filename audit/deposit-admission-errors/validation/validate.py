#!/usr/bin/env python3
"""Default compares; --write records this new dossier. No builds or compiler runs.
The only execution is ordinary temporary Lean axiom queries against real imports.
"""
from pathlib import Path
import argparse,hashlib,importlib.util,json,re,subprocess,tarfile
from Crypto.Hash import keccak
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='b3b63586ecd72467dadc2e5ccdca220d820f15fb'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
MODULES=['LidoSRv3.Audit.Source.DepositAdmissionErrors','LidoSRv3.Audit.Guarantees.PDeposit1AdmissionErrors','LidoSRv3.Tests.DepositAdmissionErrorsRegression']
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
# Retained source/runtime dossiers: exact accepted345 identities, no reruns.
reuse={};compiler={}
for directory,harness,tests in [('deposit-physical-admission','AdmissionHarness',6),('deposit-dsm-call','DsmHarness',9)]:
 old=ROOT/'audit'/directory;receipt=json.loads((old/'receipt.json').read_text())
 for rel,h in receipt['hashes'].items():
  raw=(ROOT/rel).read_bytes();assert sha(raw)==h and raw==git(ROOT,'show',BASE+':'+rel),rel
 reviews={str(p.relative_to(ROOT)):sha(p.read_bytes()) for p in (old/'integration').glob('*review*.md')}
 for rel in reviews:assert (ROOT/rel).read_bytes()==git(ROOT,'show',BASE+':'+rel)
 sol=old/'solidity';inputs=json.loads((sol/'inputs.json').read_text());artifact=json.loads((sol/'compiler-artifact.json').read_text());metadata=json.loads(artifact['rawMetadata'])
 assert metadata['compiler']['version']=='0.8.25+commit.b61c2a91'
 assert metadata['settings']['viaIR'] and metadata['settings']['optimizer']=={'enabled':True,'runs':200} and metadata['settings']['evmVersion']=='cancun'
 checked=[]
 for rel,v in metadata['sources'].items():
  body=(sol/rel).read_bytes();assert v['keccak256']=='0x'+keccak.new(digest_bits=256,data=body).hexdigest()
  assert body==git(ROOT,'show',BASE+':'+str((sol/rel).relative_to(ROOT)))
  if rel.startswith('src/contracts/'):assert body==git(CORE,'show',PIN+':'+rel[len('src/'):])
  checked.append({'path':str((sol/rel).relative_to(ROOT)),'sha256':sha(body),'keccak256':v['keccak256']})
 assert len(checked)==28
 for v in inputs['sources']:assert sha((ROOT/v['path']).read_bytes())==v['sha256']
 assert len(inputs['sources'])==27
 ir=(sol/(harness+'.ir')).read_text()
 if 'irOptimized' in artifact:assert ir==artifact['irOptimized']+'\n'
 if directory=='deposit-physical-admission':assert json.loads((sol/'storage-layout.json').read_text())==artifact['storageLayout']
 log=(sol/'forge.log').read_text();assert f'{tests} passed; 0 failed' in log and log.count('runs: 1024')==2
 reuse[directory]={'receipt_sha256':sha((old/'receipt.json').read_bytes()),'files':receipt['hashes'],'independent_reviews':reviews,'normal_tests':tests,'fuzz_tests':2,'fuzz_runs_each':1024,'rerun':False}
 compiler[directory]={'metadata':metadata['settings'],'inputs':checked,'ir_sha256':sha(ir.encode()),'ir_lines':len(ir.splitlines()),'artifact_sha256':sha((sol/'compiler-artifact.json').read_bytes())}
# Complete vendored OZ closure retains independently checked cached archive provenance.
import base64
archive=ROOT/'audit/consolidation-physical-quota/solidity/openzeppelin-contracts-5.2.0.tgz'
raw=archive.read_bytes();tar=tarfile.open(archive)
for directory in reuse:
 sol=ROOT/'audit'/directory/'solidity';inputs=json.loads((sol/'inputs.json').read_text())
 assert 'sha512-'+base64.b64encode(hashlib.sha512(raw).digest()).decode()==inputs['openzeppelin']['integrity']
 for p in (sol/'src/@openzeppelin/contracts-v5.2').rglob('*.sol'):
  assert p.read_bytes()==tar.extractfile('package/'+str(p.relative_to(sol/'src/@openzeppelin/contracts-v5.2'))).read()
# All local admission encoders are tied to actual complete compiler bodies.
ir=(ROOT/'audit/deposit-dsm-call/solidity/DsmHarness.ir').read_text()
plain=re.sub(r'/\*.*?\*/','',ir,flags=re.S);plain=re.sub(r'///[^\n]*','',plain);plain=re.sub(r'\s+','',plain)
start=plain.index('functionfun_deposit(');deposit=plain[start:plain.index('function',start+10)]
assert deposit.index('fun_checkAppAuth(fun_getDepositSecurityModule())')<deposit.index('fun_requireModuleIdExists(')<deposit.index('ifiszero(lt(value,3))')<deposit.index('ifiszero(iszero(value))')<deposit.index('fun_getWithdrawalCredentialsWithType(')<deposit.index('staticcall(')<deposit.index('fun_getModuleDepositAllocation(')
assert 'shl(224,0x4e487b71)' in deposit and 'mstore(4,0x21)' in deposit and 'revert(0,0x24)' in deposit
assert 'shl(225,0x322e64fb)' in deposit
assert 'shl(224,0xea8e4eb5)' in plain and 'shl(225,0x6a0eb141)' in plain
for sig,value in [('NotAuthorized()','ea8e4eb5'),('StakingModuleUnregistered()','d41d6282'),('StakingModuleNotActive()','645cc9f6'),('Panic(uint256)','4e487b71')]:assert keccak.new(digest_bits=256,data=sig.encode()).hexdigest()[:8]==value
# Preserve the failed tracing evidence, with exactly the existing qualified reuse.
trace=ROOT/'audit/deposit-dsm-call/solidity/no-code-trace.log';normal=ROOT/'audit/deposit-dsm-call/solidity/no-code-check.log'
assert '[FAIL:' in trace.read_text() and '[PASS]' in normal.read_text()
record('reuse-identities.json',{'base':BASE,'dossiers':reuse,'oz_archive_sha256':sha(raw),'tracing_fail_sha256':sha(trace.read_bytes()),'normal_no_code_sha256':sha(normal.read_bytes()),'limitation':'Normal-mode exactbytes only; tracing test FAIL preserved; no fresh Forge/compiler/native execution.'})
record('compiler-identities.json',compiler)
record('correspondence.json',{'core':PIN,'source':'StakingRouter.deposit943–950; _checkAppAuth1177–1179; SRUtils membership45–47; physical enum/status reads and actual packed WC remain unchanged.',
 'ir':'Full DsmHarness fun_deposit3323 onward: auth then membership then enum Panic21 then inactive4bytes then WC/getDepositableEther/allocation; exact auth4232–4244; membership4119 onward. Full AdmissionHarness5030 lines and DsmHarness retained at accepted345.',
 'errors':{'unauthorized':'ea8e4eb5','unregistered':'d41d6282','invalidEnum':'4e487b71 + uint256(0x21)','inactive':'645cc9f6'},
 'composition':'One actual lookup, local physical gate, one unchanged ModulePhysicalMetadata continuation. Public all-outcome theorem retains entire328 Effects plus exact successful result, first-failing local error origin/bytes/no-module-attempt and universal original rollback. Downstream faults unmodified; no global reason remapping.',
 'boundary':'No allocation/capture closure; no unified complete trace or full-memory/gas/bytecode claim. Existing supplied allocation/maxEB/phase cursors/context/hash/library qualifications remain. Accepted ALLOC and RESERVE unchanged.'})
print(f'PASS {len(entries)} actual sources/{len(pins)} pins/{len(scopes)} ordinary foundational scopes;3 normal modules;99 prior receipt hashes/2x28 compiler sources reused;15 retained normal Solidity tests/4x1024 fuzz;whole328 success/local error origin/original rollback')
