#!/usr/bin/env python3
"""Check current normal imports, pinned inputs and ordinary axioms. --write records JSON; default compares."""
from pathlib import Path
import argparse,hashlib,json,subprocess,importlib.util,re
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='f00863276fbe279c566328ed4ae90f5bf223a38e'
MODULE='LidoSRv3.Tests.TopupPhysicalCredentialGetter'
NEW=['LidoSRv3/Audit/Source/TopupPhysicalCredentialGetter.lean','LidoSRv3/Audit/Guarantees/PTopupPhysicalCredentialGetter.lean','LidoSRv3/Tests/TopupPhysicalCredentialGetter.lean']
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
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.ROOT=ROOT
scopes=c.environment_dependencies(sorted(names),MODULE,None);assert all(a<=c.FOUNDATIONAL_AXIOMS for a in scopes.values())
record('axioms.json',{n:sorted(a) for n,a in scopes.items()});record('build-identities.json',artifacts)
# Reuse exact retained complete BatchRouter IR and all of its compiler inputs.
from Crypto.Hash import keccak
K=lambda b:keccak.new(digest_bits=256,data=b).hexdigest()
D=ROOT/'audit/topup-module-nocode';ids=json.loads((D/'compiler-source-identities.json').read_text());meta=json.loads((D/'compiler-metadata.json').read_text());checked=[]
PIN='17005714f151e5502c559932319a3f2f74ac2436';CORE=Path('/tmp/lido-ssz-proof-committed/lido-core')
for name,h in ids['source_sha256'].items():
 if '/lido-core/' in name:
  rel=name.split('/lido-core/',1)[1];body=git(CORE,'show',PIN+':'+rel)
 elif name.startswith('/tmp/lido-topup-wei-deps/package/'):
  rel=name.split('/package/',1)[1];body=git(ROOT,'show',BASE+':audit/deposit-dsm-call/solidity/src/@openzeppelin/contracts-v5.2/'+rel)
 else:
  body=(ROOT/name).read_bytes();assert body==git(ROOT,'show',BASE+':'+name)
 assert hashlib.sha256(body).hexdigest()==h,name
 checked.append(dict(path=name,sha256=h,keccak256=K(body)))
# Metadata names match the source identity packet's remapped names.
for name,e in meta['sources'].items():
 candidates=[v for v in checked if v['path']==name or v['path'].endswith('/'+name) or name.endswith(v['path'])]
 if not candidates and name.startswith('@openzeppelin/contracts-v5.2/'):
  candidates=[v for v in checked if v['path'].endswith('/package/'+name.split('/',2)[2])]
 if not candidates and name.startswith('contracts/'):
  candidates=[v for v in checked if v['path'].endswith('/lido-core/'+name)]
 assert len(candidates)==1,(name,candidates)
 assert '0x'+candidates[0]['keccak256']==e['keccak256'],name
assert len(checked)==len(meta['sources'])
assert sha(D/'router-ir.txt')==ids['ir_sha256']
assert meta['compiler']['version']=='0.8.25+commit.b61c2a91'
assert meta['settings']['viaIR'] and meta['settings']['optimizer']=={'enabled':True,'runs':200} and meta['settings']['evmVersion']=='cancun'
seed=int(K(b'lido.StakingRouter.routerStorage'),16)
root=int(K((seed-1).to_bytes(32,'big')),16)&~255
assert root==int('5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000',16)
assert K(b'StakingModuleUnregistered()')[:8]=='d41d6282'
assert K(b'getStakingModuleWithdrawalCredentials(uint256)')[:8]=='f85c6ceb'
kept=['router-ir.txt','compiler-metadata.json','compiler-source-identities.json','receipt.json']
for n in kept:assert (D/n).read_bytes()==git(ROOT,'show',BASE+':'+str((D/n).relative_to(ROOT)))
record('compiler-reuse.json',dict(scope='Reused complete exact IR, no solc or Forge rerun; all input SHA/metadata Keccak checked against Git pins/vendored accepted bytes',sources=checked,artifacts={str((D/x).relative_to(ROOT)):sha(D/x) for x in kept},router_root=hex(root),selector='f85c6ceb',unregistered='d41d6282'))
prior=ROOT/'audit/topup-credential-call/validation';vectors=['root.bin','proof-0.bin','proof-1.bin','proof-2.bin','vector.json','make-vector.py']
for n in vectors:assert (prior/n).read_bytes()==git(ROOT,'show',BASE+':'+str((prior/n).relative_to(ROOT)))
P=ROOT/'.lake/packages/evmyul';ffi=['EvmYul/FFI/ffi.lean','EvmYul/FFI/ffi.c','sha2/sha-256.c','sha2/sha-256.h','keccak256/sha3.c','keccak256/sha3.h']
record('runtime-inputs.json',dict(scope='Fresh native FFI diagnostic, unchanged independent f008 vectors; no kernel theorem credit',vectors={str((prior/n).relative_to(ROOT)):sha(prior/n) for n in vectors},files={n:sha(P/n) for n in ffi},repositories={n:git(P/n,'rev-parse','HEAD').decode().strip() for n in ['sha2','keccak256']}))
print('PASS',len(entries),'source identities,',len(pins),'pins,',len(scopes),'ordinary foundational scopes,',len(checked),'retained compiler inputs; 3 normal artifacts')
