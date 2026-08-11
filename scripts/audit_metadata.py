#!/usr/bin/env python3
"""Validate JSON-compatible YAML metadata and render review-only views.

This deliberately does not inspect or parse Lean. Lean remains the theorem
authority; the script only checks and renders declared structured metadata.
"""

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "audit"
EXPECTED_IDS = [
    "P-ALLOC-1",
    "P-ALLOC-2",
    "P-DEPOSIT-1",
    "P-TOPUP-1",
    "P-ACCOUNT-1",
    "P-RESERVE-1",
    "P-ETH-1",
    "P-ADDRESS-1",
    "P-TOPUP-2",
    "P-CONSOLIDATION-1",
    "P-SSZ-1",
]
SUBORDINATE_IDS = [
    "P-SSZ-1.deposit-data-root",
    "P-SSZ-1.abstract-digest",
    "P-CONSOLIDATION-1.abstract-flow-model",
    "P-ALLOC-1.eugene-bound",
    "P-ADDRESS-1.yul-interface-harness",
    "P-DEPOSIT-1.verity-tx-rollback.tx",
    "P-CONSOLIDATION-1.fee-refinement.tx",
    "P-SSZ-1.tx-execution-simulation",
    "P-ETH-1a",
    "P-ETH-1b",
    "P-DEREF-1",
]
SOURCE_TARGET_IDS = EXPECTED_IDS[:6] + ["P-ETH-1a", "P-ETH-1b"] + EXPECTED_IDS[7:]
SOURCE_TARGET_IDS = SOURCE_TARGET_IDS + ["P-DEREF-1"]
EXPECTED_AUTHORITY = (
    "Lean theorem statements and proofs are authoritative; this metadata does not "
    "close a semantic guarantee."
)
EXPECTED_WORDING = [
    "Checked pinned-source execution refines the independent allocation-capacity Audit model under explicit Uint256 bounds; proportional allocation amounts and EVM equivalence remain open.",
    "Pinned-source correspondence proves only the next-target selection rule; proportional allocation amounts and EVM equivalence remain open.",
    "Pinned-source correspondence proves branch-wise stake conservation and whole-transaction rollback for the deposit push; TxObservation remains an abstract transaction model, not an EVM execution trace.",
    "Pinned-source correspondence proves branch-wise top-up value conservation; an actual Verity Contract.run transaction suffix simulates source commit/revert and snapshot rollback with the two declared value-bearing calls, while linked-external effects, Yul, EVM, runtime bytecode, and deployment provenance remain open.",
    "Under an explicit independently established full-success premise, pinned-source correspondence proves that AccountingOracle writes the validated module-balance snapshot before Accounting reads rewards and conditionally reports minted shares exactly when fee shares are positive; the SOURCE-to-VERITY_TX refinement includes checked Uint256 and uint64 accumulation, while later source guards, Yul, EVM, runtime, crypto, and E2E are not modeled or remain open.",
    "Pinned source-shaped reserve spending is simulated by executable Verity Contract.run semantics into the abstract transaction/spec, proving withdrawal-reserve non-interference and rollback across checked-Uint256 failures; Yul, EVM, runtime-bytecode, crypto, and E2E layers remain open or not applicable.",
    "The complete ETH-flow guarantee remains open across ConsolidationBus, ConsolidationGateway, WithdrawalVault, the EIP-7002 and EIP-7251 request contracts, Lido, and arbitrary refund recipients; the checked child models cover only bounded interfaces.",
    "Permissionless transfer, request, claim, and redemption entrypoints must admit arbitrary eligible users without caller-address discrimination and produce successful post-states equivariant under caller renaming; singleton-actor functions are excluded and covered by authentication-integrity properties.",
    "Per-validator top-up headroom and aggregate budget conservation are proved; verifier-binding remains BLOCKED.",
    "Consolidation requests must be eligible, correctly bound, value-conserving and atomic. Fee-refinement and abstract-flow sub-rows are merged; batch eligibility, replay protection, and composition theorem remain open.",
    "The mapped SSZ helper and wrapper scope remains open: GIndex.concat, SSZ.verifyProof, and the three wrapper call sites have only a MODEL-layer structural witness binding; SHA-256/precompile semantics are STRETCH_OPAQUE_FFI, while EVM and production provenance remain open.",
    "Source-shaped MODEL-plane evidence derives the signature root from raw signature bytes and proves only the deposit-data-root control-flow shape with a public-key-anchored, nonconstant structural witness binding; the SOURCE plane remains OPEN, SHA-256/precompile semantics remain STRETCH_OPAQUE_FFI, and EVM and production provenance remain BLOCKED.",
    "Typed low-level Verity statements bind the exact seven SHA-256 calls, 64-byte preimages, 32-byte digests, and nested deposit-data-root composition to the pinned pure-Lean SHA-256 engine; functional SHA-256 correctness remains assumed, and no Verity execution simulation is claimed.",
    "Typed low-level Verity statements bind the exact 48-byte source key followed by the exact 48-byte target key, with no padding, to one CALL carrying the resulting 96-byte payload; no amount, SHA-256 call, loop, or rollback composition is present, and no Yul or EVM execution refinement is claimed.",
    "Canonical checked SRLib rows composed with the MinFirst mutation prove that one operator reward share is bounded by the configured bond headroom; this is subordinate MODEL/ALGORITHM evidence only and does not establish EVM equivalence.",
    "Typed Yul builtin abstractions at the exact EVMYulLean pin (`f7e4ee0d`) bind a small abstract Yul program with `mstore-address`, `calldataload-address`, `sload-address`, and `calldatacopy-source-target` to the abstract address-renaming relation from `LidoSRv3.Audit.Guarantees.PAddress1`; one mutant vector is exercised and proven NOT to build, demonstrating mutant sensitivity, and no EVM execution refinement is claimed.",
    "Source-shaped deposit prefix scaffold (OPEN): the Verity FunctionSpec compiles locator-derived DSM authentication, module membership/config extraction, withdrawal-credentials conversion, immutable LIDO.getDepositableEther, and 32-byte successful-returndata checks. Allocation and the multi-contract suffix remain OPEN; this is not a full source, transaction, conservation, or rollback proof.",
    "Source-shaped bounded FunctionSpec scaffold for the pinned WithdrawalVault consolidation entrypoint. Constructor nonzero guards and the preservesEthBalance assertion are represented syntactically, but dynamic ABI decoding, calls, events, balance rollback, and source/transaction correspondence remain OPEN because Verity does not connect FunctionSpec execution to CallProgram and DenoteMemory traces.",
    "Concrete Verity transaction-plane evidence stages the exact DepositData calldata layout, performs the seven address-2 SHA-256 calls, checks the expected root, and restores the transaction snapshot on failure; SHA-256 functional correctness remains assumed under A-SHA256-FFI.",
    "The bounded abstract model confines ETH returned through the protocol-controlled stVault rebalance/redemption interface to Lido or the WithdrawalQueue; raw owner-controlled StakingVault.withdraw is excluded, and source and executable correspondence remain open.",
    "The bounded abstract consolidation-fee model confines its fee-bearing call to cfg.consolidationRequest; equating that immutable configurable address with the canonical EIP-7251 deployment is a separate provenance obligation.",
]
EXPECTED_ASSUMPTIONS = {
    "schema": "lido-srv3-assumptions-v1",
    "certification": {
        "status": "DEV-431-READY",
        "audit_cert": False,
        "statement": "DEV-431-READY is development readiness, not AUDIT-CERT.",
    },
    "assumptions": [
        {"id": "A-MODEL-INPUTS", "accepted": True,
         "risk": "Quantity bounds and units remain model inputs until source refinement is proved."},
        {"id": "A-ABSTRACT-TX", "accepted": True,
         "risk": "Common success/revert semantics are abstract and are not executable EVM trace semantics."},
        {"id": "A-SOURCE-SHAPED", "accepted": True,
         "risk": "Source-shaped inputs are not extracted from independently verified pinned Solidity spans."},
        {"id": "A-TOPUP-NOWRAP", "accepted": True,
         "risk": "The unbounded-Nat top-up model reads the unchecked uint256 accumulation at StakingRouter.sol line 732 only under the assumption that the allocation sum stays below 2^256; the bound originates outside the pinned P-TOPUP-1 spans."},
        {"id": "A-HANDWRITTEN-MINFIRST", "accepted": True,
         "risk": "The handwritten MinFirst model lacks established Solidity and EVM equivalence."},
        {"id": "A-VERITY-SCAFFOLD", "accepted": True,
         "risk": "The Verity 4.31 scaffold is non-certified."},
        {"id": "A-DEV-NOT-CERT", "accepted": True,
         "risk": "DEV-431-READY is explicitly accepted as not AUDIT-CERT."},
        {"id": "A-MULTI-NODE-TRANSPORT", "accepted": True,
         "risk": "Multi-node certification transport is accepted as a trust and reproducibility risk; transported results require independent identity and consistency checks."},
        {"id": "A-YUL-INTERFACE", "accepted": True,
         "risk": "Handwritten Yul and direct bytecode require explicit interface composition, not a fabricated source projection."},
        {"id": "A-SHA256-FFI", "accepted": True,
         "risk": "SHA-256 precompile behavior relies on opaque native FFI and host-library behavior; differential vectors do not close this crypto risk."},
        {"id": "A-RUNTIME-PROVENANCE", "accepted": True,
         "risk": "Canonical runtime, codehash, fork configuration, and address provenance are unavailable; Mock-derived evidence is non-production evidence."},
    ],
}
EXPECTED_REPRODUCTION = [
    {"command": "lake build LidoSRv3.Audit.Guarantees.PAlloc1 LidoSRv3.Tests.AllocCapacityRegression",
     "expected": "successful checked-source to independent Audit-model correspondence and negative-mutant build; proportional amount correspondence remains open"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PAlloc2",
     "expected": "successful pinned-source next-target selection correspondence build; proportional amount correspondence remains open"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PDeposit1",
     "expected": "successful pinned-source deposit conservation/rollback correspondence build; EVM-level revert semantics remain open"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PTopup1 LidoSRv3.Tests.TopupHybridMutants",
     "expected": "successful pinned-source conservation plus actual Verity Contract.run transaction simulation, snapshot rollback, declared-call program, and negative-mutant build; linked-external/Yul/EVM/runtime/deployment semantics remain open"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PAccount1 LidoSRv3.Tests.AccountingVectors",
     "expected": "successful full-source-execution-gated MODEL-to-SOURCE-to-VERITY_TX correspondence, positive-fee conditional minting, zero-fee and later-revert regressions, and checked-Uint256 refinement build; later guards/Yul/EVM/runtime/crypto/E2E remain open"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PReserve1 LidoSRv3.Tests.ReserveMutants",
     "expected": "successful pinned-source reserve non-interference, actual Verity-execution simulation, rollback, checked-Uint256, and source-mutant regression build"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PEth1",
     "expected": "successful bounded child-model proofs only; parent P-ETH-1 remains OPEN"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PAddress1",
     "expected": "admission non-discrimination and successful post-state equivariance modulo a bijective caller swap compile; singleton-actor functions remain excluded"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PTopup2",
     "expected": "successful configurable top-up-limit and transition-derived aggregate conservation build; verifier-binding remains blocked on runtime provenance"},
    {"command": "python3 scripts/audit_metadata.py check",
     "expected": "opaque FFI risk remains recorded; no crypto closure"},
    {"command": "lake build LidoSRv3.Audit.Ssz",
     "expected": "successful MODEL-layer structural witness binding only; no SSZ helper or wrapper source correspondence"},
    {"command": "lake build LidoSRv3.Audit.Source.DepositDataRootCorrespondence LidoSRv3.Tests.SszRegression",
     "expected": "successful raw-signature deposit-data-root control-flow and structural-binding regressions only; SHA-256/precompile remains STRETCH_OPAQUE_FFI and source/EVM/crypto/E2E correspondence remains open"},
    {"command": "lake build LidoSRv3.Audit.Verity.SszAbstractDigest",
     "expected": "successful typed-program compilation and exact seven-call pure-Lean digest composition; no Verity execution simulation or SHA-256 functional proof"},
    {"command": "lake build LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel",
     "expected": "successful typed-program compilation and exact source-then-target 96-byte single-CALL layout; no amount, SHA-256, loop, rollback, Yul, or EVM claim"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound LidoSRv3.Tests.PAlloc1EugeneBoundVectors",
     "expected": "successful checked Eugene operator-bond bound and cap-sensitive vectors over canonical SRLib and MinFirst models; EVM equivalence remains open"},
    {"command": "lake build LidoSRv3.Audit.Verity.AddressYulInterface LidoSRv3.Tests.AddressYulInterface", "expected": "successful typed-Yul-builtin compilation against the exact EVMYulLean pin and mutant-sensitive vector set; mutant-vector failure proof and abstract address-rename relation reuse only; no EVM theorem"},
    {"command": "lake build LidoSRv3.Audit.Verity.DepositRollback LidoSRv3.Audit.Verity.Tests.DepositRollback", "expected": "successful OPEN prefix-scaffold compilation plus a kernel-checked counterexample showing that a later reverting CallProgram call retains an earlier successful world mutation; whole-batch transaction rollback and the full source path remain OPEN"},
    {"command": "lake build LidoSRv3.Audit.Verity.ConsolidationFee", "expected": "successful source-shaped FunctionSpec scaffold build; dynamic ABI, call/event trace, balance rollback, and source/tx adequacy remain OPEN"},
    {"command": "lake build LidoSRv3.Audit.Verity.SszTxSimulation LidoSRv3.Audit.Verity.Tests.SszTxSimulation", "expected": "successful typed DepositData execution simulation, exact seven-call SHA-256 composition, root-mutant rejection, and snapshot rollback proofs"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PEth1",
     "expected": "successful bounded protocol rebalance/redemption return-confinement proof; parent ETH-flow guarantee remains open"},
    {"command": "lake build LidoSRv3.Audit.Guarantees.PEth1",
     "expected": "successful configurable consolidation-request fee-target proof; canonical deployed address and parent ETH-flow guarantee remain open"},
]
EXPECTED_ASSUMPTION_LINKS = [
    ["A-SOURCE-SHAPED"],
    ["A-HANDWRITTEN-MINFIRST"],
    ["A-ABSTRACT-TX", "A-SOURCE-SHAPED"],
    ["A-SOURCE-SHAPED", "A-TOPUP-NOWRAP", "A-VERITY-SCAFFOLD"],
    ["A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD"],
    ["A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD"],
    [],
    ["A-ABSTRACT-TX"],
    ["A-RUNTIME-PROVENANCE"],
    ["A-SHA256-FFI"],
    ["A-RUNTIME-PROVENANCE", "A-SHA256-FFI", "A-MULTI-NODE-TRANSPORT"],
    ["A-RUNTIME-PROVENANCE", "A-SHA256-FFI", "A-MULTI-NODE-TRANSPORT"],
    ["A-RUNTIME-PROVENANCE", "A-SHA256-FFI", "A-MULTI-NODE-TRANSPORT"],
    ["A-VERITY-SCAFFOLD", "A-RUNTIME-PROVENANCE"],
    ["A-SOURCE-SHAPED", "A-HANDWRITTEN-MINFIRST"],
    ["A-YUL-INTERFACE"],
    ["A-VERITY-SCAFFOLD", "A-RUNTIME-PROVENANCE"],
    ["A-VERITY-SCAFFOLD", "A-RUNTIME-PROVENANCE"],
    ["A-VERITY-SCAFFOLD", "A-SHA256-FFI", "A-RUNTIME-PROVENANCE"],
    [],
    [],
]
EXPECTED_NEXT_GATES = [
    "Refine proportional allocation amounts and EVM "
    "correspondence for SRLib._getModulesAllocationAndCapacity.",
    "Refine proportional allocation amounts, checked-Uint256 execution, and EVM "
    "correspondence for MinFirstAllocationStrategy.allocateToBestCandidate.",
    "Refine success/revert and rollback against pinned executable EVM semantics.",
    "Refine the declared linked-external calls and generated program through Yul/EVM/runtime-bytecode semantics and independently verified deployment provenance.",
    "Refine the checked Verity transaction model against executable Yul/EVM semantics and independently verified deployment provenance.",
    "Optionally refine the proved Verity transaction through generated Yul, EVM/runtime-bytecode, and deployed storage/call semantics.",
    "Compose all inventoried ETH-bearing call sites and refine the complete flow against pinned Solidity, deployment provenance, and executable EVM semantics.",
    "Prove source correspondence for the mapped permissionless transfer, request, claim, and redemption entrypoints, preserving caller-indexed balances, allowances, ownership, request state, pause state, and external-call behavior under renaming.",
    "Obtain independent canonical runtime, codehash, fork, and address provenance.",
    "Replace or independently validate the opaque native SHA-256 FFI trust boundary.",
    "Refine the mapped GIndex.concat, SSZ.verifyProof, and wrapper call sites to pinned-source correspondence before closing the umbrella SSZ source plane.",
    "Refine the excluded GIndex.concat, SSZ.verifyProof, and wrapper call sites to pinned-source correspondence; SHA-256/precompile semantics and canonical production runtime provenance remain required before any Yul/EVM/crypto/E2E composition.",
    "Promote the abstract digest layer only after Verity execution simulation connects the typed statement program to precompile denotation; SHA-256 functional correctness and production runtime provenance remain assumptions.",
    "Refine the typed 96-byte single-call program against generated Yul/EVM semantics and independently verified production runtime provenance.",
    "Refine the composed checked SRLib/MinFirst operator-bound evidence against executable EVM semantics.",
    "Independent Yul/EVM interface proof beyond this harness; runtime/production provenance and full EVM equivalence remain open.",
    "Add a FunctionSpec/call/memory execution bridge and transaction-entry frame whose terminal revert restores all earlier successful call effects, then add faithful Solidity allocation extraction and the complete dynamic multi-contract suffix; see LidoSRv3/Audit/Verity/DepositRollbackBlocker.md.",
    "Close the FunctionSpec-to-CallProgram/DenoteMemory/event-trace gaps listed in audit/P-CONSOLIDATION-1-VERITY-GAPS.md, then add transaction-frame rollback and source refinement.",
    "Certify the pending SSZ transaction-plane evidence, then refine generated Yul/EVM semantics and independently verified production runtime provenance without closing the SHA-256 assumption.",
    "Refine only the protocol-controlled rebalance/redemption return interface against pinned Solidity and executable EVM semantics.",
    "Refine the configured immutable target against pinned Solidity, then establish the canonical EIP-7251 address through independent deployment provenance and executable EVM semantics.",
]
EXPECTED_EXCLUSIONS = {
    "schema": "lido-srv3-exclusions-v1",
    "exclusions": [
        {"id": "BLS", "scope": "BLS signature validity and related cryptographic correctness"},
        {"id": "FULL-REPORT-PIPELINE-REFINEMENT",
         "scope": "Full report-pipeline source, transaction, and EVM refinement"},
        {"id": "STVAULT-INTERNALS",
         "scope": "stVault internal state, accounting, and lifecycle semantics"},
        {"id": "VALUE-BASED-EXIT-BOUND",
         "scope": "Value-based exit and consolidation bounds"},
        {"id": "BROAD-REGISTRY-LIFECYCLE",
         "scope": "Broad registry, governance, module lifecycle, and role-management behavior"},
    ],
}
PLANES = {"model", "algorithm", "source", "tx", "yul", "evm", "crypto"}
EXPECTED_STATUSES = [
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "LEAN_CHECKED", "tx": "OPEN",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "NOT_APPLICABLE", "algorithm": "LEAN_CHECKED", "source": "LEAN_CHECKED", "tx": "NOT_APPLICABLE",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "LEAN_CHECKED", "tx": "OPEN",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "LEAN_CHECKED", "tx": "LEAN_CHECKED",
     "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "LEAN_CHECKED", "tx": "LEAN_CHECKED",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "LEAN_CHECKED", "tx": "LEAN_CHECKED",
     "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "OPEN", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "OPEN",
     "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "OPEN",
     "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "BLOCKED", "tx": "BLOCKED",
     "yul": "OPEN", "evm": "BLOCKED", "crypto": "NOT_APPLICABLE"},
    {"model": "OPEN", "algorithm": "NOT_APPLICABLE", "source": "NOT_APPLICABLE", "tx": "OPEN",
     "yul": "OPEN", "evm": "OPEN", "crypto": "STRETCH_OPAQUE_FFI"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "BLOCKED",
     "yul": "OPEN", "evm": "BLOCKED", "crypto": "STRETCH_OPAQUE_FFI"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "BLOCKED",
     "yul": "OPEN", "evm": "BLOCKED", "crypto": "STRETCH_OPAQUE_FFI"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "OPEN",
     "yul": "OPEN", "evm": "BLOCKED", "crypto": "STRETCH_OPAQUE_FFI"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "OPEN",
     "yul": "OPEN", "evm": "BLOCKED", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "LEAN_CHECKED", "source": "OPEN", "tx": "NOT_APPLICABLE",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "NOT_APPLICABLE", "algorithm": "NOT_APPLICABLE", "source": "NOT_APPLICABLE", "tx": "OPEN", "yul": "LEAN_CHECKED", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "OPEN", "source": "OPEN", "tx": "OPEN", "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "OPEN", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "OPEN", "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "PENDING", "yul": "OPEN", "evm": "BLOCKED", "crypto": "STRETCH_OPAQUE_FFI"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "OPEN",
     "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE", "source": "OPEN", "tx": "OPEN",
     "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
]
EXPECTED_THEOREM_PLANES = [
    ["model", "source"],
    ["algorithm", "source"],
    ["model", "source"],
    ["model", "source", "tx"],
    ["model", "source", "tx"],
    ["model", "source", "tx"],
    [],
    ["model", "tx"],
    ["model"],
    [],
    ["model"],
    ["model"],
    ["model", "tx"],
    ["model", "tx"],
    ["model", "algorithm"],
    ["yul"],
    ["model"],
    [],
    ["model", "tx"],
    ["model"],
    ["model"],
]
EXPECTED_THEOREMS = [
    "LidoSRv3.Audit.Guarantees.PAlloc1.source_capacities_match_canonical",
    "LidoSRv3.Audit.Guarantees.PAlloc2.source_selects_same_next_target",
    "LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back",
    "LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source",
    "LidoSRv3.Audit.Guarantees.PAccount1.source_to_verityTx",
    "LidoSRv3.Audit.Guarantees.PReserve1.verity_tx_simulates_reserve_spec",
    None,
    "LidoSRv3.Audit.Guarantees.PAddress1.admission_and_post_state_equivariance",
    "LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_block_cap",
    None,
    "LidoSRv3.Audit.Ssz.structural_witness_binding_sound",
    "LidoSRv3.Audit.Source.DepositDataRootCorrespondence.source_pinned_config_discharges_deposit_data_root",
    "LidoSRv3.Audit.Verity.SszAbstractDigest.abstract_digest_refinement",
    "LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.abstract_flow_refinement",
    "LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound.operator_reward_share_le_configured_bond",
    "LidoSRv3.Audit.Verity.AddressYulInterface.mutant_sensitive_harness",
    "LidoSRv3.Audit.Verity.DepositRollback.allocation_extraction_matches_source_derived_prefix",
    None,
    "LidoSRv3.Audit.Verity.SszTxSimulation.ssz_tx_simulation_correct",
    "LidoSRv3.Audit.Guarantees.PEth1.eth_flow_confined",
    "LidoSRv3.Audit.Guarantees.PEth1.consolidation_fee_path_confined",
]
STATUS_VALUES = {
    "ABSTRACT_LEAN_CHECKED",
    "BLOCKED",
    "DEV-431-READY",
    "LEAN_CHECKED",
    "NOT_APPLICABLE",
    "OPEN",
    "PENDING",
    "REGRESSION",
    "STRETCH_OPAQUE_FFI",
}
THEOREM_BACKED_STATUSES = {"ABSTRACT_LEAN_CHECKED", "LEAN_CHECKED", "REGRESSION"}
SOURCE_CLOSURE_STATUSES = THEOREM_BACKED_STATUSES | {"AUDIT-CERT"}
CAMPAIGN_BASE = {
    "repository": "https://github.com/lfglabs-dev/lido-srv3-proof-closure.git",
    "ref": "campaign/lido-minimal-11",
    "commit": "4d7d152551fffed0d43e9b5c73bed6eef4532f05",
}
CANONICAL_LIDO_REPOSITORY = "https://github.com/lidofinance/core.git"
CANONICAL_LIDO_COMMIT = "af095e48bbc1c3841c2c9936219c8461af01056b"
CANONICAL_VERITY_REPOSITORY = "https://github.com/lfglabs-dev/verity.git"
CANONICAL_VERITY_COMMIT = "c41757164e9e8230536d7af29d81a2961b30e482"
CANONICAL_VERITY_INPUT_REV = "c41757164e9e8230536d7af29d81a2961b30e482"
CANONICAL_EVMYULLEAN_REPOSITORY = "https://github.com/lfglabs-dev/EVMYulLean.git"
CANONICAL_EVMYULLEAN_COMMIT = "f7e4ee0dc8f8d5265ce822a937ab5be771f182e9"
CANONICAL_MATHLIB_REPOSITORY = "https://github.com/leanprover-community/mathlib4.git"
CANONICAL_MATHLIB_COMMIT = "fabf563a7c95a166b8d7b6efca11c8b4dc9d911f"
CANONICAL_MATHLIB_INPUT_REV = "v4.31.0"
CANONICAL_LEAN_TOOLCHAIN = "leanprover/lean4:v4.31.0"
EXPECTED_MANIFEST_SCHEMA = "srv3-audit-manifest-v1"
EXPECTED_REGISTRY_SCHEMA = "lido-srv3-minimal-11-guarantees-v3"
EXPECTED_SOURCE_MAP_SCHEMA = "lido-srv3-minimal-11-source-map-v2"
EXPECTED_LOCK_SCHEMA = "lido-srv3-artifacts-lock-v1"
REQUIRED_UNAVAILABLE = {
    name: {"status": "MISSING", "blocked": True, "value": None}
    for name in (
        "canonical_eip7251_runtime",
        "canonical_eip7251_codehash",
        "canonical_eip7251_fork",
        "canonical_eip7251_address",
        "sha256_ffi_implementation_identity",
    )
}
EXPECTED_MANIFEST_LAYERS = {
    "legacy": {
        "modules": ["LidoSRv3.Legacy.Model", "LidoSRv3.Legacy.SpecProofs"],
        "trust": "pure-model regression evidence",
    },
    "audit": {
        "modules": [
            "LidoSRv3.Audit.Arithmetic",
            "LidoSRv3.Audit.Trace",
            "LidoSRv3.Audit.Allocation",
            "LidoSRv3.Audit.Strategy",
            "LidoSRv3.Audit.StrategyProofs",
            "LidoSRv3.Audit.Source.MinFirstCorrespondence",
            "LidoSRv3.Audit.Model.AllocCapacity",
            "LidoSRv3.Audit.Source.AllocCapacityCorrespondence",
            "LidoSRv3.Audit.Regression.AllocCapacityLegacy",
            "LidoSRv3.Audit.Source.DepositCorrespondence",
            "LidoSRv3.Audit.Source.TopupCorrespondence",
            "LidoSRv3.Audit.Verity.TopupHybrid",
            "LidoSRv3.Audit.Source.AccountingCorrespondence",
            "LidoSRv3.Audit.Source.DepositDataRootCorrespondence",
            "LidoSRv3.Audit.Verity.SszAbstractDigest",
            "LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel",
            "LidoSRv3.Audit.Source.ReserveCorrespondence",
            "LidoSRv3.Tests.MinFirstVectors",
            "LidoSRv3.Tests.AllocCapacityRegression",
            "LidoSRv3.Audit.Ssz",
            "LidoSRv3.Tests.SszRegression",
            "LidoSRv3.Tests.DepositVectors",
            "LidoSRv3.Tests.TopupVectors",
            "LidoSRv3.Tests.TopupHybridMutants",
            "LidoSRv3.Tests.ReserveMutants",
            "LidoSRv3.Tests.AccountingVectors",
            "LidoSRv3.Audit.AddressEquivariance",
            "LidoSRv3.Tests.AddressEquivariance",
            "LidoSRv3.Audit.Common.Units",
            "LidoSRv3.Audit.Common.Result",
            "LidoSRv3.Audit.Common.Trace",
            "LidoSRv3.Audit.Common.Atomicity",
            "LidoSRv3.Audit.Common.Bounded",
            "LidoSRv3.Audit.Verity.AddressYulInterface",
            "LidoSRv3.Tests.AddressYulInterface",
        ],
        "trust": (
            "Lean-proved predicates over source-shaped audit data; "
            "P-ALLOC-1 allocation-capacity, P-ALLOC-2 next-target, "
            "P-DEPOSIT-1 deposit conservation/rollback, "
            "P-TOPUP-1 top-up conservation plus hybrid Verity transaction rollback, and "
            "P-ACCOUNT-1 full-success-gated and positive-fee-conditional "
            "MODEL-to-SOURCE-to-VERITY_TX checked-Uint256 refinement is "
            "checked against pinned Solidity, and P-RESERVE-1 reserve non-interference plus "
            "executable Verity transaction simulation is checked against pinned Solidity, "
            "while later guards remain an "
            "explicit interface premise; "
            "P-SSZ-1 deposit-data-root control-flow is MODEL-plane structural "
            "evidence over source-shaped inputs, and its SOURCE-plane "
            "correspondence remains OPEN in audit/guarantees.yaml"
        ),
    },
}
EXPECTED_PROOF_BASELINE = "31e563b5aa47f649ae5cce5ab80aaddd2e45dec2"
EXPECTED_MANIFEST_THEOREMS = [
    {"name": "Quantity.checkedDiv_zero", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "Quantity.saturatingSub_zero_of_le", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "revert_restores_state_value_and_logs", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "revert_may_retain_attempts", "status": "lean_checked", "axioms": []},
    {"name": "valid_result_preserves_router_order", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "Guarantees.PAlloc1.active_capacity_bounded", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "Guarantees.PAlloc1.source_capacities_match_canonical", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "Guarantees.PAlloc1.router_order_preserved", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PAlloc1.checked_uint256_execution_refines_math", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "Guarantees.PAlloc2.selects_least_open_bucket", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PAlloc2.source_selects_same_next_target", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "Guarantees.PAccount1.source_report_before_reward", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PAccount1.source_to_verityTx", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PAddress1.admission_and_post_state_equivariance",
     "status": "lean_checked", "axioms": []},
    {"name": "Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back",
     "status": "lean_checked", "axioms": ["propext"]},
    {"name": "Guarantees.PDeposit1.source_router_balance_unchanged",
     "status": "lean_checked", "axioms": ["propext"]},
    {"name": "Guarantees.PDeposit1.source_reverting_branch_moves_no_ether",
     "status": "lean_checked", "axioms": ["propext"]},
    {"name": "Guarantees.PDeposit1.source_nonconserving_deployment_reverts",
     "status": "lean_checked", "axioms": ["propext"]},
    {"name": "Guarantees.PTopup1.source_topup_conserves_and_rolls_back",
     "status": "lean_checked", "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PTopup1.source_router_balance_unchanged",
     "status": "lean_checked", "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PTopup1.source_reverting_branch_moves_no_ether",
     "status": "lean_checked", "axioms": ["propext"]},
    {"name": "Guarantees.PTopup1.source_balance_guards_discharged",
     "status": "lean_checked", "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PTopup1.source_unchecked_accumulation_faithful",
     "status": "lean_checked", "axioms": ["propext"]},
    {"name": "Guarantees.PTopup1.source_pinned_config_discharges_pubkey_guard",
     "status": "lean_checked", "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PTopup1.verity_tx_simulates_source",
     "status": "lean_checked", "axioms": ["propext", "Classical.choice", "Quot.sound"]},
    {"name": "Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve",
     "status": "lean_checked", "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PReserve1.verity_tx_simulates_reserve_spec",
     "status": "lean_checked", "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PReserve1.verity_tx_preserves_withdrawal_reserve",
     "status": "lean_checked", "axioms": ["propext", "Quot.sound"]},
    {"name": "Guarantees.PSsz1.structural_witness_binding_sound", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "Source.DepositDataRootCorrespondence.source_pinned_config_discharges_deposit_data_root",
     "status": "lean_checked", "axioms": ["propext", "Quot.sound"]},
    {"name": "MinFirst.candidate_mem", "status": "lean_checked", "axioms": ["propext"]},
    {"name": "MinFirst.candidate_open", "status": "lean_checked", "axioms": ["propext"]},
    {"name": "MinFirst.candidate_none_no_open", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "MinFirst.candidate_minimal", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "MinFirst.candidate_router_tie", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "MinFirst.incrementSelected_moduleId", "status": "lean_checked", "axioms": []},
    {"name": "MinFirst.incrementSelected_active", "status": "lean_checked", "axioms": []},
    {"name": "MinFirst.incrementSelected_monotone", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "MinFirst.incrementSelected_eq_of_ne", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "MinFirst.step_preserves_length", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "MinFirst.step_preserves_module_order", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "MinFirst.loop_preserves_length", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "MinFirst.loop_preserves_module_order", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "MinFirst.allocate_preserves_length", "status": "lean_checked",
     "axioms": ["propext"]},
    {"name": "MinFirst.allocate_preserves_module_order", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "MinFirst.run_spent_le", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {"name": "MinFirst.totalAllocated_le_requested", "status": "lean_checked",
     "axioms": ["propext", "Quot.sound"]},
    {
        "name": "Common.BoundedAmount.checkedAdd_sound",
        "status": "lean_checked",
        "axioms": [],
    },
    {
        "name": "Common.revert_rolls_back_state_and_committed_effects",
        "status": "lean_checked",
        "axioms": ["propext"],
    },
    {
        "name": "Common.success_exposes_exact_committed_effects",
        "status": "lean_checked",
        "axioms": ["propext"],
    },
]
EXPECTED_PROOF_POLICY = {
    "project_axioms": 0,
    "sorry": 0,
    "admit": 0,
    "unsafe_proof_escapes": 0,
    "report_entrypoint": "LidoSRv3.Audit.Trust",
}
EXPECTED_SOURCE_POLICY = (
    "Source spans remain unmapped unless independently verified from pinned source; "
    "names or legacy anchors are insufficient."
)
EXPECTED_SOURCE_SCOPE = {
    "public_guarantee_count": 11,
    "transaction_atomicity": "INTERNAL_ONLY",
    "assurance_layers": [
        "MODEL", "ALG", "TX", "REL", "TRACE", "SRC", "YUL", "EVM", "CRYPTO", "E2E"
    ],
    "metadata_is_proof_progress": False,
}
EXPECTED_ACCEPTED_RISKS = {
    "baseline": "DEV-431-READY_NOT_AUDIT-CERT",
    "two_node_certification": "UNAVAILABLE_OR_PARTIAL_NON_BLOCKING",
    "sha256_ffi": "OPAQUE",
    "production_runtime_codehash_fork_address_provenance": "INCOMPLETE",
}
EXPECTED_SSZ_CLAIM = {
    "level": "STRUCTURAL_ONLY",
    "includes": [
        "structures", "generalized_indices", "pivot_and_branch_traversal",
        "wrapper_binding", "operation_binding",
    ],
    "excludes": [
        "FULL_SSZ", "SHA256_CRYPTOGRAPHIC_CORRECTNESS",
        "DEPLOYED_PRECOMPILE_EQUIVALENCE",
        "RUNTIME_CODEHASH_FORK_ADDRESS_PROVENANCE", "EIP_7251_PROVENANCE",
    ],
}
VERIFIED_SOURCE_ANCHORS = {
    "P-DEREF-1": {
        ("contracts/0.8.25/sr/SRStorage.sol", "ROUTER_STORAGE_POSITION, module address access, and membership", 12, 78),
        ("contracts/0.8.25/sr/SRUtils.sol", "_requireModuleIdExists membership guard", 45, 47),
        ("contracts/0.8.25/sr/SRTypes.sol", "ModuleStateConfig moduleAddress declaration", 117, 136),
        ("contracts/0.8.25/sr/SRLib.sol", "_migrateStorage registry writers", 51, 155),
        ("contracts/0.8.25/sr/SRLib.sol", "_addModule registry writer", 183, 232),
    },
    "P-ALLOC-1": {
        ("contracts/0.8.25/sr/StakingRouter.sol", "getDepositAllocations", 929, 936),
        ("contracts/0.8.25/sr/SRLib.sol", "_getDepositAllocations", 391, 431),
        ("contracts/0.8.25/sr/SRLib.sol", "_getModulesAllocationAndCapacity", 493, 559),
        ("contracts/0.8.25/sr/SRLib.sol", "_getStakingModuleSummary", 372, 379),
        ("contracts/0.8.25/sr/SRStorage.sol", "getModuleState", 30, 32),
        ("contracts/0.8.25/sr/SRStorage.sol", "getIStakingModule helpers", 34, 47),
        ("contracts/0.8.25/sr/SRStorage.sol", "getModulesCount", 54, 56),
        ("contracts/0.8.25/sr/SRStorage.sol", "getModuleIdAt", 62, 64),
        ("contracts/common/lib/WithdrawalCredentials.sol", "isType2(uint256)", 47, 49),
        ("contracts/0.8.25/sr/SRUtils.sol", "TOTAL_BASIS_POINTS", 17, 17),
        ("contracts/common/interfaces/IStakingModule.sol", "getStakingModuleSummary", 71, 81),
        ("contracts/common/interfaces/IStakingModuleV2.sol", "getTotalModuleStake", 28, 29),
        ("package.json", "@openzeppelin/contracts-v5.2 dependency pin", 143, 143),
    },
    "P-ALLOC-2": {
        ("contracts/common/lib/MinFirstAllocationStrategy.sol", "allocateToBestCandidate candidate search", 76, 86),
    },
    "P-DEPOSIT-1": {
        ("contracts/0.8.25/sr/StakingRouter.sol", "deposit", 942, 997),
        ("contracts/0.4.24/Lido.sol", "withdrawDepositableEther", 869, 886),
        ("contracts/0.4.24/Lido.sol", "_spendDepositableEther", 839, 859),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "makeBeaconChainDeposits32ETH", 36, 64),
    },
    "P-TOPUP-1": {
        ("contracts/0.8.25/sr/StakingRouter.sol", "topUp", 679, 759),
        ("contracts/0.8.25/sr/StakingRouter.sol", "_validateTopUpInputs", 761, 782),
        ("contracts/0.8.25/sr/StakingRouter.sol", "_checkAppAuth", 1177, 1179),
        ("contracts/0.8.25/sr/StakingRouter.sol", "_getTopUpGateway", 1169, 1171),
        ("contracts/0.8.25/sr/StakingRouter.sol", "_getModuleState", 1099, 1107),
        ("contracts/0.8.25/sr/SRUtils.sol", "_requireWCType2", 41, 43),
        ("contracts/0.8.25/sr/SRUtils.sol", "_requireModuleIdExists", 45, 47),
        ("contracts/0.8.25/sr/StakingRouter.sol", "PUBKEY_LENGTH", 57, 57),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "PUBLIC_KEY_LENGTH", 21, 21),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "MIN_DEPOSIT", 28, 28),
        ("contracts/0.4.24/Lido.sol", "withdrawDepositableEther", 869, 886),
        ("contracts/0.4.24/Lido.sol", "_spendDepositableEther", 839, 859),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "makeBeaconChainTopUp", 66, 108),
    },
    "P-ACCOUNT-1": {
        ("contracts/0.8.9/oracle/AccountingOracle.sol", "submitReportData", 360, 366),
        ("contracts/0.8.9/oracle/AccountingOracle.sol", "_handleConsensusReportData", 477, 559),
        ("contracts/0.8.9/oracle/AccountingOracle.sol", "_processStakingRouterValidatorBalancesByModule", 609, 619),
        ("contracts/0.8.25/sr/StakingRouter.sol", "reportValidatorBalancesByStakingModule", 285, 290),
        ("contracts/0.8.25/sr/SRLib.sol", "_validateReportValidatorBalancesByStakingModule", 853, 870),
        ("contracts/0.8.25/sr/SRLib.sol", "_reportValidatorBalancesByStakingModule", 872, 892),
        ("contracts/0.8.25/sr/SRUtils.sol", "_ensureAmountGwei", 75, 83),
        ("contracts/0.8.25/sr/SRUtils.sol", "MAX_VALUE_GWEI", 23, 23),
        ("contracts/0.8.9/Accounting.sol", "handleOracleReport", 135, 144),
        ("contracts/0.8.9/Accounting.sol", "_calculateProtocolFees", 263, 303),
        ("contracts/0.8.9/Accounting.sol", "_applyOracleReportContext", 359, 428),
        ("contracts/0.8.25/sr/StakingRouter.sol", "getStakingRewardsDistribution", 802, 874),
        ("contracts/0.8.25/sr/StakingRouter.sol", "reportRewardsMinted", 263, 271),
        ("contracts/0.8.25/sr/SRLib.sol", "_reportRewardsMinted", 616, 639),
    },
    "P-RESERVE-1": {
        ("contracts/0.4.24/Lido.sol", "_getBufferedEtherAllocation", 605, 616),
        ("contracts/0.4.24/Lido.sol", "getDepositableEther", 823, 825),
        ("contracts/0.4.24/Lido.sol", "_getDepositableEther", 831, 833),
        ("contracts/0.4.24/Lido.sol", "_spendDepositableEther", 839, 859),
        ("contracts/0.4.24/Lido.sol", "withdrawDepositableEther", 869, 886),
    },
    "P-ETH-1a": {
        ("contracts/0.8.25/consolidation/ConsolidationGateway.sol", "preservesEthBalance", 118, 122),
        ("contracts/0.8.25/consolidation/ConsolidationGateway.sol", "_refundFee", 295, 307),
        ("contracts/0.8.9/WithdrawalVault.sol", "preservesEthBalance", 81, 85),
    },
    "P-ETH-1b": {
        ("contracts/0.8.25/consolidation/ConsolidationBus.sol", "executeConsolidation", 383, 406),
    },
    "P-ADDRESS-1": {
        ("contracts/0.8.9/WithdrawalQueueERC721.sol", "transferFrom", 218, 220),
        ("contracts/0.8.9/WithdrawalQueue.sol", "requestWithdrawals", 125, 142),
        ("contracts/0.8.9/WithdrawalQueue.sol", "claimWithdrawalsTo", 244, 264),
        ("contracts/0.6.12/WstETH.sol", "unwrap", 69, 80),
    },
    "P-TOPUP-2": {
        ("contracts/0.8.25/TopUpGateway.sol", "topUp", 160, 237),
        ("contracts/0.8.25/TopUpGateway.sol", "_evaluateTopUpLimit", 396, 415),
        ("contracts/0.8.25/CLValidatorVerifier.sol", "_verifyValidator", 44, 57),
    },
    "P-CONSOLIDATION-1": {
        ("contracts/0.8.25/consolidation/ConsolidationBus.sol", "addConsolidationRequests", 325, 370),
        ("contracts/0.8.25/consolidation/ConsolidationBus.sol", "executeConsolidation", 383, 406),
        ("contracts/0.8.25/consolidation/ConsolidationGateway.sol", "addConsolidationRequests", 185, 223),
        ("contracts/0.8.25/consolidation/ConsolidationGateway.sol", "_prepareConsolidationPairs", 348, 365),
        ("contracts/0.8.9/WithdrawalVault.sol", "constructor", 63, 78),
        ("contracts/0.8.9/WithdrawalVault.sol", "preservesEthBalance", 81, 85),
        ("contracts/0.8.9/WithdrawalVault.sol", "addConsolidationRequests", 199, 208),
        ("contracts/0.8.9/WithdrawalVaultEIP7685.sol", "constructor", 34, 40),
        ("contracts/0.8.9/WithdrawalVaultEIP7685.sol", "_addConsolidationRequests", 56, 73),
        ("contracts/0.8.9/WithdrawalVaultEIP7685.sol", "_callAddConsolidationRequest", 113, 121),
    },
    "P-SSZ-1": {
        ("contracts/common/lib/BeaconTypes.sol", "Validator declaration", 8, 17),
        ("contracts/common/interfaces/ValidatorWitness.sol", "ValidatorWitness declaration", 13, 24),
        ("contracts/common/lib/GIndex.sol", "concat", 72, 89),
        ("contracts/common/lib/SSZ.sol", "hashTreeRoot(BeaconTypes.Validator)", 89, 175),
        ("contracts/common/lib/SSZ.sol", "verifyProof", 179, 248),
        ("contracts/0.8.25/CLValidatorVerifier.sol", "_verifyValidator", 44, 57),
        ("contracts/0.8.25/vaults/predeposit_guarantee/CLProofVerifier.sol", "_validatePubKeyWCProof", 150, 175),
        ("contracts/0.8.25/consolidation/ConsolidationGateway.sol", "addConsolidationRequests", 185, 223),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "_computeDepositDataRootWithAmount", 120, 135),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "_computeDepositDataRootWithAmount raw signature overload", 110, 118),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "_computeSignatureRoot", 137, 146),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "_toLittleEndian64", 148, 153),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "PUBLIC_KEY_LENGTH", 21, 21),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "SIGNATURE_LENGTH", 22, 22),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "SHA256_DIGEST_LENGTH and zero padding literals", 126, 133),
        ("contracts/0.8.25/lib/BeaconChainDepositor.sol", "DEPOSIT_DATA_LENGTH ABI input shape", 120, 135),
    },
}
UNMAPPED_SOURCE_BLOCKERS = {}
VIEWS = ("ROADMAP.md", "STATUS.md", "REPRODUCE.md")


