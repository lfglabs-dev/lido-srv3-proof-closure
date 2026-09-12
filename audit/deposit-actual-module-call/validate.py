#!/usr/bin/env python3
"""Focused reproducible checks; uses existing dependency caches, no network."""
from pathlib import Path
import hashlib,json,os,re,subprocess,time
HERE=Path(__file__).resolve().parent
ROOT=HERE.parent.parent
BASE='f8ea5f9d3cffc165f5d84dd96444836c806827eb'
CORE=Path(os.environ.get('LIDO_CORE','/tmp/lido-ssz-proof-committed/lido-core')).resolve()
CORE_PIN='17005714f151e5502c559932319a3f2f74ac2436'
DEP=Path(os.environ.get('LIDO_OZ','/tmp/lido-topup-wei-deps/package')).resolve()
LEAN_FILES=['audit/trio/deposit/ModuleCall.lean','audit/trio/deposit/ModulePhysicalMetadata.lean',
 'LidoSRv3/Audit/Guarantees/PDeposit1ModuleCalls.lean',
 'audit/trio/deposit/Tests/Verity/ModulePhysicalMetadataTest.lean']
def output(args,cwd=ROOT):return subprocess.check_output(args,cwd=cwd,text=True).strip()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(args,name,env=None):
    started=time.time()
    with (HERE/name).open('w') as f:
        result=subprocess.run(args,cwd=ROOT,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=900)
    if result.returncode:raise SystemExit(f'FAILED {name}: exit {result.returncode}')
    return {'argv':args,'log':name,'exit_code':result.returncode,'seconds':round(time.time()-started,3)}
assert output(['git','rev-parse','HEAD'],CORE)==CORE_PIN
assert output(['git','rev-parse','HEAD'],ROOT/'.lake/packages/verity')=='e977aaad6e1a9e92e0132d41b3d33a14135a4d46'
checks=[]
for i,name in enumerate(LEAN_FILES):
    dest=ROOT/'.lake/build/lib/lean'/Path(name).with_suffix('.olean')
    dest.parent.mkdir(parents=True,exist_ok=True)
    checks.append(run(['lake','env','lean','-o',str(dest),name],['module-call-lean.log','module-physical-lean.log','public-lean.log','tests-lean.log'][i]))
    log=(HERE/checks[-1]['log']).read_text()
    assert not re.search(r'(sorryAx|Lean\.ofReduceBool|error:|error\()',log),log
checks.append(run(['lake','env','lean','--run',str(HERE/'Export.lean')],'vectors.json'))
checks.append(run(['python3',str(HERE/'build_vectors.py')],'vectors-build.log'))
env=dict(os.environ,FOUNDRY_SRC='audit/deposit-actual-module-call/solidity',FOUNDRY_TEST='audit/deposit-actual-module-call/solidity')
common=['--remappings',f'contracts/={CORE}/contracts/','--remappings',f'@openzeppelin/contracts-v5.2/={DEP}/',
 '--out','/tmp/lido-deposit-actual-module-solidity-out','--cache-path','/tmp/lido-deposit-actual-module-solidity-cache']
checks.append(run(['forge','test',*common,'--match-contract','DepositModuleCallTest','--fuzz-runs','256','--fuzz-seed','0x20260910','--threads','2','-vv'],'solidity/validation.log',env))
checks.append(run(['forge','inspect',*common,'DepositModuleCallHarness','ir'],'solidity/DepositModuleCallHarness.ir.yul.txt',env))
# Normalize trailing blank lines only, keeping the generated IR diff-clean.
ir=HERE/'solidity/DepositModuleCallHarness.ir.yul.txt'
ir.write_text(ir.read_text().rstrip()+'\n')
checks.append(run(['forge','inspect',*common,'DepositModuleCallHarness','metadata'],'solidity/metadata.json',env))
meta=json.loads((HERE/'solidity/metadata.json').read_text())
assert meta['compiler']['version']=='0.8.25+commit.b61c2a91'
compiler_sources={}
for name,info in meta['sources'].items():
    p=Path(name) if Path(name).is_absolute() else ROOT/name
    # cast reads hex input from stdin, avoiding command length/quoting limits.
    got=subprocess.check_output(['cast','keccak'],input='0x'+p.read_bytes().hex(),text=True).strip()
    assert got==info['keccak256'],(name,got,info['keccak256'])
    compiler_sources[name]={'sha256':sha(p),'keccak256':got}
