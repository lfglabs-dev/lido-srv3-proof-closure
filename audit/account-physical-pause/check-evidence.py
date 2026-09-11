from pathlib import Path
import json,hashlib,subprocess
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
B=Path('/tmp/lido-address-steth-quote');A=B/'audit/address-steth-quote-call';PIN='ee24f9dc158ed25cec118a8ab8cd3a4fc59942f1'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def run(*xs):return subprocess.check_output(xs,text=True).strip()
receipt=json.loads((A/'receipt.json').read_text())
for rel,h in receipt['files'].items():assert sha(B/rel)==h and (B/rel).read_bytes()==subprocess.check_output(['git','-C',str(B),'show',PIN+':'+rel]),rel
ident=json.loads((A/'solidity/lido/source-identities.json').read_text())
a=json.loads((A/'lido-compiler-artifact.json').read_text());assert len(a['metadata']['sources'])==37
for rel,info in a['metadata']['sources'].items():
 p=A/'solidity/lido'/rel
 assert run('cast','keccak','0x'+p.read_bytes().hex())==info['keccak256']
assert (O/'solidity/artifacts/Lido.json').read_bytes()==(A/'solidity/queue/artifacts/Lido.json').read_bytes()
assert run('cast','keccak','lido.Pausable.activeFlag')=='0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece'
# Only wrapper/interface fixture mintSetup is replaced by actual Lido.mintShares.
expected=(R/'audit/account-treasury-call/solidity/src/DistributionHarness.sol').read_text().replace('mintSetup','mintShares')
assert (O/'solidity/src/DistributionHarness.sol').read_text()==expected
fresh=json.loads((O/'solidity/artifacts/DistributionHarness.sol/DistributionHarness.json').read_text())
for rel,info in fresh['metadata']['sources'].items():assert run('cast','keccak','0x'+(O/'solidity'/rel).read_bytes().hex())==info['keccak256']
assert fresh['metadata']['compiler']['version']=='0.8.9+commit.e5eed63a'
assert fresh['metadata']['settings']['optimizer']=={'enabled':True,'runs':200}
assert fresh['metadata']['settings']['evmVersion']=='byzantium'
assert (O/'DistributionHarness.asm').read_text()==fresh['assembly']+'\n'
(O/'DistributionHarness-compiler-artifact.json').write_text(json.dumps(fresh,separators=(',',':'))+'\n')
test_records={}
for name in ['PhysicalPauseTest','Locator']:
 artifact=json.loads((O/'solidity/artifacts/PhysicalPause.t.sol'/(name+'.json')).read_text())
 for rel,info in artifact['metadata']['sources'].items():assert run('cast','keccak','0x'+(O/'solidity'/rel).read_bytes().hex())==info['keccak256']
 assert artifact['metadata']['compiler']==fresh['metadata']['compiler']
 (O/(name+'-compiler-artifact.json')).write_text(json.dumps(artifact,separators=(',',':'))+'\n')
 test_records[name]={'sources':len(artifact['metadata']['sources']),'artifact_sha256':sha(O/(name+'-compiler-artifact.json'))}
records={'borrowed_provider':PIN,'borrowed_path':str(B),'borrowed_receipt_hashes':len(receipt['files']),'core_pin':ident['core_pin'],'lido_compiler':a['metadata']['compiler'],'lido_settings':a['metadata']['settings'],'lido_inputs':ident,'full_Lido_assembly_sha256':sha(A/'Lido.asm'),'Lido_deployment_artifact_sha256':sha(O/'solidity/artifacts/Lido.json'),'new_caller_compiler':fresh['metadata']['compiler'],'new_caller_settings':fresh['metadata']['settings'],'new_caller_sources':len(fresh['metadata']['sources']),'new_caller_assembly_sha256':sha(O/'DistributionHarness.asm'),'fresh_tests':test_records,'tools':{'forge':run('forge','--version'),'cast':run('cast','--version')}}
# Keep complete original assembly locally, without recompiling the frozen compiler.
(O/'Lido.asm').write_bytes((A/'Lido.asm').read_bytes())
(O/'compiler-identities.json').write_text(json.dumps(records,indent=2)+'\n')
print('PASS exact111 borrowed evidence hashes; full37 Lido compiler metadata inputs, same deployed artifact, actual pause Keccak, exact Accounting distribution body, fresh0.8.9 caller and full source assemblies')
