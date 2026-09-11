#!/usr/bin/env python3
"""Recheck actual repaired import closure; preserve the rejected source packet."""
from pathlib import Path
import hashlib,importlib.util,json,re,subprocess
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='a3ae099cdaa185245a19a16121f9fd025e0fd806'
REPAIRED='LidoSRv3/Audit/Verity/AddressRecipientCallBridge.lean'
REPLACEMENTS={
'0x8ee26abbbdf5335e3953ccf2204a79e845eecb5ab51f8398526746e4ea068041':'0x8ee26abbbdf533de3953ccf2204279e845eecb5ab51f8398522746e4ea068041',
'0x6825d6bead788134d1ac062bbb7f1f0e4a9e13182688453e79955a721d58c45d':'0x6825d6bead7081b4d1ac062bbb771f0e4ade13182688453e79955a721d58c4dd',
'0x528f2b9d452f4b604589d1a9e64c321ee1035a867d38a1359d022af391cf7df5':'0x528f2b9d45274be04589d1a9e644321ee1435a867d38a1359d022af391cf7d75'}
MODULE='LidoSRv3.Tests.AddressRequestCalls'
NEW=['LidoSRv3/Audit/Source/AddressRequestCalls.lean','LidoSRv3/Audit/Guarantees/PAddress1RequestCalls.lean','LidoSRv3/Tests/AddressRequestCalls.lean']
def git(repo,*args):return subprocess.check_output(['git','-C',str(repo),*args])
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
pins={p['name']:p['rev'] for p in json.loads((ROOT/'lake-manifest.json').read_text())['packages']}
for name,pin in pins.items():assert git(ROOT/'.lake/packages'/name,'rev-parse','HEAD').decode().strip()==pin
setup=json.loads((ROOT/'.lake/build/ir'/Path(MODULE.replace('.','/')+'.setup.json')).read_text())
entries=[]
for name,arts in setup['importArts'].items():
 prefix,suffix=arts[0].split('/.lake/build/lib/lean/')
 actual=Path(prefix)/Path(suffix).with_suffix('.lean')
 if not actual.exists():actual=Path(prefix)/'audit/trio/account-address'/Path(suffix).with_suffix('.lean')
 assert actual.exists(),(name,actual)
 if '/.lake/packages/' in str(actual):
  pkg,rel=str(actual).split('/.lake/packages/',1)[1].split('/',1)
  local=ROOT/'.lake/packages'/pkg/rel
  assert local.read_bytes()==actual.read_bytes()
  assert git(ROOT/'.lake/packages'/pkg,'show',pins[pkg]+':'+rel)==local.read_bytes(),name
  relative='.lake/packages/'+pkg+'/'+rel
 else:
  local=ROOT/Path(suffix).with_suffix('.lean')
  if not local.exists():local=ROOT/'audit/trio/account-address'/Path(suffix).with_suffix('.lean')
  assert local.read_bytes()==actual.read_bytes(),name
  relative=str(local.relative_to(ROOT))
  assert Path(arts[0]).read_bytes()==(ROOT/'.lake/build/lib/lean'/suffix).read_bytes(),name
  original=git(ROOT,'show',BASE+':'+relative)
  if relative==REPAIRED:
   for old,new in REPLACEMENTS.items():
    assert original.count(old.encode())==1
    original=original.replace(old.encode(),new.encode())
  assert original==local.read_bytes(),relative
 entries.append(dict(module=name,path=relative,sha256=sha(local)))
for p in NEW:
 if not any(e['path']==p for e in entries):entries.append(dict(module=p[:-5].replace('/','.'),path=p,sha256=sha(ROOT/p)))
(OUT/'source-inputs.json').write_text(json.dumps(dict(scope='Actual final test setup importArts plus test itself; every cached external source at its package Git pin; each consumed local source matches a3ae except exactly three corrected canonical literals; selected local olean byte-compared.',entries=sorted(entries,key=lambda x:x['path']),package_pins=pins),indent=2)+'\n')
for p in NEW:
 text=re.sub(r'/\-.*?\-/','',(ROOT/p).read_text(),flags=re.S)
 text=re.sub(r'--[^\n]*','',text)
 assert not re.search(r'\b(sorry|admit|axiom|native_decide|unsafe|implemented_by)\b',text),p
names=[]
for name in re.findall(r'^#print axioms (\S+)',(ROOT/NEW[-1]).read_text(),re.M):
 if name.startswith('actual_'):name='LidoSRv3.Audit.Guarantees.PAddress1.'+name
 elif name.startswith('public_'):name='LidoSRv3.Tests.AddressRequestCalls.'+name
 names.append(name)
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py');checker=importlib.util.module_from_spec(spec);spec.loader.exec_module(checker);checker.ROOT=ROOT
computed=checker.environment_dependencies(names,MODULE,None)
assert all(a<={'propext','Classical.choice','Quot.sound'} for a in computed.values())
(OUT/'axioms.json').write_text(json.dumps({n:sorted(a) for n,a in computed.items()},indent=2)+'\n')
# Native diagnostic support is separate from the Lean package pin/axiom claim.
pkg=ROOT/'.lake/packages/evmyul'
runtime={str(p.relative_to(ROOT)):sha(p) for p in [pkg/'EvmYul/FFI/ffi.lean',pkg/'EvmYul/FFI/ffi.c',pkg/'sha2/sha-256.c',pkg/'sha2/sha-256.h',pkg/'keccak256/sha3.c',pkg/'keccak256/sha3.h']}
(OUT/'runtime-inputs.json').write_text(json.dumps(dict(scope='Fresh diagnostic dylib only; not kernel theorem evidence',sha256=runtime,repositories={d:git(pkg/d,'rev-parse','HEAD').decode().strip() for d in ['sha2','keccak256']}),indent=2)+'\n')
print(f'PASS {len(entries)} imported/new source identities, {len(pins)} package pins, {len(computed)} active ordinary axiom sets; local sources match rejected a3ae except exactly three independently checked canonical slot literals.')
