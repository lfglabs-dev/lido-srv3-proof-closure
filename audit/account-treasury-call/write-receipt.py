#!/usr/bin/env python3
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
sources=json.loads((OUT/'source-inputs.json').read_text());axioms=json.loads((OUT/'axioms.json').read_text());sol=json.loads((OUT/'solidity/validation.json').read_text())
log=(OUT/'build.log').read_text();assert 'Build completed successfully (35 jobs).' in log and 'PASS: cached prerequisites and four new modules' in log
new=[ROOT/p for p in ['audit/trio/account-address/TreasuryCall.lean','audit/trio/account-address/ReportFeeTreasuryCall.lean','audit/trio/account-address/Tests/Verity/ReportFeeTreasuryCallTest.lean','LidoSRv3/Audit/Guarantees/PAccount1TreasuryCall.lean']]
files=new+sorted(p for p in OUT.rglob('*') if p.is_file() and p.name!='receipt.json' and not any(x in p.relative_to(OUT).parts for x in ['out','cache','__pycache__']))
r={'base':'eee5d6700e5d99cc35eab7bf3e1e2b51a2465857','source_pin':'17005714f151e5502c559932319a3f2f74ac2436',
 'scope':'Same ACCOUNT report/mint/modules then actual typed readonly treasury request on their real returned ACCOUNT World, canonical decoded recipient actually paid, preserved ledger/events/rollback',
 'public_theorems':['LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_treasury_call','LidoSRv3.Audit.Guarantees.PAccount1.actual_report_treasury_failure_restores'],
 'build':{'cached_prerequisite_jobs':35,'new_sequential_modules':4,'exit_code':0},'kernel_regressions_and_consumer':12,
 'source_identities':len(sources['entries']),'package_pins':sources['package_pins'],'pinned_solidity_bodies':5,'axiom_sets':len(axioms),'foundations_only':True,
 'fresh_solidity_tests':sol['fresh_tests'],'compiler_input_identities':len(sol['compiled_sources']),'original_steth_dependencies':29,
 'profile':'solc0.8.9 + inherited StETH0.4.24, optimizer200, common fixture Byzantium',
 'boundaries':['Actual ACCOUNT World remains separate from Live.World; abstract shares map unchanged','Locator immutable and code metadata supplied context, no deployment/context provenance proof','Arbitrary readonly locator implementation and existing copied-byte/memory/gas boundaries; no full compiled report/Lido claim'],
 'existing_sources_modified':False,'review_status':'Pending independent exact commit/source/Solidity review; author stopped after commit',
 'sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
(OUT/'receipt.json').write_text(json.dumps(r,indent=2)+'\n');print(f'PASS receipt: {len(files)} exact artifacts, {len(axioms)} axiom closures, {len(sources["entries"])} sources, {sol["fresh_tests"]} fresh Solidity tests.')
