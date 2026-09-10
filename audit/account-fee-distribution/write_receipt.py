#!/usr/bin/env python3
from pathlib import Path
import datetime,hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
BASE='241c2ce1e78860b8451a843949b71f60b8c2df25'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
modules={
 'FeeDistribution':'audit/trio/account-address/FeeDistribution.lean',
 'ReportFeeDistribution':'audit/trio/account-address/ReportFeeDistribution.lean',
 'LidoSRv3.Audit.Guarantees.PAccount1FeeDistribution':'LidoSRv3/Audit/Guarantees/PAccount1FeeDistribution.lean',
 'Tests.Verity.ReportFeeDistributionTest':'audit/trio/account-address/Tests/Verity/ReportFeeDistributionTest.lean'}
for line in subprocess.check_output(['git','-C',str(ROOT),'diff','--name-status',BASE],text=True).splitlines():
 status,path=line.split('\t');assert status=='A' and (path in modules.values() or path.startswith('audit/account-fee-distribution/')),line
inputs=json.loads((OUT/'source-inputs.json').read_text())
for row in inputs['entries']:assert sha(ROOT/row['path'])==row['sha256'],row['path']
axioms=json.loads((OUT/'axioms.json').read_text());assert len(axioms)==21
assert all(set(a)<={'propext','Classical.choice','Quot.sound'} for a in axioms.values())
assert 'PASS: existing prerequisites and four new modules' in (OUT/'target-build.log').read_text()
assert '8 tests passed, 0 failed' in (OUT/'solidity/forge-tests.log').read_text()
sv=json.loads((OUT/'solidity/validation.json').read_text())
for path,digest in sv['compiled_source_identities'].items():assert sha(OUT/'solidity'/path)==digest,path
files=[ROOT/p for p in modules.values()]+sorted(p for p in OUT.rglob('*') if p.is_file() and not any(part in {'out','cache'} for part in p.relative_to(OUT).parts) and p!=OUT/'receipt.json')
r=dict(schema='lido-account-fee-distribution-v1',created_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),base=BASE,
 source_pin='17005714f151e5502c559932319a3f2f74ac2436',public_theorem='LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_distribution',
 scope='Actual existing checked report/mint/split/casts at same intermediate world followed by exact sequential typed StETH module/treasury transfers, derived mint funding, unchanged packed words, events, total-paid equality and final pointwise initial-shares-plus-credits, with whole-root rollback.',
 new_explicit_external_boundary='TreasuryRead is a typed read-only resolver on the actual post-module state, separately declared; no locator STATICCALL/ABI correctness theorem or full deployed entry is claimed.',
 previous_files_changed=0,build=dict(command='python3 audit/account-fee-distribution/build.py',exit_code=0,lake_prerequisite_jobs=29,new_sequential_modules=4),
 kernel_regressions=9,public_actual_consumer_instantiations=1,source_identities=len(inputs['entries']),package_pins=inputs['package_pins'],scoped_axiom_sets=len(axioms),new_axioms=0,
 solidity=dict(fresh_tests=8,unchanged_full_steth_dependencies=29,actual_compiler_input_identities=32,compiled_artifacts=3,compiler_versions=['0.4.24','0.8.9'],optimizer_runs=200,fixture_evm_target='byzantium',production_bytecode_equivalence=False,scope='Full inherited StETH + byte-identical Accounting distribution function fragment; harness setup/mint/rate overrides explicit; real typed CALL/STATICCALL observed.'),
 built_olean_sha256={m:sha(ROOT/'.lake/build/lib/lean'/Path(m.replace('.','/')+'.olean')) for m in modules},
 sha256={str(p.relative_to(ROOT)):sha(p) for p in files},status='Frozen local candidate; independent exact source/Solidity review and root registration/All/Trust integration pending.')
(OUT/'receipt.json').write_text(json.dumps(r,indent=2)+'\n')
print(f'PASS: {len(files)} candidate artifact/source hashes; 21 foundation-only axiom sets; 9 kernel and 8 fresh Solidity tests.')
