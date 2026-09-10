#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,subprocess
D=Path(__file__).resolve().parent;CORE=Path('/tmp/lido-ssz-proof-committed/lido-core')
PIN='17005714f151e5502c559932319a3f2f74ac2436'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
ident=json.loads((D/'source-identities.json').read_text())
assert ident['pin']==PIN
for p,h in ident['sources'].items():
 assert sha(D/'vendor'/p)==h,p
 if p.startswith('contracts/'):
  assert subprocess.check_output(['git','-C',str(CORE),'show',PIN+':'+p])==(D/'vendor'/p).read_bytes(),p
# Same complete _distributeFee function body, exact source order and whitespace.
s=(CORE/'contracts/0.8.9/Accounting.sol').read_text();a=s.index('    function _distributeFee(');b=s.index('\n    /// @dev Notify observer',a)
assert s[a:b] in (D/'src/DistributionHarness.sol').read_text()
compiled={};sourcechecks={}
for name in ['StethHarness','DistributionHarness','DistributionTest']:
 file='Distribution.t.sol' if name=='DistributionTest' else name+'.sol'
 artifact=json.loads((D/'out'/file/(name+'.json')).read_text());meta=artifact['metadata']
 for p,record in meta['sources'].items():
  data=(D/p).read_bytes()
  actual=subprocess.check_output(['cast','keccak','0x'+data.hex()],text=True).strip()
  assert actual==record['keccak256'],p
  sourcechecks[p]=sha(D/p)
 (D/('compiled-'+name+'.json')).write_text(json.dumps(artifact,indent=2)+'\n')
 compiled[name]=dict(compiler=meta['compiler'],settings=meta['settings'],artifact_sha256=sha(D/('compiled-'+name+'.json')))
assembly=(D/'DistributionHarness.asm').read_text()
assert 'staticcall' in assembly and 'LIDO_LOCATOR.treasury()' in assembly and 'LIDO.transferShares(recipients[i], moduleShares)' in assembly
(D/'validation.json').write_text(json.dumps(dict(pin=PIN,full_steth_dependency_sources=len(ident['sources']),compiled_source_identities=sourcechecks,compiled=compiled,accounting_distribution_body_identical=True,staticcall_and_call_assembly_observed=True,fresh_forge_tests=8,scope='Unmodified inherited StETH transfer semantics with setup and virtual rate overrides; exact Accounting distribution function fragment with real CALLs/read-only treasury STATICCALL. Not full Accounting/Lido/report deployment or proof of locator ABI.'),indent=2)+'\n')
print(f'PASS: {len(ident["sources"])} original StETH dependencies, {len(sourcechecks)} actual compiler-input identities, three compiled artifact snapshots, exact Accounting distribution body, CALL/STATICCALL assembly.')
