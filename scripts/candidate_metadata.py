"""Exact candidate synchronization constants; no independent review credit.

The frozen historical R1 fingerprints remain in audit_metadata.py. These
constants bind current statements and disclosures described in the candidate
report. Changing them requires reviewing the corresponding source/metadata delta.
"""

CANDIDATE_INPUT_SHA256 = {
    "audit/guarantees.yaml": "48dc27c2096a563867d8f0de536112afb825f4cbc07d3d9a685ac79e9b2dae4c",
    "audit/source-map.yaml": "65de3beb60c50a5a28942ccc24d7206205dbd7a9530fc4859d4dd873ae850239",
    "audit/trust-native-decide-allowlist.txt": "52b822c37a17525b9b569f7a7e37cb49bdb35f049c0f269e54b78a544f34360f"
}


EXPECTED_CANONICAL_CLAIMS = {
    "P-ALLOC-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PAlloc1.verity_tx_simulates_allocation_count_from_storage', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-ALLOC-2": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc2.step_correspondence_and_full_loop_conservation", "CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc2.verity_tx_simulates_min_first_distribution", "IMPLEMENTATION_PENDING", ("A-VERITY-SCAFFOLD", "A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE")),
    "P-DEPOSIT-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PDeposit1.actual_deposit_call_slot_success_and_revert', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-TOPUP-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall.actual_topup_admission_calls_wei_and_revert', 'IMPLEMENTATION_PENDING', ('A-ABSTRACT-TX', 'A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-ACCOUNT-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAccount1.router_accounting_order_discipline", "CHECKED", "LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_simulates_oracle_report", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD", "A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE")),
    "P-RESERVE-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PReserve1LiveWriters.actual_reserve_physical_history', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-CONSOLIDATION-ETH-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PConsolidationEth1.eth_flow_parent_at_canonical", "CHECKED", "LidoSRv3.Audit.Guarantees.PConsolidationEth1.verity_tx_success_and_revert_partition", "IMPLEMENTATION_PENDING", ("A-ABSTRACT-TX", "A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD", "A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE")),
    "P-ADDRESS-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PAddress1.universal_address_writer_equivariance', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PAddress1.abstract_source_verity_tx_address_equivariance', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-TOPUP-2": ("CHECKED", "LidoSRv3.Audit.Guarantees.PTopup2.router_exact_sum_bounded_under_gateway_shape", "CHECKED", "LidoSRv3.Audit.Guarantees.PTopup2.verity_tx_simulates_topup2_spec", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD", "A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE")),
    "P-CONSOLIDATION-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity_from_gateway', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_vault_live_success_and_revert', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-SSZ-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.real_validator_correspondence", "CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.actual_compiled_cl_entry_complete_declared_branch", "IMPLEMENTATION_PENDING", ("A-SHA256-FFI", "A-MULTI-NODE-TRANSPORT", "A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE")),
}
EXPECTED_CANONICAL_DETAIL_SHA256 = {
    "P-ALLOC-1": "e8add9462a1eb31c63b00020dde0431041c8afae2cb4f2d409d5a0aea5f58878",
    "P-ALLOC-2": "75c4c469c6a042930a29b8197689a03fd679de31f7f9156e7482d013d751becb",
    "P-DEPOSIT-1": "3c0fbeea216e9f4e7fb8de6b60bbcf28d28bb15e16f7c3baf302b0cb96ff1d41",
    "P-TOPUP-1": "7c2c62b6c799bde7f6f270bb4f6330a5fcf4c444f6fd78dc188a947118c51cf9",
    "P-ACCOUNT-1": "384e194ee3c3da6b66f532442104d65f6aea80eed5ef0207a643383a5ce0949a",
    "P-RESERVE-1": "eb5a5696b30caa5b290f80f0f60bb6ee56415c3476f363bc036cd1615cd90886",
    "P-CONSOLIDATION-ETH-1": "5f182e386487d0e8509b3d7d1ffb178705fa62a78602feb43442836ced4b8b9a",
    "P-ADDRESS-1": "664151352f236f5a2688fa2d93061962c05c12eb4bc904807daa42f3474c0ff3",
    "P-TOPUP-2": "aa114745909c7e21be3ec147f2b5678d55b4cfc435998df0d13275d4f9c8f9d9",
    "P-CONSOLIDATION-1": "39b0c6730f038eb52941fdb7e23fea4a19bfef84affea3dc6437478024e966fe",
    "P-SSZ-1": "761b258d12e90d0f1d6ae6d4202a9336692b1941f16d2c81b3f168e6f119d39c",
}