def load(name):
    return json.loads((AUDIT / name).read_text(encoding="utf-8"))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def manifest_package(manifest, name):
    matches = [package for package in manifest["packages"] if package["name"] == name]
    require(len(matches) == 1, f"lake-manifest.json: expected exactly one {name} package")
    return matches[0]


def validate_source_targets(source_map):
    pinned_sha = source_map["pinned_source"].rsplit("@", 1)[-1]
    require(bool(re.fullmatch(r"[0-9a-f]{40}", pinned_sha)),
            "source-map pinned_source must end in a 40-character lowercase source SHA")
    targets = source_map.get("targets")
    require(isinstance(targets, list), "source-map targets must be a list")
    require([target.get("id") for target in targets] == SOURCE_TARGET_IDS,
            "source-map targets must contain the exact ordered minimal-11 IDs")
    for target in targets:
        target_id = target.get("id", "<missing>")
        status = target.get("status")
        spans = target.get("spans")
        require(status in {"MAPPED", "UNMAPPED"},
                f"{target_id}: source-map status must be MAPPED or UNMAPPED")
        require(isinstance(spans, list), f"{target_id}: source-map spans must be a list")
        if target_id in UNMAPPED_SOURCE_BLOCKERS:
            require(status == "UNMAPPED",
                    f"{target_id}: source target without verified correspondence "
                    "must remain UNMAPPED")
            require(set(target) == {"id", "status", "spans", "blocker"},
                    f"{target_id}: UNMAPPED source row requires exact "
                    "id/status/spans/blocker fields")
            require(not spans, f"{target_id}: UNMAPPED source row must not claim spans")
            require(target.get("blocker") == UNMAPPED_SOURCE_BLOCKERS[target_id],
                    f"{target_id}: UNMAPPED source blocker differs from canonical record")
            continue
        require(status == "MAPPED",
                f"{target_id}: verified source target must remain MAPPED")
        require(set(target) == {"id", "status", "spans"},
                f"{target_id}: MAPPED source row requires exact id/status/spans fields")
        require(spans, f"{target_id}: MAPPED source row requires verified spans")
        require(not target.get("blocker"),
                f"{target_id}: MAPPED source row must not retain a blocker")
        for span in spans:
            require(set(span) == {
                "repository", "source_sha", "path", "function",
                "start_line", "end_line", "permalink",
            }, f"{target_id}: source span requires exact repository/SHA/path/"
               "function/lines/permalink")
            require(span["repository"] == "lidofinance/core",
                    f"{target_id}: source span repository must be lidofinance/core")
            require(span["source_sha"] == pinned_sha,
                    f"{target_id}: source span SHA must equal the pinned source SHA")
            require(isinstance(span["path"], str) and span["path"].strip()
                    and not span["path"].startswith("/") and ".." not in Path(span["path"]).parts,
                    f"{target_id}: source span requires an exact repository-relative path")
            require(isinstance(span["function"], str) and span["function"].strip(),
                    f"{target_id}: source span requires an exact function")
            require(type(span["start_line"]) is int and type(span["end_line"]) is int
                    and 1 <= span["start_line"] <= span["end_line"],
                    f"{target_id}: source span requires a valid exact line range")
            expected_permalink = (
                f"https://github.com/lidofinance/core/blob/{pinned_sha}/"
                f"{span['path']}#L{span['start_line']}-L{span['end_line']}"
            )
            require(span["permalink"] == expected_permalink,
                    f"{target_id}: source span requires an immutable exact permalink")
            anchor = (
                span["path"], span["function"], span["start_line"], span["end_line"]
            )
            require(anchor in VERIFIED_SOURCE_ANCHORS.get(target_id, set()),
                    f"{target_id}: source span is not a verified semantic anchor")
        actual_anchors = {
            (span["path"], span["function"], span["start_line"], span["end_line"])
            for span in spans
        }
        require(len(actual_anchors) == len(spans),
                f"{target_id}: duplicate source spans are forbidden")
        require(actual_anchors == VERIFIED_SOURCE_ANCHORS[target_id],
                f"{target_id}: source spans differ from verified semantic anchors")


