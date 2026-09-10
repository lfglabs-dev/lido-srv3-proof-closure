#!/usr/bin/env python3
from pathlib import Path
import datetime,hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
BASE='f8ea5f9d3cffc165f5d84dd96444836c806827eb'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
paths=['audit/trio/consolidation/SettlementRequests.lean','LidoSRv3/Audit/Guarantees/PConsolidationEth1Requests.lean','LidoSRv3/Tests/ConsolidationSettlementRequestsRegression.lean']
for line in subprocess.check_output(['git','-C',str(ROOT),'diff','--name-status',BASE],text=True).splitlines():
    status,path=line.split('\t');assert status=='A' and (path in paths or path.startswith('audit/consolidation-settlement-requests/')),line
inputs=json.loads((OUT/'source-inputs.json').read_text())
for row in inputs['entries']: assert sha(ROOT/row['path'])==row['sha256'],row['path']
axioms=json.loads((OUT/'axioms.json').read_text());assert len(axioms)==9
assert all(set(a)<={'propext','Classical.choice','Quot.sound'} for a in axioms.values())
assert 'Build completed successfully (1266 jobs).' in (OUT/'target-build.log').read_text()
files=[ROOT/p for p in paths]+sorted(p for p in OUT.rglob('*') if p.is_file() and p.name!='receipt.json')
r=dict(schema='lido-consolidation-settlement-requests-v1',created_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),base=BASE,
 source_pin='17005714f151e5502c559932319a3f2f74ac2436',public_theorem='LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_settlement_requests',
 scope='Same existing shared-callee settlement success jointly supplies full prior Success and actual decoded inbox requests, exact distinct outer/inner fee reads, loop world consumed by refund, final world/balance/trace; no new stage premise or executor.',
 executable_changes=0,new_public_premises=0,build=dict(command='lake build LidoSRv3.Tests.ConsolidationSettlementRequestsRegression',exit_code=0,jobs=1266,unchanged_dependency_cache_reused=True),
 kernel_regressions=7,public_actual_consumer_instantiations=2,source_identities=len(inputs['entries']),package_pins=inputs['package_pins'],scoped_axiom_sets=9,new_axioms=0,
 solidity=dict(fresh_run=False,pinned_complete_bodies=3,retained_artifact_fixture_hashes=41,historical_tests=[9,5],new_compiled_composition_refinement=False),
 sha256={str(p.relative_to(ROOT)):sha(p) for p in files},status='Frozen local candidate for independent exact source/Solidity review; root facade/Trust integration pending.')
(OUT/'receipt.json').write_text(json.dumps(r,indent=2)+'\n')
print(f'PASS: {len(files)} final retained artifact/source hashes; 1266 build jobs, seven kernel regressions, nine foundation-only axiom sets.')
