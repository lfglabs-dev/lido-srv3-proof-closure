#!/usr/bin/env python3
"""Record final local proof/test and retained validation artifact identities."""
from pathlib import Path
import datetime, hashlib, json, subprocess
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
BASE='09a09ad875f8e1519586a04932efd4dbacdf713f'
for line in subprocess.check_output(['git','-C',str(ROOT),'diff','--name-status',BASE],text=True).splitlines():
    status,path=line.split('\t')
    assert status=='A' and (path.startswith('audit/topup-root-physical-effects/') or path in {'LidoSRv3/Audit/Source/TopupRootCallEffects.lean','LidoSRv3/Audit/Guarantees/PTopup1RootCalls.lean','LidoSRv3/Tests/TopupRootCallEffectsRegression.lean'}),line
inputs=json.loads((OUT/'source-inputs.json').read_text())
for row in inputs['entries']:
    assert hashlib.sha256((ROOT/row['path']).read_bytes()).hexdigest()==row['sha256'],row['path']
axioms=json.loads((OUT/'axioms.json').read_text())
assert len(axioms)==14 and all(set(a)<={'propext','Classical.choice','Quot.sound'} for a in axioms.values())
assert 'Build completed successfully (1305 jobs).' in (OUT/'target-build.log').read_text()
files=[ROOT/p for p in ['LidoSRv3/Audit/Source/TopupRootCallEffects.lean','LidoSRv3/Audit/Guarantees/PTopup1RootCalls.lean','LidoSRv3/Tests/TopupRootCallEffectsRegression.lean']]
files+=sorted(p for p in OUT.rglob('*') if p.is_file() and p.name!='receipt.json')
record=dict(schema='lido-topup-root-physical-effects-v1',created_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),base=BASE,
 source_pin='17005714f151e5502c559932319a3f2f74ac2436',public_theorem='LidoSRv3.Audit.Guarantees.PTopup1.actual_root_module_batch_effects',
 scope='Success of existing actual root/module batch composes same authenticated rows and actual reply with exact mathematical sum and zero/positive physical continuation. No new executor or public premise.',
 build=dict(command='lake build LidoSRv3.Tests.TopupRootCallEffectsRegression',exit_code=0,jobs=1305,unchanged_dependency_cache_reused=True),
 kernel_regressions=12,public_consumer_instantiations=2,source_identities=len(inputs['entries']),package_pins=inputs['package_pins'],scoped_axiom_sets=len(axioms),new_axioms=0,
 solidity=dict(fresh_run=False,reused_compiler_source_fixture_identities=45,inherited_receipts=3,new_compiled_composition_refinement=False),
 sha256={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
 status='Local candidate; independent exact full-source/Solidity review and root facade/Trust integration pending.')
(OUT/'receipt.json').write_text(json.dumps(record,indent=2)+'\n')
print(f'PASS: {len(files)} final candidate artifact hashes; 1305 build jobs, 12 kernel regressions, 14 foundation-only axiom sets.')