def validate_lock(lock, source_map):
    manifest = json.loads((ROOT / "lake-manifest.json").read_text(encoding="utf-8"))
    audit_manifest = json.loads(
        (ROOT / "verity/targets/audit-manifest.json").read_text(encoding="utf-8")
    )
    toolchain = (ROOT / "lean-toolchain").read_text(encoding="utf-8").strip()
    lakefile = (ROOT / "lakefile.lean").read_text(encoding="utf-8")
    lido_source_repository, lido_commit = source_map["pinned_source"].split("@", 1)
    require(lido_source_repository == "lidofinance/core",
            "source-map pinned_source must use the canonical lidofinance/core repository")
    require(lido_commit == CANONICAL_LIDO_COMMIT,
            "source-map Lido pin differs from the canonical source commit")
    require(toolchain == CANONICAL_LEAN_TOOLCHAIN,
            "lean-toolchain must use the canonical Lean 4.31 toolchain")
    verity = manifest_package(manifest, "verity")
    require(
        verity["url"] == CANONICAL_VERITY_REPOSITORY
        and verity["rev"] == CANONICAL_VERITY_COMMIT
        and verity["inputRev"] == CANONICAL_VERITY_INPUT_REV,
        "Lake Verity pin differs from the canonical dependency pin",
    )
    mathlib = manifest_package(manifest, "mathlib")
    require(
        mathlib["url"] == CANONICAL_MATHLIB_REPOSITORY
        and mathlib["rev"] == CANONICAL_MATHLIB_COMMIT
        and mathlib["inputRev"] == CANONICAL_MATHLIB_INPUT_REV,
        "Lake mathlib pin differs from the canonical migration receipt",
    )

    expected_pins = {
        "lido_core": {
            "repository": CANONICAL_LIDO_REPOSITORY,
            "commit": lido_commit,
        },
        "verity": {
            "repository": CANONICAL_VERITY_REPOSITORY,
            "commit": CANONICAL_VERITY_COMMIT,
        },
        "evmyullean": {
            "repository": CANONICAL_EVMYULLEAN_REPOSITORY,
            "commit": CANONICAL_EVMYULLEAN_COMMIT,
        },
        "lean": {"toolchain": toolchain},
        "mathlib": {
            "repository": CANONICAL_MATHLIB_REPOSITORY,
            "commit": CANONICAL_MATHLIB_COMMIT,
        },
    }
    require(lock.get("pins") == expected_pins,
            "artifacts.lock.json pins differ from source-map/toolchain/Lake authorities")
    require(lock.get("modules") == [
        "LidoSRv3.Audit.Verity.AddressYulInterface",
        "LidoSRv3.Tests.AddressYulInterface",
    ], "artifacts.lock.json Yul interface module inventory differs")
    require(audit_manifest["source_revisions"]["lido"] == lido_commit,
            "source-map Lido pin differs from verity target audit manifest")
    require(audit_manifest["source_revisions"]["verity"] == CANONICAL_VERITY_COMMIT,
            "Lake Verity pin differs from verity target audit manifest")
    lean_revision = toolchain.rsplit(":", 1)[-1]
    require(audit_manifest["source_revisions"]["lean"] == lean_revision,
            "Lean toolchain pin differs from verity target audit manifest")
    evmyul = manifest_package(manifest, "evmyul")
    require(
        evmyul["url"] == CANONICAL_EVMYULLEAN_REPOSITORY
        and evmyul["rev"] == CANONICAL_EVMYULLEAN_COMMIT
        and evmyul["inputRev"] == CANONICAL_EVMYULLEAN_COMMIT,
        "Lake EVMYulLean pin differs from the canonical dependency pin",
    )
    require(audit_manifest.get("schema") == EXPECTED_MANIFEST_SCHEMA,
            "audit manifest schema differs from the canonical version")
    require(audit_manifest.get("proof_policy") == EXPECTED_PROOF_POLICY,
            "audit manifest proof policy differs from the canonical zero-escape policy")
    manifest_layers = json.loads(json.dumps(audit_manifest.get("layers")))
    if (isinstance(manifest_layers, dict)
            and isinstance(manifest_layers.get("audit"), dict)
            and isinstance(manifest_layers["audit"].get("modules"), list)):
        manifest_layers["audit"]["modules"].extend(lock["modules"])
    require(manifest_layers == EXPECTED_MANIFEST_LAYERS,
            "audit manifest layers differ from the canonical trust records")
    require(audit_manifest.get("proof_baseline") == EXPECTED_PROOF_BASELINE,
            "audit manifest proof baseline differs from the canonical commit")
    require(audit_manifest.get("theorems") == EXPECTED_MANIFEST_THEOREMS,
            "audit manifest theorem ledger differs from the canonical records")
    require(
        f'"{CANONICAL_VERITY_REPOSITORY}"@"{CANONICAL_VERITY_COMMIT}"' in lakefile,
        "lakefile.lean Verity pin differs from the canonical dependency pin",
    )

    require(lock.get("campaign_base") == CAMPAIGN_BASE,
            "artifacts.lock.json campaign_base differs from canonical campaign authority")


