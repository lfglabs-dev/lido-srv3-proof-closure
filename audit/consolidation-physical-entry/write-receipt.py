#!/usr/bin/env python3
"""Author recording only. Rewrites this new dossier's receipt; no compilation."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
paths=[ROOT/'audit/trio/consolidation/PhysicalEntrySettlement.lean',ROOT/'LidoSRv3/Audit/Guarantees/PConsolidationEth1PhysicalEntry.lean',ROOT/'LidoSRv3/Tests/TrioConsolidation/PhysicalEntrySettlement.lean']
paths+=sorted(p for p in OUT.rglob('*') if p.is_file() and p!=OUT/'receipt.json')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
receipt={'base':'82051ab0a552734712b8f33e3f96f0074bf9ee39','scope':'SOURCE candidate: physical actual caller role then checked entry balance then resumed gate; entire8205 quota/settlement/decoded requests on actual post-quota World; original credited-entry rollback. Independent review/integration required.',
 'checks':{'normal_jobs':1272,'actual_source_identities':1255,'package_pins':11,'ordinary_foundation_scopes':22,'kernel_regressions':14,'public_instances':2,'fresh_solidity_cases':8,'fuzz_runs':1024,'fresh_compiler_inputs':25,'fresh_artifacts':2,'full_gateway_ir_lines':2610,'reused_support_artifacts':3,'native_execution_groups':6,'independent_nested_keccak_vectors':4},
 'files':{str(p.relative_to(ROOT)):sha(p) for p in sorted(paths)},
 'config_sha256':{n:sha(ROOT/n) for n in ['lakefile.lean','lake-manifest.json','lean-toolchain']},
 'raw_whitespace':{'audit/consolidation-physical-entry/solidity/PhysicalEntryHarness.ir':['EOF2610']}}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('Recorded',len(receipt['files']),'hashes; source+new dossier only')
