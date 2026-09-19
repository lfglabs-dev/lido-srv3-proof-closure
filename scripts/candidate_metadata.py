"""Exact candidate synchronization constants; no independent review credit.

The frozen historical R1 fingerprints remain in audit_metadata.py. These
constants bind current statements and disclosures described in the candidate
report. Changing them requires reviewing the corresponding source/metadata delta.
"""

CANDIDATE_INPUT_SHA256 = {
    "audit/guarantees.yaml": "98215bad0077559fa2bd200315a1581be36a0091a8c3274a5088a1e88c69520b",
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
    "P-CONSOLIDATION-ETH-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidationEth1.eth_flow_parent_at_canonical', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_witness_admission_live_success_and_revert', 'IMPLEMENTATION_PENDING', ('A-ABSTRACT-TX', 'A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-NO-REENTRY', 'A-SHA256-FFI')),
    "P-ADDRESS-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PAddress1.universal_address_writer_equivariance', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PAddress1.abstract_source_verity_tx_address_equivariance', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-NO-REENTRY')),
    "P-TOPUP-2": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PTopup2.router_exact_sum_bounded_under_gateway_shape', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PTopup2.actual_module_batch_bound', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE')),
    "P-CONSOLIDATION-1": ('CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity_from_gateway', 'CHECKED', 'LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_witness_admission_live_success_and_revert', 'IMPLEMENTATION_PENDING', ('A-SOURCE-SHAPED', 'A-VERITY-SCAFFOLD', 'A-SOLC-TRUSTED', 'A-RUNTIME-PROVENANCE', 'A-SHA256-FFI')),
    "P-SSZ-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.real_validator_correspondence", "CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.actual_compiled_cl_entry_complete_declared_branch", "IMPLEMENTATION_PENDING", ("A-SHA256-FFI", "A-MULTI-NODE-TRANSPORT", "A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE")),
}
EXPECTED_CANONICAL_DETAIL_SHA256 = {
    "P-ALLOC-1": "d4ddb86616f3a64d82352b9ab91ce900483137de921d47b9f6f4763cd2a6f816",
    "P-ALLOC-2": "0e740a710f1dc7b8110b8ed43ef4cc75dae08fd0aa8b80fa0c82e099f2501efa",
    "P-DEPOSIT-1": "9c50dec0a7e3e95aa17ab9da6925f2a2b8021030467345e92d1562521ac51517",
    "P-TOPUP-1": "407a1a0df3cc76d26547605328d8dceb0b107376b7b67b209ed9446740b495ef",
    "P-ACCOUNT-1": "ff5d9bf073fb6684e37187aa6f039b0ffb09809852d94f539af94b7b3e1d499c",
    "P-RESERVE-1": "1ce8879384dbd9da986d20f3ddaa0e3a5ca8b520d6e91cb92ef54629dd3cd6f9",
    "P-CONSOLIDATION-ETH-1": "d7266a4d024b2a6c7655869de9b3f3385e13484a0286d6674f053f64cd3deb90",
    "P-ADDRESS-1": "a12051f53c9b2b9f075ff4209336a6dca552ddfd85b64d98c6da1377f37929ed",
    "P-TOPUP-2": "8f00698895bc27c579cc055e4baff3448eb4a135a193bf1ba095be834856a3ae",
    "P-CONSOLIDATION-1": "0144b41700d54359c89d41eb1d1141d98c3d7d64a6e5773f53427ab10d1a6ae4",
    "P-SSZ-1": "761b258d12e90d0f1d6ae6d4202a9336692b1941f16d2c81b3f168e6f119d39c",
}