def validate():
    registry = load("guarantees.yaml")
    assumptions = load("assumptions.yaml")
    exclusions = load("exclusions.yaml")
    lock = load("artifacts.lock.json")
    source_map = load("source-map.yaml")
    require(registry.get("schema") == EXPECTED_REGISTRY_SCHEMA,
            "guarantee registry schema differs from the canonical version")
    require(source_map.get("schema") == EXPECTED_SOURCE_MAP_SCHEMA,
            "source-map schema differs from the canonical version")
    require(lock.get("schema") == EXPECTED_LOCK_SCHEMA,
            "artifacts lock schema differs from the canonical version")
    require(registry.get("authority") == EXPECTED_AUTHORITY,
            "guarantee registry authority differs from the canonical declaration")
    rows = registry["guarantees"]
    ids = [row["id"] for row in rows]
    require(ids == EXPECTED_IDS + SUBORDINATE_IDS,
            "guarantees must contain the exact ordered canonical IDs plus subordinate evidence")
    require([row["catalogue_wording"] for row in rows[:-1]] == EXPECTED_WORDING,
            "catalogue wording changed")
    require(exclusions == EXPECTED_EXCLUSIONS,
            "exclusions differ from the canonical scope boundary set")
    require(assumptions == EXPECTED_ASSUMPTIONS,
            "assumptions differ from the canonical accepted risk records")
    require(source_map.get("policy") == EXPECTED_SOURCE_POLICY,
            "source-map policy differs from the canonical assurance rule")
    require(source_map.get("scope") == EXPECTED_SOURCE_SCOPE,
            "source-map scope/layer boundary differs from the canonical record")
    require(source_map.get("accepted_risks") == EXPECTED_ACCEPTED_RISKS,
            "source-map accepted risks differ from the canonical record")
    require(source_map.get("ssz_claim") == EXPECTED_SSZ_CLAIM,
            "source-map SSZ claim exceeds the structural-only boundary")
    require(set(source_map) == {
        "schema", "pinned_source", "policy", "scope",
        "accepted_risks", "ssz_claim", "targets",
    }, "source-map requires exact schema/pinned_source/policy/scope/"
       "accepted_risks/ssz_claim/targets fields")
    validate_source_targets(source_map)
    assumption_ids = {row["id"] for row in assumptions["assumptions"]}
    source_targets = {row["id"]: row for row in source_map["targets"]}
    for row, expected_statuses, expected_theorem_planes, expected_theorem, expected_reproduction, expected_links, expected_gate in zip(
        rows[:-1], EXPECTED_STATUSES, EXPECTED_THEOREM_PLANES, EXPECTED_THEOREMS,
        EXPECTED_REPRODUCTION, EXPECTED_ASSUMPTION_LINKS, EXPECTED_NEXT_GATES
    ):
        if row["id"] == "P-ETH-1a":
            require(row.get("parent_id") == "P-ETH-1",
                    "P-ETH-1a must remain subordinate to P-ETH-1")
            require(row.get("source_plane_scope") ==
                    "protocol-controlled stVault rebalance/redemption interface only",
                    "P-ETH-1a: scope must exclude raw owner-controlled withdrawals")
            require(row.get("note") ==
                    "Scope assumption: owner-controlled StakingVault.withdraw permits any nonzero recipient and is excluded from this child property.",
                    "P-ETH-1a: owner-withdrawal scope assumption differs")
        elif row["id"] == "P-ETH-1b":
            require(row.get("parent_id") == "P-ETH-1",
                    "P-ETH-1b must remain subordinate to P-ETH-1")
            require(row.get("source_plane_scope") ==
                    "configured immutable consolidation-request fee target only",
                    "P-ETH-1b: configurable-target scope differs")
            require(row.get("note") ==
                    "Deployment-provenance assumption: Solidity uses nonzero immutable CONSOLIDATION_REQUEST, but proving its deployed value is 0x00...007251 is outside this source theorem.",
                    "P-ETH-1b: deployment-provenance assumption differs")
        elif row["id"] == "P-SSZ-1.deposit-data-root":
            require(row.get("parent_id") == "P-SSZ-1",
                    "P-SSZ-1.deposit-data-root must remain subordinate to P-SSZ-1")
            require(row.get("source_plane_scope") == "deposit-data-root only",
                    "P-SSZ-1.deposit-data-root: source plane scope must remain deposit-data-root only")
        elif row["id"] == "P-SSZ-1.abstract-digest":
            require(row.get("parent_id") == "P-SSZ-1",
                    "P-SSZ-1.abstract-digest must remain subordinate to P-SSZ-1")
            require(row.get("source_plane_scope") == "abstract SHA-256 digest only",
                    "P-SSZ-1.abstract-digest: scope must remain abstract SHA-256 digest only")
            require(row.get("campaign_head_sha") ==
                    "52b6db9d5f59bbfbd2d6d5932295f8e850e8079a",
                    "P-SSZ-1.abstract-digest: campaign head differs")
            require(row.get("verity_sha") ==
                    "1348e19634b52ffd8f2ceaf5c1a21dc7b7a076d6",
                    "P-SSZ-1.abstract-digest: Verity gate differs")
            require(row.get("validated_tree_sha") ==
                    "94ec852336ea2148785943d48c96a7d0248ea99f",
                    "P-SSZ-1.abstract-digest: parent validated tree differs")
            require(row.get("no_new_forbidden_lean_tokens") is True,
                    "P-SSZ-1.abstract-digest: forbidden-token assertion is missing")
            require(row.get("files") == [
                "LidoSRv3.lean",
                "LidoSRv3/Audit/Verity/SszAbstractDigest.lean",
                "audit/artifacts.lock.json",
                "audit/guarantees.yaml",
                "audit/validation-receipt.txt",
                "lake-manifest.json",
                "lakefile.lean",
                "scripts/audit_metadata.py",
                "verity/targets/audit-manifest.json",
            ], "P-SSZ-1.abstract-digest: evidence file list differs")
        elif row["id"] == "P-ALLOC-1.eugene-bound":
            require(row.get("parent_id") == "P-ALLOC-1",
                    "P-ALLOC-1.eugene-bound must remain subordinate to P-ALLOC-1")
            require(row.get("source_plane_scope") == "operator bond bound only",
                    "P-ALLOC-1.eugene-bound: source plane scope must remain operator bond bound only")
        elif row["id"] == "P-CONSOLIDATION-1.abstract-flow-model":
            require(row.get("parent_id") == "P-CONSOLIDATION-1",
                    "P-CONSOLIDATION-1.abstract-flow-model must remain subordinate to P-CONSOLIDATION-1")
            require(row.get("source_plane_scope") == "abstract 96-byte consolidation flow only",
                    "P-CONSOLIDATION-1.abstract-flow-model: scope differs")
            require(row.get("campaign_head_sha") ==
                    "1ae66a0477eb0769b0cc4c0c21d39f62d572d4b9",
                    "P-CONSOLIDATION-1.abstract-flow-model: campaign head differs")
            require(row.get("verity_loop_simulation_sha") ==
                    "066f1bf5772ebc6cc218902b8f05ad70cbf36866",
                    "P-CONSOLIDATION-1.abstract-flow-model: LoopSimulation gate differs")
            require(row.get("verity_sha256_sha") ==
                    "1348e19634b52ffd8f2ceaf5c1a21dc7b7a076d6",
                    "P-CONSOLIDATION-1.abstract-flow-model: DenoteSha256 gate differs")
            require(row.get("verity_external_calls_sha") ==
                    "7dba916d99b14ed30613ad9579eee9b49b876bc6",
                    "P-CONSOLIDATION-1.abstract-flow-model: DenoteExternalCalls gate differs")
            require(row.get("validated_tree_sha") ==
                    "512b637208ee6ae89a51f0a4e2708b71588bdcb1",
                    "P-CONSOLIDATION-1.abstract-flow-model: parent validated tree differs")
            require(row.get("no_new_forbidden_lean_tokens") is True,
                    "P-CONSOLIDATION-1.abstract-flow-model: forbidden-token assertion is missing")
            require(row.get("files") == [
                "LidoSRv3.lean",
                "LidoSRv3/Audit/Verity/ConsolidationAbstractFlowModel.lean",
                "audit/artifacts.lock.json",
                "audit/guarantees.yaml",
                "audit/validation-receipt.txt",
                "lake-manifest.json",
                "lakefile.lean",
                "scripts/audit_metadata.py",
                "scripts/check_validation_receipt.py",
                "verity/targets/audit-manifest.json",
            ], "P-CONSOLIDATION-1.abstract-flow-model: evidence file list differs")
        elif row["id"] == "P-ADDRESS-1.yul-interface-harness":
            require(row.get("parent_id") == "P-ADDRESS-1",
                    "P-ADDRESS-1.yul-interface-harness must remain subordinate to P-ADDRESS-1")
            require(row.get("source_plane_scope") == "typed Yul builtin interface harness only",
                    "P-ADDRESS-1.yul-interface-harness: scope differs")
        elif row["id"] == "P-DEPOSIT-1.verity-tx-rollback.tx":
            require(row.get("parent_id") == "P-DEPOSIT-1",
                    "P-DEPOSIT-1.verity-tx-rollback.tx must remain subordinate to P-DEPOSIT-1")
            require(row.get("source_plane_scope") == "source-shaped deposit prefix scaffold (OPEN); allocation and multi-contract suffix explicitly OPEN",
                    "P-DEPOSIT-1.verity-tx-rollback.tx: scope differs")
            require(row.get("no_new_forbidden_lean_tokens") is True,
                    "P-DEPOSIT-1.verity-tx-rollback.tx: forbidden-token assertion is missing")
        elif row["id"] == "P-CONSOLIDATION-1.fee-refinement.tx":
            require(row.get("parent_id") == "P-CONSOLIDATION-1",
                    "P-CONSOLIDATION-1.fee-refinement.tx must remain subordinate to P-CONSOLIDATION-1")
            require(row.get("source_plane_scope") == "WithdrawalVault consolidation request model only; gateway grouping, quota, proof validation, and refund are excluded",
                    "P-CONSOLIDATION-1.fee-refinement.tx: scope differs")
        elif row["id"] == "P-SSZ-1.tx-execution-simulation":
            require(row.get("parent_id") == "P-SSZ-1",
                    "P-SSZ-1.tx-execution-simulation must remain subordinate to P-SSZ-1")
            require(row.get("source_plane_scope") == "SSZ transaction execution simulation only",
                    "P-SSZ-1.tx-execution-simulation: scope differs")
            require(row.get("no_new_forbidden_lean_tokens") is True,
                    "P-SSZ-1.tx-execution-simulation: forbidden-token assertion is missing")
        else:
            require("parent_id" not in row,
                    f"{row['id']}: only declared subordinate evidence may have a parent")
            require("source_plane_scope" not in row,
                    f"{row['id']}: source plane scope marker is reserved for subordinate evidence")
        require(set(row["statuses"]) == PLANES, f"{row['id']}: assurance planes differ")
        theorem_planes = row.get("theorem_planes")
        require(theorem_planes == expected_theorem_planes,
                f"{row['id']}: theorem planes differ from canonical evidence")
        require(row.get("theorem") == expected_theorem,
                f"{row['id']}: theorem differs from canonical evidence")
        require(len(theorem_planes) == len(set(theorem_planes))
                and set(theorem_planes) <= PLANES,
                f"{row['id']}: invalid theorem evidence plane")
        require(bool(row["theorem"]) == bool(theorem_planes),
                f"{row['id']}: theorem and theorem planes must be declared together")
        for plane, status in row["statuses"].items():
            require(status in STATUS_VALUES,
                    f"{row['id']}: invalid {plane} assurance status: {status}")
            require(status not in THEOREM_BACKED_STATUSES or plane in theorem_planes,
                    f"{row['id']}: {plane} status {status} requires theorem evidence "
                    "for that plane")
        require(row["statuses"] == expected_statuses,
                f"{row['id']}: assurance statuses differ from canonical claims")
        source_status = row["statuses"]["source"]
        if row["id"] in {"P-SSZ-1.deposit-data-root", "P-SSZ-1.abstract-digest",
                          "P-SSZ-1.tx-execution-simulation"}:
            mapping = source_targets["P-SSZ-1"]
        elif row["id"] == "P-ALLOC-1.eugene-bound":
            mapping = source_targets["P-ALLOC-1"]
        elif row["id"] == "P-CONSOLIDATION-1.abstract-flow-model":
            mapping = source_targets["P-CONSOLIDATION-1"]
        elif row["id"] == "P-ADDRESS-1.yul-interface-harness":
            mapping = source_targets["P-ADDRESS-1"]
        elif row["id"] == "P-DEPOSIT-1.verity-tx-rollback.tx":
            mapping = source_targets["P-DEPOSIT-1"]
        elif row["id"] == "P-CONSOLIDATION-1.fee-refinement.tx":
            mapping = source_targets["P-CONSOLIDATION-1"]
        elif row["id"] == "P-ETH-1":
            # The open parent spans both child source-map targets; no source
            # closure is inferred from either mapping.
            mapping = source_targets["P-ETH-1a"]
        else:
            mapping = source_targets[row["id"]]
        require(
            source_status not in SOURCE_CLOSURE_STATUSES
            or (mapping["status"] == "MAPPED" and mapping["spans"]),
            f"{row['id']}: source assurance closure requires verified source spans",
        )
        require(row["next_gate"] == expected_gate,
                f"{row['id']}: next gate differs from canonical roadmap")
        require(row["reproduction"] == expected_reproduction,
                f"{row['id']}: reproduction record differs from canonical evidence")
        require(row["assumptions"] == expected_links,
                f"{row['id']}: assumption links differ from canonical risks")
        require(set(row["assumptions"]) <= assumption_ids,
                f"{row['id']}: canonical assumption link is unknown")
    pderef = rows[-1]
    require(pderef["id"] == "P-DEREF-1", "supplemental dereference row is missing")
    require(pderef.get("catalogue_wording") ==
            "Supplemental bounded MODEL/SOURCE/VERITY_TX evidence: reachable initialization, migration, and add-module states derive nonzero registered addresses; an executable Verity mapping transaction returns and records that same modeled address. Solidity storage hashing/layout, generated Yul, EVM execution, and runtime provenance remain OPEN.",
            "P-DEREF-1: catalogue wording differs from canonical bounded claim")
    require(pderef.get("source_plane_scope") ==
            "registry address binding only; migration old-layout contents are explicit inputs",
            "P-DEREF-1: source plane scope differs from canonical boundary")
    require(pderef.get("theorem") == "LidoSRv3.Audit.SolidityDereference.verity_observe_refines_source",
            "P-DEREF-1: theorem differs from canonical evidence")
    require(pderef.get("theorem_planes") == ["model", "source", "tx"],
            "P-DEREF-1: theorem planes differ from canonical evidence")
    require(pderef.get("statuses") == {
        "model": "LEAN_CHECKED", "algorithm": "NOT_APPLICABLE",
        "source": "LEAN_CHECKED", "tx": "LEAN_CHECKED", "yul": "OPEN",
        "evm": "OPEN", "crypto": "NOT_APPLICABLE",
    }, "P-DEREF-1: assurance statuses differ from canonical claims")
    require(pderef.get("assumptions") == [
        "A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD", "A-YUL-INTERFACE",
        "A-RUNTIME-PROVENANCE",
    ], "P-DEREF-1: assumption links differ from canonical risks")
    require(pderef.get("next_gate") ==
            "Establish independently checked ROUTER_STORAGE_POSITION, Solidity mapping layout, compiler-emitted SLOAD execution, and deployed runtime provenance before claiming Yul/EVM closure.",
            "P-DEREF-1: next gate differs from canonical roadmap")
    require(pderef.get("reproduction") == {
        "command": "lake build LidoSRv3.Audit.Guarantees.PDeref1 LidoSRv3.Tests.DereferenceMutants",
        "expected": "reachable nonzero derivation, source-to-executable-Verity mapping refinement, and guard/address-writer mutants compile; Yul/EVM provenance remains OPEN",
    }, "P-DEREF-1: reproduction record differs from canonical evidence")
    validate_lock(lock, source_map)
    require(lock.get("unavailable") == REQUIRED_UNAVAILABLE,
            "unavailable provenance must contain the exact canonical blocker set")
    return rows[:len(EXPECTED_IDS)]


