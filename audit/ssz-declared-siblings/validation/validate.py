#!/usr/bin/env python3
"""Check current normal imports, pinned inputs and ordinary axioms. --write records JSON; default compares."""
from pathlib import Path
import argparse,hashlib,json,subprocess,importlib.util,re
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
BASE='4207bb0578b0a6821cd1d78b1f3a4bb08f277905'
MODULE='LidoSRv3.Tests.SszDeclaredSiblingsRegression'
NEW=['LidoSRv3/Audit/Source/SszDeclaredSiblings.lean','LidoSRv3/Audit/Guarantees/PSsz1DeclaredSiblings.lean','LidoSRv3/Tests/SszDeclaredSiblingsRegression.lean']
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
 names.update(namespace+'.'+n for n in re.findall(r'^theorem (\w+)',text,re.M))
 base=p[:-5];st=json.loads((ROOT/'.lake/build/ir'/(base+'.setup.json')).read_text());tr=json.loads((ROOT/'.lake/build/lib/lean'/(base+'.trace')).read_text())
 assert st['options']=={} and st['plugins']==[] and not tr['synthetic'];assert 'skipKernelTC' not in json.dumps(tr)
 artifacts.append(dict(source=p,sha256=sha(ROOT/p),olean_sha256=sha(ROOT/'.lake/build/lib/lean'/(base+'.olean')),setup_sha256=sha(ROOT/'.lake/build/ir'/(base+'.setup.json')),trace_sha256=sha(ROOT/'.lake/build/lib/lean'/(base+'.trace'))))
names.update('LidoSRv3.Audit.Source.SszCompiledClEntry.'+n for n in ['beforeRoot_success','rootCall_success','afterRoot_success'])
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.ROOT=ROOT
scopes=c.environment_dependencies(sorted(names),MODULE,None);assert all(a<=c.FOUNDATIONAL_AXIOMS for a in scopes.values())
record('axioms.json',{n:sorted(a) for n,a in scopes.items()});record('build-identities.json',artifacts)
# Existing accepted compiler/source/FFI packet, checked in full before reuse.
OLD=ROOT/'audit/ssz-compiled-cl-entry';V=OLD/'validation';SOL=OLD/'solidity'
old_receipt=json.loads((OLD/'receipt.json').read_text());integration=json.loads((OLD/'integration/receipt.json').read_text())
reused={}
for name,expected in old_receipt['sha256'].items():
 assert sha(ROOT/name)==expected,name
 assert (ROOT/name).read_bytes()==git(ROOT,'show',BASE+':'+name),name
 reused[name]=expected
for name,expected in integration['sha256'].items():
 assert sha(ROOT/name)==expected,name
 assert (ROOT/name).read_bytes()==git(ROOT,'show',BASE+':'+name),name
 reused[name]=expected
providers={}
for source,expected in integration['identities']['normal_olean_sha256'].items():
 p=ROOT/'.lake/build/lib/lean'/Path(source).with_suffix('.olean')
 assert sha(p)==expected,source
 providers[source]=expected
# Seven full source bodies, retained Mac replay and complete IR, no compiler run.
from Crypto.Hash import keccak
inp=json.loads((V/'materialized-compiler-input.json').read_text());orig=json.loads((SOL/'standard-json-input.json').read_text());ids=json.loads((SOL/'compiler-input-identities.json').read_text());raw=json.loads((V/'root-solc-output.json').read_text())
assert inp['settings']==orig['settings'];assert set(inp['sources'])==set(orig['sources'])==set(ids['inputs'])
checked=[]
for path,e in inp['sources'].items():
 body=e['content'].encode();expected=ids['inputs'][path]['sha256'];assert hashlib.sha256(body).hexdigest()==expected
 if path.startswith('lido-core/'):
  repo=Path('/tmp/lido-ssz-proof-committed/lido-core');pin=ids['source_pin'];relative=path[len('lido-core/'):]
 else:repo=ROOT;pin=BASE;relative=path
 assert git(repo,'show',pin+':'+relative)==body
 k='0x'+keccak.new(digest_bits=256,data=body).hexdigest();assert k==ids['inputs'][path]['keccak256']
 checked.append(dict(path=path,sha256=expected,keccak256=k,pin=pin))
