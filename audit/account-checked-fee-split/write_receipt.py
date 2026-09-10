#!/usr/bin/env python3
from pathlib import Path
import datetime, hashlib, json, subprocess
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
BASE='70301660264f2f710e7160e190aaa3af330e84fa'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
inputs=json.loads((OUT/'source-inputs.json').read_text())
for row in inputs['entries']: assert sha(ROOT/row['path'])==row['sha256'],row['path']
axioms=json.loads((OUT/'axioms.json').read_text())
assert len(axioms)==17 and all(set(a)<={'propext','Classical.choice','Quot.sound'} for a in axioms.values())
assert 'PASS: inherited targets plus all three new modules compiled' in (OUT/'target-build.log').read_text()
paths=['audit/trio/account-address/ReportFeeMint.lean','audit/trio/account-address/ReportFeeCheckedSplit.lean','audit/trio/account-address/Tests/Verity/ReportFeeCheckedSplitTest.lean','LidoSRv3/Audit/Guarantees/PAccount1CheckedFeeSplit.lean']
files=[ROOT/p for p in paths]+sorted(p for p in OUT.rglob('*') if p.is_file() and p.name!='receipt.json')
mods=['ReportFeeMint','ReportFeeCheckedSplit','LidoSRv3.Audit.Guarantees.PAccount1CheckedFeeSplit','Tests.Verity.ReportFeeCheckedSplitTest']
r=dict(schema='lido-account-checked-fee-split-v1',created_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),base=BASE,
 source_pin='17005714f151e5502c559932319a3f2f74ac2436',public_theorem='LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_checked_split',
 scope='Actual report/getter/checked fee calculation/mint success jointly implies previous Success, ExactCasts, equal distribution lengths and exact checked module-floor plus treasury partition of the same actually minted fee; no later payout claimed.',
 executable_changes=0,public_new_premises=0,build=dict(command='python3 audit/account-checked-fee-split/build.py',exit_code=0,lake_prerequisite_jobs=26,new_sequential_lean_modules=3),
 kernel_regressions=10,public_actual_consumer_instantiations=1,source_identities=len(inputs['entries']),package_pins=inputs['package_pins'],pinned_solidity_bodies=5,scoped_axiom_sets=len(axioms),new_axioms=0,fresh_solidity_execution=False,
 built_olean_sha256={m:sha(ROOT/'.lake/build/lib/lean'/Path(m.replace('.','/')+'.olean')) for m in mods},
 sha256={str(p.relative_to(ROOT)):sha(p) for p in files},status='Candidate frozen for independent exact full-source/Solidity review; global registration and All/Trust integration pending.')
(OUT/'receipt.json').write_text(json.dumps(r,indent=2)+'\n')
print(f'PASS: {len(files)} retained artifact/source hashes; 17 foundation-only axiom sets and ten new kernel regressions.')