def rendered(rows):
    header = (
        "<!-- GENERATED by scripts/audit_metadata.py; edit structured metadata, "
        "not this view. Lean is theorem authority. -->\n\n"
    )
    roadmap = header + "# ROADMAP\n\n" + "\n".join(
        f"- `{row['id']}`: {row['next_gate']}" for row in rows
    ) + "\n"
    status_lines = [
        "# STATUS",
        "",
        "| ID | Model | ALG | Source | TX | Yul | EVM | Crypto |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in rows:
        s = row["statuses"]
        status_lines.append(
            f"| `{row['id']}` | {s['model']} | {s['algorithm']} | {s['source']} | {s['tx']} | "
            f"{s['yul']} | {s['evm']} | {s['crypto']} |"
        )
    status = header + "\n".join(status_lines) + "\n"
    reproduce = header + "# REPRODUCE\n\n" + "\n".join(
        f"- `{row['id']}`: `{row['reproduction']['command']}` — "
        f"{row['reproduction']['expected']}"
        for row in rows
    ) + "\n"
    return {"ROADMAP.md": roadmap, "STATUS.md": status, "REPRODUCE.md": reproduce}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("generate", "check"))
    parser.add_argument("--expect-canonical-count", type=int)
    args = parser.parse_args()
    rows = validate()
    if args.expect_canonical_count is not None:
        require(len(rows) == args.expect_canonical_count,
                f"canonical guarantee count is {len(rows)}, expected {args.expect_canonical_count}")
    views = rendered(rows)
    if args.command == "generate":
        for name, content in views.items():
            (AUDIT / name).write_text(content, encoding="utf-8")
        print("generated audit/ROADMAP.md audit/STATUS.md audit/REPRODUCE.md")
    else:
        for name, content in views.items():
            require((AUDIT / name).read_text(encoding="utf-8") == content,
                    f"{name} is stale; run scripts/audit_metadata.py generate")
        print(f"audit metadata ok: {len(EXPECTED_IDS)} canonical guarantees + "
              f"{len(SUBORDINATE_IDS)} subordinate evidence rows")


if __name__ == "__main__":
    main()
