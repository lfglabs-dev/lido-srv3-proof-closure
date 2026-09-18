"""Exact candidate synchronization constants; no independent review credit.

The frozen historical R1 fingerprints remain in audit_metadata.py. These
constants bind current statements and disclosures described in the candidate
report. Changing them requires reviewing the corresponding source/metadata delta.
"""

CANDIDATE_INPUT_SHA256 = {
    "audit/guarantees.yaml": "d2fb7ac5420cf221638b9c17f9c33e606ac171baa0061d74df0d7af744729841",
    "audit/source-map.yaml": "6d6e6a3c2b34faa4556c2938b9c098c3297fc35640f3ffe5c90790ca18c5cbc0",
    "audit/trust-native-decide-allowlist.txt": "41b3048a7d18e32af1b585e8a7ecc1fcb6615033947f5e655ae30bda1e71f375"
}


EXPECTED_CANONICAL_CLAIMS = {
    "P-ALLOC-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PAlloc1.account_allocation_result', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-SUPPORTED-MODULES')),
    "P-ALLOC-2": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc2.step_correspondence_and_full_loop_conservation", "CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc2.verity_tx_simulates_min_first_distribution", "IMPLEMENTATION_PENDING", ("A-VERITY-SCAFFOLD", "A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE")),
    "P-DEPOSIT-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PDeposit1.actual_deposit_call_slot_success_and_revert', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-NO-REENTRY')),
    "P-TOPUP-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall.actual_topup_admission_calls_wei_and_revert', 'IMPLEMENTATION_PENDING', ('A-ABSTRACT-TX', 'A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-NO-REENTRY')),
    "P-ACCOUNT-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PAccount1.router_accounting_order_discipline', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PAccount1.actual_report_accounting_call', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-RESERVE-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PReserve1LiveWriters.actual_reserve_physical_history', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-NO-REENTRY')),
    "P-CONSOLIDATION-ETH-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidationEth1.eth_flow_parent_at_canonical', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_vault_live_success_and_revert', 'IMPLEMENTATION_PENDING', ('A-ABSTRACT-TX', 'A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-NO-REENTRY')),
    "P-ADDRESS-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PAddress1.universal_address_writer_equivariance', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PAddress1.abstract_source_verity_tx_address_equivariance', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-NO-REENTRY')),
    "P-TOPUP-2": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PTopup2.router_exact_sum_bounded_under_gateway_shape', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PTopup2.actual_module_batch_bound', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-CONSOLIDATION-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity_from_gateway', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_vault_live_success_and_revert', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-SSZ-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.real_validator_correspondence", "CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.actual_compiled_cl_entry_complete_declared_branch", "IMPLEMENTATION_PENDING", ("A-SHA256-FFI", "A-MULTI-NODE-TRANSPORT", "A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE")),
}
EXPECTED_CANONICAL_DETAIL_SHA256 = {
    "P-ALLOC-1": "d4ddb86616f3a64d82352b9ab91ce900483137de921d47b9f6f4763cd2a6f816",
    "P-ALLOC-2": "da823989d09d055e815b87022274d8767387b63f45a174caf11ac0f64cfaeb5b",
    "P-DEPOSIT-1": "9970f151765ebc8e33fddec892424465f1d5b28f9fc96491696fa92beb3ae6aa",
    "P-TOPUP-1": "35d101d83aed37e5d2016a22d816b049a700ae2603f933166892201416889816",
    "P-ACCOUNT-1": "115e40ac3c5c71aa5b617c2d91a21bbfb848ce3bbac37250a8b51dfac00b1741",
    "P-RESERVE-1": "5ca806549b93c15066cdfbfd9ccafa15a82a98dfa37e050cac0d09bdabf310af",
    "P-CONSOLIDATION-ETH-1": "ea20254695e56b757219205682423b139e377c01574d8f77d00d912d251eb5f1",
    "P-ADDRESS-1": "6fe5cf0df3a018a3c142096427333b5659c2f568d64446707c0a75e059941b65",
    "P-TOPUP-2": "ff63f8f3e888714d21f7c3b55488608e8870cdf99716f5c9d25d5bba93cce685",
    "P-CONSOLIDATION-1": "b4e89d3ffd97043bc0693fc0a1cc35dbeefd3846d35974095f46ce23b4e3fe7b",
    "P-SSZ-1": "761b258d12e90d0f1d6ae6d4202a9336692b1941f16d2c81b3f168e6f119d39c",
}
