#!/usr/bin/env python3
from pathlib import Path
import datetime,hashlib,json,subprocess,tarfile
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def git(repo,*a):return subprocess.check_output(['git','-C',str(repo),*a])
archive=OUT/'solidity/openzeppelin-contracts-4.4.1.tgz'
pack=json.loads((OUT/'solidity/npm-pack.json').read_text())[0]
import base64
assert 'sha512-'+base64.b64encode(hashlib.sha512(archive.read_bytes()).digest()).decode()==pack['integrity']
identities={}
with tarfile.open(archive) as tf:
 for p in sorted((OUT/'solidity/src').rglob('*.sol')):
  rel=p.relative_to(OUT/'solidity/src').as_posix()
  if rel.startswith('core/'):
   origin='contracts/0.8.9/'+rel.removeprefix('core/')
   assert git(CORE,'show',PIN+':'+origin)==p.read_bytes(),rel
  elif rel.startswith('@openzeppelin/'):
   origin='npm:@openzeppelin/contracts@4.4.1/'+rel.removeprefix('@openzeppelin/contracts-v4.4/')
   assert tf.extractfile('package/'+rel.removeprefix('@openzeppelin/contracts-v4.4/')).read()==p.read_bytes()
  else: origin='local harness/probe; never claimed production source'
  identities[p.relative_to(ROOT).as_posix()]={'origin':origin,'sha256':sha(p)}
for p in (OUT/'solidity/test').glob('*.sol'):identities[p.relative_to(ROOT).as_posix()]={'origin':'local tests','sha256':sha(p)}
artifact=json.loads((OUT/'solidity/RequestHarness.json').read_text())
(OUT/'solidity/source-identities.json').write_text(json.dumps({'pin':PIN,'npm_integrity':pack['integrity'],'sources':identities,'compiler_settings':artifact['metadata']['settings'],'solc_version':artifact['metadata']['compiler']['version']},indent=2)+'\n')
new=['LidoSRv3/Audit/Source/AddressRequestCalls.lean','LidoSRv3/Audit/Guarantees/PAddress1RequestCalls.lean','LidoSRv3/Tests/AddressRequestCalls.lean']
paths=[ROOT/p for p in new]+[p for p in OUT.rglob('*') if p.is_file() and not {'out','cache'}&set(p.relative_to(OUT).parts) and p.name!='receipt.json']
inputs=json.loads((OUT/'source-inputs.json').read_text());axioms=json.loads((OUT/'axioms.json').read_text())
receipt={'schema':'lido-address-request-call-v1','created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'base':'eee5d6700e5d99cc35eab7bf3e1e2b51a2465857','source_pin':PIN,'new_production_files':new[:2],'test_file':new[2],'previous_files_changed':0,
'public_theorems':['LidoSRv3.Audit.Guarantees.PAddress1.actual_request_withdrawal_enqueue','LidoSRv3.Audit.Guarantees.PAddress1.actual_request_withdrawal_failure_restores'],
'lean':{'target_command':'lake build LidoSRv3.Audit.Source.AddressRequestCalls LidoSRv3.Audit.Guarantees.PAddress1RequestCalls LidoSRv3.Tests.AddressRequestCalls','exit_code':0,'final_target_jobs':1262,'logs':'source-build.log built final source/public; target-build.log built final tests and replayed unchanged dependencies','kernel_examples':13,'public_kernel_rollback_instances':1,'complete_success_kernel_instance':False,'reason':'Nested physical Keccak reduction exceeded recursion limit; no replacement premise or native axiom','source_identity_count':len(inputs['entries']),'package_pin_count':len(inputs['package_pins']),'scoped_active_axiom_queries':len(axioms),'scoped_allowed_axioms':['propext','Classical.choice','Quot.sound']},
'compiled_oleans':{p:sha(ROOT/'.lake/build/lib/lean'/Path(p).with_suffix('.olean')) for p in new},
'native_diagnostics':{'command':'python3 audit/address-request-call/run-diagnostics.py','exit_code':0,'checks':8,'kernel_proof':False,'ffi':'Fresh official wrappers + recorded C inputs, temporary dylib; no source changes'},
'solidity':{'command':'forge test --root audit/address-request-call/solidity --fuzz-seed 0x20260911 -vv','exit_code':0,'tests':12,'fuzz_tests':1,'fuzz_runs':1024,'forge_version':subprocess.check_output(['forge','--version'],text=True).strip(),'full_core_dependency_files':sum(x['origin'].startswith('contracts/') for x in identities.values()),'openzeppelin_dependency_files':sum(x['origin'].startswith('npm:') for x in identities.values()),'full_legacy_runtime_tested':True,'whole_entrypoint_tested':False,'experimental_ir_full_harness':'failed: solc IRVariable.cpp:52 Invalid stack item name: slot; restricted probe only, different push length behavior'},
'sha256':{p.relative_to(ROOT).as_posix():sha(p) for p in sorted(paths)}}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('PASS receipt:',len(paths),'artifact/input hashes;',len(inputs['entries']),'Lean source identities;',len(identities),'Solidity compiler source files')
