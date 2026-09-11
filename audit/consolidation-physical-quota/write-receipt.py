#!/usr/bin/env python3
"""Author recording only. Rewrites this new dossier's receipt; no compilation."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
paths=[ROOT/'audit/trio/consolidation/PhysicalQuotaSettlement.lean',ROOT/'LidoSRv3/Audit/Guarantees/PConsolidationEth1PhysicalQuota.lean',ROOT/'LidoSRv3/Tests/TrioConsolidation/PhysicalQuotaSettlement.lean']
paths+=sorted(p for p in OUT.rglob('*') if p.is_file() and p!=OUT/'receipt.json')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
receipt={'base':'1cd11a4719ce9dec72f0c7dcffde5bcd7848f28d','scope':'SOURCE candidate: physical executing-gateway quota then entire accepted settlement/decoded requests on actual post-quota World; original credited-entry rollback. Independent review/integration required.',
 'checks':{'normal_jobs':1269,'actual_source_identities':1252,'package_pins':11,'ordinary_foundation_scopes':30,'kernel_regressions':16,'public_instances':2,'fresh_solidity_cases':12,'fuzz_runs':1024,'fresh_compiler_inputs':24,'fresh_artifacts':4,'full_gateway_ir_lines':2456,'reused_legacy_inputs':2},
 'files':{str(p.relative_to(ROOT)):sha(p) for p in sorted(paths)},
 'config_sha256':{n:sha(ROOT/n) for n in ['lakefile.lean','lake-manifest.json','lean-toolchain']},
 'raw_whitespace':{'audit/consolidation-physical-quota/solidity/PhysicalQuotaHarness.ir':['EOF2456'],
  'audit/consolidation-physical-quota/validation/development-public-word-name.log':[136,142],
  'audit/consolidation-physical-quota/validation/development-test-word-name.log':[168,342,348,373,379,403,422]}}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('Recorded',len(receipt['files']),'hashes; source+new dossier only')
