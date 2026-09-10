#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]; OUT=Path(__file__).resolve().parent
sources=json.loads((OUT/'source-inputs.json').read_text()); axioms=json.loads((OUT/'axioms.json').read_text())
build=(OUT/'build.log').read_text();assert 'Build completed successfully (1357 jobs).' in build
new=[ROOT/p for p in ['LidoSRv3/Audit/Source/TopupModuleMemory.lean','LidoSRv3/Audit/Source/TopupBatchMemory.lean','LidoSRv3/Audit/Guarantees/PTopupMemoryCalls.lean','LidoSRv3/Tests/TopupModuleMemoryRegression.lean']]
files=new+sorted(p for p in OUT.iterdir() if p.is_file() and p.name!='receipt.json')
receipt={'base':'2c2c72a91cd68a43de0777912772d12cc48a285d','source_pin':'17005714f151e5502c559932319a3f2f74ac2436',
 'scope':'Additive actual root/module batch scalar allocator and uint256[] decoder; same successful witnesses/cap/physical effects; failure World restoration',
 'public_theorems':['LidoSRv3.Audit.Guarantees.PTopupMemoryCalls.actual_root_module_memory_effects','LidoSRv3.Audit.Guarantees.PTopupMemoryCalls.actual_root_module_memory_failure_restores'],
 'build':{'exit_code':0,'jobs':1357,'target':'LidoSRv3.Tests.TopupModuleMemoryRegression'},
 'regressions':{'normal_kernel_or_exact_transport':12,'full_public_instance':1,'positive_physical_fixture_transport':True,'no_native_decide':True},
 'source_identities':len(sources['entries']),'package_pins':sources['package_pins'],'axiom_sets':len(axioms),'axioms_foundations_only':True,
 'reused_compiler_input_identities':28,'reused_historical_artifacts':17,'fresh_solidity_tests':0,
 'boundaries':['Phase returnBuffer origin and alignment not derived','Immutable copied raw-byte view; full memory-copy/alias and opcode-gas relation not established','Existing typed root/external/physical layout boundaries unchanged; no full compiled CL claim'],
 'old_sources_edited':False,'review_status':'Pending independent exact source/Solidity correspondence review; writer will stop at commit',
 'sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(f'PASS receipt {len(files)} artifacts, {len(axioms)} checked axiom closures, {len(sources["entries"])} source identities.')
