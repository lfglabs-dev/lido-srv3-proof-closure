#!/usr/bin/env python3
"""Seal the completed candidate's scoped validation, without claiming integration."""
from pathlib import Path
import datetime
import hashlib
import json
import re
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
closure=json.loads((OUT/'source-inputs.json').read_text())
axioms=json.loads((OUT/'axioms.json').read_text())
build=(OUT/'target-build.log').read_text()
assert 'Build completed successfully (1299 jobs).' in build
assert not re.search(r'^error:',build,re.M)
assert all(set(a)<={'propext','Classical.choice','Quot.sound'} for a in axioms.values())
modules=[
 'LidoSRv3/Audit/Source/TopupGatewayRootCalls.lean',
 'LidoSRv3/Audit/Source/TopupBatchRootCalls.lean',
 'LidoSRv3/Audit/Guarantees/PTopup2RootCalls.lean',
 'LidoSRv3/Tests/TopupBatchRootCallsRegression.lean',
]
paths=[ROOT/p for p in modules]+[p for p in OUT.iterdir() if p.is_file() and p.name!='receipt.json']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
receipt={
 'schema':'lido-topup-root-call-batch-v1',
 'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'base':'ea5774a82facf0d474e68058c4645ebf4380d403',
 'source_pin':'17005714f151e5502c559932319a3f2f74ac2436',
 'public_theorem':'LidoSRv3.Audit.Guarantees.PTopup2.actual_root_module_batch_bound',
 'scope':'Additive typed actual root STATICCALL witness loop feeds unchanged actual module executor on one World; ordered authentication and packed cap derive jointly from success. Prior claims and compiled/ABI/crypto/full-entry boundaries preserved.',
 'build':{'command':'lake build LidoSRv3.Audit.Guarantees.PTopup2RootCalls LidoSRv3.Tests.TopupBatchRootCallsRegression',
          'exit_code':0,'jobs':1299,'existing_pinned_dependency_cache_reused':True},
 'kernel_regressions':11,'public_consumer_instantiations':1,
 'source_identities':len(closure['entries']),
 'local_source_identities':sum(e['local'] for e in closure['entries']),
 'package_pins':closure['package_pins'],
 'independently_recomputed_scoped_axiom_sets':len(axioms),'new_axioms':0,
 'solidity':{'fresh_run':False,'unchanged_compiler_source_fixture_identities':45,
             'inherited_receipts':3,'new_compiled_composition_refinement':False},
 'sha256':{str(p.relative_to(ROOT)):sha(p) for p in sorted(paths)},
 'status':'Candidate complete; independent full-source/pinned-Solidity review and root integration pending.'}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(f"PASS: sealed {len(paths)} input/evidence identities, {len(axioms)} axiom sets, {len(closure['entries'])} source identities.")