art=raw['contracts']['audit/ssz-root-call-composition/solidity/SszRootCall.t.sol']['SszRootCallHarness'];assert (art['irOptimized']+'\n').encode()==(SOL/'inspected-cl-entry-ir.yul').read_bytes()
assert sha(SOL/'inspected-cl-entry-ir.yul')==integration['identities']['retained_ir_sha256']
oldruntime=json.loads((V/'runtime-inputs.json').read_text())
for path,expected in oldruntime['sha256'].items():assert sha(ROOT/path)==expected,path
for repo,pin in oldruntime['repositories'].items():assert git(ROOT/'.lake/packages/evmyul'/repo,'rev-parse','HEAD').decode().strip()==pin
assert 'PASS 4 whole-entry FFI diagnostics' in (V/'diagnostics.log').read_text()
# Test vector literals equal exact retained IO inputs. Byte checks do not claim FFI success in the kernel.
tests=(ROOT/NEW[2]).read_text()
for decl,name in [('vectorCalldata','valid-calldata.bin'),('vectorReply','valid-root.bin')]:
 literal=re.search(r'def '+decl+r' : ByteArray := ⟨#\[([0-9,]+)\]⟩',tests)[1]
 assert bytes(map(int,literal.split(',')))==(V/name).read_bytes()
vector=(V/'valid-calldata.bin').read_bytes();count=int.from_bytes(vector[452:484],'big');assert count==50
slot=int.from_bytes(vector[36:68],'big');proposer=int.from_bytes(vector[68:100],'big')
pair=hashlib.sha256(slot.to_bytes(8,'little')+bytes(24)+proposer.to_bytes(8,'little')+bytes(24)).digest()
assert vector[484+32*(count-2):484+32*(count-1)]==pair
literal=re.search(r'theorem retained_penultimate_bytes .*? = \[([0-9,]+)\]',tests)[1]
assert bytes(map(int,literal.split(',')))==pair
# Full prior public consequence and identical whole-run/ShaWidth premises retained before added conjunction.
old=(ROOT/'LidoSRv3/Audit/Guarantees/PSsz1CompiledClEntry.lean').read_text();a=old.index('theorem actual_compiled_cl_entry_branch');b=old.index(' :=\n  SszCompiledClEntry.run_success',a)
expected=old[a:b].replace('actual_compiled_cl_entry_branch','actual_compiled_cl_entry_complete_declared_branch',1)
assert expected+' ∧' in (ROOT/NEW[1]).read_text()
record('reuse-identities.json',{'scope':'Exact accepted330 source/review/replay/diagnostic bytes and seven current normal oleans; no Solidity, compiler or FFI execution repeated.', 'files':reused,'normal_oleans':providers,'compiler_inputs':checked,'runtime':oldruntime,'vector_count':count,'penultimate_sha256':pair.hex()})
subprocess.run(['git','diff','--exit-code',BASE,'--',*git(ROOT,'ls-tree','-r','--name-only',BASE).decode().splitlines()],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
record('summary.json',{'status':'PASS','base':BASE,'base_tree':git(ROOT,'rev-parse',BASE+'^{tree}').decode().strip(),'normal_modules':3,'source_inputs':len(entries),'package_pins':len(pins),'ordinary_scopes':len(scopes),'retained_compiler_inputs':len(checked),'retained_ffi_diagnostics':4,'new_ffi_runs':0,'new_solc_runs':0,'full_prior_conclusion':True,'new_test_theorems':len(re.findall(r'^theorem ',tests,re.M))})
print(f'PASS {len(entries)} exact source providers, {len(pins)} pins, {len(scopes)} ordinary scopes; three normal modules; entire330 conclusion; seven byte-identical old normal oleans and complete compiler/FFI evidence reused.')
