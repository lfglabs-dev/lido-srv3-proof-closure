#!/usr/bin/env python3
"""Author recording only; rewrites this new source dossier receipt."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths=[ROOT/'LidoSRv3/Audit/Source/DepositAdmissionErrors.lean',ROOT/'LidoSRv3/Audit/Guarantees/PDeposit1AdmissionErrors.lean',ROOT/'LidoSRv3/Tests/DepositAdmissionErrorsRegression.lean']
paths+=sorted(p for p in OUT.rglob('*') if p.is_file() and p!=OUT/'receipt.json')
whitespace={}
for p in paths:
 text=p.read_text();lines=text.splitlines();bad=[i+1 for i,l in enumerate(lines) if l.rstrip(' \t')!=l]
 if text.endswith('\n\n'):bad.append('EOF'+str(len(lines)))
 if bad:whitespace[str(p.relative_to(ROOT))]=bad
receipt={'base':'b3b63586ecd72467dadc2e5ccdca220d820f15fb','scope':'SOURCE: local admission exact bytes and first-failing physical origin consumed with entire328 success/exact journals/original rollback. Separate independent review/integration required.',
 'checks':{'normal_jobs':1334,'actual_source_identities':1317,'package_pins':11,'ordinary_foundation_scopes':25,'direct_kernel_regressions':11,'transport_execution_theorems':4,'public_instances':3,'retained_solidity_cases':15,'retained_fuzz_cases':4,'runs_each':1024,'retained_compiler_closures':2,'sources_per_closure':28,'retained_receipt_hashes':99,'fresh_forge_compiler_native_runs':0},
 'files':{str(p.relative_to(ROOT)):sha(p) for p in sorted(paths)},'config_sha256':{n:sha(ROOT/n) for n in ['lakefile.lean','lake-manifest.json','lean-toolchain']},'raw_whitespace':whitespace}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print('Recorded',len(receipt['files']),'hashes; raw whitespace',whitespace)