(HERE/'solidity/compiler-input-identities.json').write_text(json.dumps(compiler_sources,indent=2)+'\n')
# Every transitively imported local repository source is exact base content,
# apart from the explicitly new files. Package revisions/cached artifacts are
# retained separately: their presence is not claimed as a clean rebuild.
seen=set();pending=[x[:-5].replace('/','.') for x in LEAN_FILES];closure={}
while pending:
    module=pending.pop()
    if module in seen:continue
    seen.add(module)
    rel=Path(module.replace('.','/')+'.lean');p=ROOT/rel
    if not p.exists():continue
    content=p.read_text()
    if str(rel) not in LEAN_FILES:
        expected=subprocess.check_output(['git','show',f'{BASE}:{rel}'],cwd=ROOT)
        assert p.read_bytes()==expected,str(rel)
    item={'source_sha256':sha(p),'is_new':str(rel) in LEAN_FILES}
    obj=ROOT/'.lake/build/lib/lean'/rel.with_suffix('.olean')
    if obj.exists():item['olean_sha256']=sha(obj)
    closure[str(rel)]=item
    for line in content.splitlines():
        match=re.match(r'\s*(?:public\s+)?import\s+(.+)',line)
        if match:pending.extend(match[1].split('--')[0].split())
(HERE/'dependency-inputs.json').write_text(json.dumps(closure,indent=2,sort_keys=True)+'\n')
packages={p.name:output(['git','rev-parse','HEAD'],p) for p in (ROOT/'.lake/packages').iterdir() if (p/'.git').exists()}
core_sources={}
for rel in ['contracts/0.8.25/sr/StakingRouter.sol','contracts/0.8.25/sr/SRTypes.sol','contracts/0.8.25/sr/SRLib.sol',
 'contracts/0.8.25/sr/SRStorage.sol','contracts/0.8.25/lib/BeaconChainDepositor.sol','contracts/common/interfaces/IStakingModule.sol']:
    assert (CORE/rel).read_bytes()==subprocess.check_output(['git','show',f'{CORE_PIN}:{rel}'],cwd=CORE)
    core_sources[rel]=sha(CORE/rel)
(HERE/'source-check.json').write_text(json.dumps({'pin':CORE_PIN,'files_sha256':core_sources},indent=2)+'\n')
source_files={str(p.relative_to(ROOT)):sha(p) for p in HERE.rglob('*') if p.is_file() and p.name not in ['receipt.json','lean-sample.txt','ProbeBeforeEmpty.lean','probe-lean.log']}
source_files.update({p:sha(ROOT/p) for p in LEAN_FILES})
receipt={'base':BASE,'core_pin':CORE_PIN,'head_at_validation':output(['git','rev-parse','HEAD']),
 'lean':output(['lake','env','lean','--version']),'forge':output(['forge','--version']),
 'compiler':meta['compiler'],'settings':meta['settings'],'packages':packages,'checks':checks,
 'local_imported_sources':len(closure),'artifacts_sha256':source_files,
 'scope':'Focused fresh Lean/Forge checks using identified existing caches; no full dependency or deployed-bytecode rebuild.'}
(HERE/'receipt.json').write_text(json.dumps(receipt,indent=2,sort_keys=True)+'\n')
print(json.dumps({'status':'passed','lean_files':len(LEAN_FILES),'forge_tests':8,'fuzz_runs':256,'byte_vectors':64,'local_sources':len(closure)}))
