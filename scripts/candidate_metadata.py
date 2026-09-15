"""Exact candidate synchronization constants; no independent review credit.

The frozen historical R1 fingerprints remain in audit_metadata.py. These
constants bind current statements and disclosures described in the candidate
report. Changing them requires reviewing the corresponding source/metadata delta.
"""

CANDIDATE_INPUT_SHA256 = {
    "audit/guarantees.yaml": "8e83fa53e3b311a3182ea2e6f19cc1669335a8a9743a15234757a00b8325271e",
    "audit/source-map.yaml": "6d6e6a3c2b34faa4556c2938b9c098c3297fc35640f3ffe5c90790ca18c5cbc0",
    "audit/trust-native-decide-allowlist.txt": "41b3048a7d18e32af1b585e8a7ecc1fcb6615033947f5e655ae30bda1e71f375"
}


EXPECTED_CANONICAL_CLAIMS = {
    "P-ALLOC-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PAlloc1.account_allocation_result', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
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
    "P-ALLOC-1": "b3393971585363f28a8b9440edc262dff2320479f73a503825eecbbf9b3fb384",
    "P-ALLOC-2": "da823989d09d055e815b87022274d8767387b63f45a174caf11ac0f64cfaeb5b",
    "P-DEPOSIT-1": "191cae5dbb0cb0d29626d87363c8340b23c30d9b1e00a7006ae80bfd430c1385",
    "P-TOPUP-1": "7c2c62b6c799bde7f6f270bb4f6330a5fcf4c444f6fd78dc188a947118c51cf9",
    "P-ACCOUNT-1": "06ac470d8e22d26d7af92220328a70d496a59620129251bcd6dee808cad43608",
    "P-RESERVE-1": "bff7261f0cad0dd3508b1dab5923c7392f24506ed1187b955519e69b0680efc7",
    "P-CONSOLIDATION-ETH-1": "3935bbcf0895ad466c46d97f56370f1961f1e1c34e91c4021891a5863c18dfad",
    "P-ADDRESS-1": "85491ec889c6761f9401ce3aecac9fbd073f5f3c3211063541e7db9c8adbcc52",
    "P-TOPUP-2": "ca04466018ff4a65a36f95d6eb0d6d955f9d3b650ae142dff50498b1c242f9dc",
    "P-CONSOLIDATION-1": "b4e89d3ffd97043bc0693fc0a1cc35dbeefd3846d35974095f46ce23b4e3fe7b",
    "P-SSZ-1": "761b258d12e90d0f1d6ae6d4202a9336692b1941f16d2c81b3f168e6f119d39c",
}
