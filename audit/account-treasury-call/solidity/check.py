#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,subprocess
D=Path(__file__).resolve().parent; OLD=D.parents[1]/'account-fee-distribution'/'solidity'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
ident=json.loads((OLD/'source-identities.json').read_text())
for p,h in ident['sources'].items():
 assert sha(OLD/'vendor'/p)==h,p
 if p.startswith('contracts/'):
  assert subprocess.check_output(['git','-C',str(CORE),'show',PIN+':'+p])==(OLD/'vendor'/p).read_bytes(),p
for n in ['StethHarness.sol','DistributionHarness.sol']:
 assert (D/'src'/n).read_bytes()==(OLD/'src'/n).read_bytes(),n
s=(CORE/'contracts/0.8.9/Accounting.sol').read_text();a=s.index('    function _distributeFee(');b=s.index('\n    /// @dev Notify observer',a)
assert s[a:b] in (D/'src/DistributionHarness.sol').read_text()
compiled={};sources={}
for name,file in [('StethHarness','StethHarness.sol'),('DistributionHarness','DistributionHarness.sol'),('RawTreasury','TreasuryCall.t.sol'),('TreasuryCallTest','TreasuryCall.t.sol')]:
 artifact=json.loads((D/'out'/file/(name+'.json')).read_text());meta=artifact['metadata']
 for p,record in meta['sources'].items():
  path=D/p;data=path.read_bytes()
  assert subprocess.check_output(['cast','keccak','0x'+data.hex()],text=True).strip()==record['keccak256'],p
  sources[p]=sha(path)
 dest=D/('compiled-'+name+'.json');dest.write_text(json.dumps(artifact,indent=2)+'\n')
 compiled[name]={'compiler':meta['compiler'],'settings':meta['settings'],'artifact_sha256':sha(dest)}
assembly=(D/'DistributionHarness.asm').read_text()
for text in ['0x61d027b3','extcodesize','staticcall','LIDO_LOCATOR.treasury()','slt','and','eq']:
 assert text in assembly,text
log=(D.parent/'solidity-test.log').read_text();assert '9 passed; 0 failed' in log
(D/'validation.json').write_text(json.dumps({'pin':PIN,'fresh_tests':9,'original_dependency_identities':len(ident['sources']),
 'copied_fixture_sources_identical':True,'accounting_distribution_body_identical':True,
 'compiled_sources':sources,'compiled':compiled,'assembly_sha256':sha(D/'DistributionHarness.asm'),
 'scope':'Actual exact Accounting distribution fragment, unchanged inherited StETH/setup fixture; real STATICCALL caller/selector/post-module effects, arbitrary return bytes/ABI/revert/readonly guards. Not full Accounting deployment or compiled report/mint equivalence; no-code test credits rejection/rollback, not intercepted revert bytes.'},indent=2)+'\n')
print(f'PASS: 9 fresh Solidity cases, {len(sources)} compiler input identities, {len(ident["sources"])} retained StETH dependencies, 4 artifact snapshots and fresh assembly; exact distribution fragment.')
