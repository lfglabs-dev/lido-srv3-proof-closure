#!/usr/bin/env python3
"""Check current normal imports, pinned inputs and ordinary axioms. --write records JSON; default compares."""
from pathlib import Path
import argparse,hashlib,json,subprocess,importlib.util,re
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='2c2c72a91cd68a43de0777912772d12cc48a285d';INITIAL='9723377c3a936c522ec10e88dadcab7e1a7b25b0'
MODULE='LidoSRv3.Tests.SszCompiledClEntryRegression'
NEW=['LidoSRv3/Audit/Source/'+n+'.lean' for n in ['SszSoladyFls','SszCompiledGIndex','SszCompiledFrame','SszCompiledReply','SszCompiledClEntry']]+['LidoSRv3/Audit/Guarantees/PSsz1CompiledClEntry.lean','LidoSRv3/Tests/SszCompiledClEntryRegression.lean']
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
record('source-inputs.json',dict(scope='Actual registered regression importArts plus regression; all old local bodies at accepted base; selected normal oleans compared; package sources at Git pins.',base=BASE,entries=sorted(entries,key=lambda x:x['path']),package_pins=pins))
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
names.update('LidoSRv3.Audit.Source.SszCompiledClEntry.'+n for n in ['beforeRoot_success','rootCall_success','afterRoot_success'])
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.ROOT=ROOT
scopes=c.environment_dependencies(sorted(names),MODULE,None);assert all(a<=c.FOUNDATIONAL_AXIOMS for a in scopes.values())
record('axioms.json',{n:sorted(a) for n,a in scopes.items()});record('build-identities.json',artifacts)
# Independent retained compiler inputs: all materialized bytes versus initial URL input, Git and metadata.
inp=json.loads((OUT/'materialized-compiler-input.json').read_text());orig=json.loads((OUT.parent/'solidity/standard-json-input.json').read_text());ids=json.loads((OUT.parent/'solidity/compiler-input-identities.json').read_text());raw=json.loads((OUT/'root-solc-output.json').read_text())
assert inp['settings']==orig['settings'];assert set(inp['sources'])==set(orig['sources'])==set(ids['inputs'])
checked=[]
for path,e in inp['sources'].items():
 b=e['content'].encode();expected=ids['inputs'][path]['sha256'];assert hashlib.sha256(b).hexdigest()==expected
 if path.startswith('lido-core/'):
  repo=Path('/tmp/lido-ssz-proof-committed/lido-core');pin=ids['source_pin'];relative=path[len('lido-core/'):]
 else:repo=ROOT;pin=BASE;relative=path
 assert git(repo,'show',pin+':'+relative)==b
 k=subprocess.check_output(['cast','keccak','0x'+b.hex()],text=True).strip();assert k==ids['inputs'][path]['keccak256']
 checked.append(dict(path=path,sha256=expected,keccak256=k,pin=pin))
art=raw['contracts']['audit/ssz-root-call-composition/solidity/SszRootCall.t.sol']['SszRootCallHarness'];assert (art['irOptimized']+'\n').encode()==(OUT.parent/'solidity/inspected-cl-entry-ir.yul').read_bytes()
record('compiler-check.json',dict(scope='Retained root Mac solc0.8.25 replay, no new compiler execution by this validator; Linux binary not reexecuted; source/IR correspondence requires review.',inputs=checked,ir_sha256=sha(OUT.parent/'solidity/inspected-cl-entry-ir.yul')))
pkg=ROOT/'.lake/packages/evmyul';runtime={str(p.relative_to(ROOT)):sha(p) for p in [pkg/'EvmYul/FFI/ffi.lean',pkg/'EvmYul/FFI/ffi.c',pkg/'sha2/sha-256.c',pkg/'sha2/sha-256.h',pkg/'keccak256/sha3.c',pkg/'keccak256/sha3.h']}
record('runtime-inputs.json',dict(scope='Existing FFI compiled into temporary diagnostic dylib; no kernel claim',sha256=runtime,repositories={d:git(pkg/d,'rev-parse','HEAD').decode().strip() for d in ['sha2','keccak256']}))
print(f'PASS {len(entries)} source identities, {len(pins)} pins, {len(scopes)} fresh ordinary foundational scopes, seven normal modules, seven pinned compiler inputs and exact retained IR.')
