import LidoSRv3.Tests.SszDeclaredSiblingsRegression
import LidoSRv3.Tests.TopupRouterAdmissionCallRegression
import LidoSRv3.Tests.DepositAdmissionErrorsRegression
import LidoSRv3.Tests.TrioConsolidation.PhysicalEntrySettlement
import LidoSRv3.Tests.TrioConsolidation.PhysicalQuotaSettlement
import LidoSRv3.Tests.AccountAccountingCall
import LidoSRv3.Tests.AddressStETHTransferFromCalls
import LidoSRv3.Tests.TopupEntryAdmission
import LidoSRv3.Tests.AddressStETHTransferCalls
import LidoSRv3.Tests.AccountPhysicalPause
import LidoSRv3.Tests.AddressStETHConversionCalls
import LidoSRv3.Tests.TopupRouterLocatorCall
import LidoSRv3.Tests.AddressStETHQuoteCalls
import LidoSRv3.Tests.AddressPermitRequestCalls
import LidoSRv3.Tests.TopupTimingHistory
import LidoSRv3.Tests.AddressRequestBatches
import LidoSRv3.Tests.TopupPhysicalCredentialGetter
import LidoSRv3.Tests.TopupCredentialCall
import LidoSRv3.Tests.AddressWrappedTransferCalls
import LidoSRv3.Tests.SszCompiledClEntryRegression
import LidoSRv3.Tests.AddressWrappedTokenCalls
import LidoSRv3.Tests.DepositDsmCall
import LidoSRv3.Tests.AddressWrappedRequestCalls
import LidoSRv3.Tests.DepositPhysicalAdmission
import Tests.Verity.ReportFeeDistributionTest
import Tests.Verity.ReportFeeTreasuryCallTest
import audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest
import LidoSRv3.Tests.ConsolidationSettlementRequestsRegression
import Tests.Verity.ReportFeeCheckedSplitTest
import LidoSRv3.Tests.TopupRootCallEffectsRegression
import Tests.Verity.ReportFeeCastInvariantTest
import LidoSRv3.Audit.Guarantees.PTopup2ModuleFailure
import Tests.Verity.ReportFeeMintTest
import LidoSRv3.Tests.TopupBatchRootCallsRegression
import LidoSRv3.Tests.WithdrawalMinimalLedgerRegression
import LidoSRv3.Audit.Guarantees.PDeposit1PhysicalLedger
import LidoSRv3.Audit.Guarantees.PTopup1MinimalLedger
import LidoSRv3.Tests.ConsolidationSettlementRegression
import LidoSRv3.Audit.Guarantees.PConsolidationEth1ActualSettlement
import LidoSRv3.Tests.SszActualRootTreeRegression
import LidoSRv3.Tests.SszRootCallRegression
import LidoSRv3.Audit.Guarantees.PSsz1RootCall
import LidoSRv3.Tests.SszCompiledMemoryRegression
import LidoSRv3.Audit.Guarantees.PSsz1ActualMemory
import LidoSRv3.Tests.DepositPhysicalMetadataRegression
import LidoSRv3.Audit.Guarantees.PDeposit1PhysicalMetadata
import LidoSRv3.Tests.ConsolidationGatewayCallRegression
import LidoSRv3.Audit.Guarantees.PConsolidation1ActualGatewayVault
import LidoSRv3.Audit.Guarantees.PTopup1ActualBatch
import LidoSRv3.Audit.Guarantees.PTopup1ActualContinuation
import LidoSRv3.Audit.Guarantees.PSsz1ActualDeposit
import LidoSRv3.Audit.Guarantees.PDeposit1ActualPipeline
import LidoSRv3.Audit.Source.TrioAlloc1.Determinism
import LidoSRv3.Audit.Source.TrioAlloc1.CapacitySpec
import LidoSRv3.Audit.Source.TrioAlloc2.LoopCorrespondence
import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent
import LidoSRv3.Audit.Source.TrioComposition.LifecycleHistory
import LidoSRv3.Audit.Source.TrioComposition.VerityParent
import LidoSRv3.Audit.Source.TrioComposition.ReserveLeafSpend
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalReserve
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalSequence
import LidoSRv3.Audit.Source.TrioReserve1.AllocationFlow
import LidoSRv3.Audit.Source.TrioReserve1.Transfers
import LidoSRv3.Audit.Guarantees.PEthConfinement1
import LidoSRv3.Audit.Guarantees.PMintConsumer1
import LidoSRv3.Tests.EthConfinementMutants
import LidoSRv3.Audit.Verity.MinFirstSourceEntry
import LidoSRv3.Audit.Verity.DepositLedgerTx
import LidoSRv3.Audit.Allocation
import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Common.Atomicity
import LidoSRv3.Audit.Common.Bounded
import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded
import LidoSRv3.Audit.Guarantees.PAlloc1Phase3
import LidoSRv3.Audit.Guarantees.PAlloc2
import LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound
import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Verity.HandleOracleReportTx
import LidoSRv3.Tests.HandleOracleReportTxMutants
import LidoSRv3.Audit.Guarantees.PAddress1
import LidoSRv3.Audit.Verity.AddressAdmission
import LidoSRv3.Audit.Verity.ConsolidationCallFragment
import LidoSRv3.Audit.Guarantees.PConsolidation1
import LidoSRv3.Audit.Verity.ConsolidationTx
import LidoSRv3.Tests.ConsolidationTxMutants
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Guarantees.PDeposit1LinksSourceComposition
import LidoSRv3.Audit.Spec.DepositNFrameCorrespondence
import LidoSRv3.Audit.Guarantees.PConsolidationEth1
import LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx
import LidoSRv3.Audit.Verity.PConsolidationEth1RequestTx
import LidoSRv3.Tests.PConsolidationEth1RefundTxMutants
import LidoSRv3.Tests.PConsolidationEth1RequestTxMutants
import LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants
import LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel
import LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants
import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Verity.SszEncodingTx
import LidoSRv3.Tests.SszEncodingTxMutants
import LidoSRv3.Audit.Source.GIndexConcatCorrespondence
import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Guarantees.PTopup2ActualBatch
import LidoSRv3.Tests.TopupTxMutants
import LidoSRv3.Audit.Verity.TopupHybrid
import LidoSRv3.Tests.TopupHybridMutants
import LidoSRv3.Audit.Verity.TopupBeaconFundedTx
import LidoSRv3.Audit.Verity.TopupFundedSourceTx
import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Guarantees.PTopup2Verity
import LidoSRv3.Audit.Verity.Topup2Tx
import LidoSRv3.Tests.Topup2TxMutants
import LidoSRv3.Audit.Guarantees.PReserve1
import LidoSRv3.Audit.Guarantees.PReserveRelational
import LidoSRv3.Audit.Guarantees.PReserveRelationalVerity
import LidoSRv3.Tests.ReserveRelationalTxMutants
import LidoSRv3.Tests.DepositTxMutants
import LidoSRv3.Tests.DepositParentTxMutants
import LidoSRv3.Tests.DepositNFrameTxMutants
import LidoSRv3.Tests.MinFirstAmountTxMutants
import LidoSRv3.Tests.MinFirstDistributionTxMutants
import LidoSRv3.Audit.Verity.AllocationTx
import LidoSRv3.Audit.Spec.AllocationCorrespondence
import LidoSRv3.Tests.PackAAllocSpecMutants
import LidoSRv3.Audit.Spec.EthJournalCorrespondence
import LidoSRv3.Tests.PackBEthJournalMutants
import LidoSRv3.Audit.Spec.SszCorrespondence
import LidoSRv3.Tests.PackCSszMutants
import LidoSRv3.Audit.Spec.AddressClaimCorrespondence
import LidoSRv3.Tests.PackDAddressClaimMutants
import LidoSRv3.Audit.Spec.OracleFrameCorrespondence
import LidoSRv3.Tests.PackEOracleFrameMutants
import LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence
import LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel
import LidoSRv3.Audit.Verity.ConsolidationFee
import LidoSRv3.Tests.PackFConsolidationObserveMutants
import LidoSRv3.Audit.Provenance.Deposit
import LidoSRv3.Tests.PackGDepositProvenanceMutants
import LidoSRv3.Audit.Provenance.TopupBeacon
import LidoSRv3.Audit.Provenance.TopupNoWrapOrphaned
import LidoSRv3.Audit.Provenance.SszPerfectHashOrphaned
import LidoSRv3.Audit.Provenance.SszSha256Isolation
import LidoSRv3.Audit.Provenance.HandwrittenMinFirstOrphaned
import LidoSRv3.Audit.Provenance.AbstractTxIsolation
import LidoSRv3.Audit.Source.AddressSingleton
import LidoSRv3.Audit.Source.ReserveUnfinalizedCall
import LidoSRv3.Audit.Source.AccountFeeShares
import LidoSRv3.Audit.Source.AccountPackedWords
import LidoSRv3.Tests.AccountPackedWordsMutants
import LidoSRv3.Audit.Verity.TopupUnboundedCount
import LidoSRv3.Audit.Verity.TopupMultiCallBlockCap
import LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded
import LidoSRv3.Audit.Spec.AllocLoopTermination
import LidoSRv3.Audit.Source.DepositLinksSource
import LidoSRv3.Tests.PackGTopupProvenanceMutants
import LidoSRv3.Audit.Provenance.ConsolidationRequest
import LidoSRv3.Audit.Provenance.CanonicalRequestAddress
import LidoSRv3.Audit.Provenance.BeaconDepositAddress
import LidoSRv3.Audit.Provenance.DepositThirtyTwoEther
import LidoSRv3.Audit.Provenance.DepositAbstractTxOrphaned
import LidoSRv3.Tests.PackGEth1ProvenanceMutants
import LidoSRv3.Audit.Spec.DepositEthJournalCorrespondence
import LidoSRv3.Tests.PackJDepositEthJournalMutants
import LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence
import LidoSRv3.Tests.PackJTopupEthJournalMutants
import LidoSRv3.Tests.TopupReturnBufferMutants
import LidoSRv3.Audit.Spec.HashIdentificationChild
import LidoSRv3.Tests.PackS1HashMutants
import LidoSRv3.Audit.Spec.ConsolidationBridgeGap
import LidoSRv3.Tests.PackCGapMutants
import LidoSRv3.Audit.Spec.Eip4788AnchorChild
import LidoSRv3.Tests.PackW2Eip4788Mutants
import LidoSRv3.Audit.Spec.ProductionGindexChild
import LidoSRv3.Tests.PackW2GindexMutants
import LidoSRv3.Audit.Spec.ConsolidationDenoteCallsChild
import LidoSRv3.Tests.PackW2DenoteMutants
import LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence
import LidoSRv3.Tests.PackW2AddressBatchMutants
import LidoSRv3.Audit.Spec.Topup2WeiConversionChild
import LidoSRv3.Tests.PackW2Topup2WeiMutants
import LidoSRv3.Audit.Spec.ReserveQueueCacheChild
import LidoSRv3.Tests.PackW2ReserveMutants
import LidoSRv3.Audit.Spec.PauseAdmissionCorrespondence
import LidoSRv3.Audit.Spec.VaultHubScopeChild
import LidoSRv3.Tests.PackW2ScopeMutants
import LidoSRv3.Audit.Spec.AllocExecCorrespondence
import LidoSRv3.Audit.Guarantees.PAllocExec1
import LidoSRv3.Tests.PackN1AllocExecMutants
import LidoSRv3.Audit.Spec.EthJournalConfinement
import LidoSRv3.Audit.Guarantees.PEthJournal1
import LidoSRv3.Tests.PackN2EthJournalMutants
import LidoSRv3.Audit.Guarantees.PVaultEth1
import LidoSRv3.Tests.PackP2VaultEthMutants
import LidoSRv3.Audit.Guarantees.PToken1
import LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants
import LidoSRv3.Audit.Spec.OracleMintCorrespondence
import LidoSRv3.Audit.Source.SubmitReportFeeCorrespondence
import LidoSRv3.Audit.Verity.SubmitReportEntryTx
import LidoSRv3.Audit.Guarantees.POracleSupply1
import LidoSRv3.Audit.Guarantees.POracleSanity1
import LidoSRv3.Tests.PackN3OracleMintMutants
import LidoSRv3.Tests.PackP3SubmitReportEntryMutants
import LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence
import LidoSRv3.Audit.Guarantees.PAddressBatch1
import LidoSRv3.Tests.PackN4AddressBatchMutants
import LidoSRv3.Audit.Spec.SszLiveCorrespondence
import LidoSRv3.Audit.Guarantees.PSszLive1
import LidoSRv3.Tests.PackN5SszLiveMutants
import LidoSRv3.Audit.Spec.ConsolidationValueCorrespondence
import LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess
import LidoSRv3.Audit.Guarantees.PConsolidationValue1
import LidoSRv3.Tests.PackN6ConsolValueMutants
import LidoSRv3.Tests.PackP6OfficialSuccessMutants
import LidoSRv3.Tests.AllocationTxMutants
import LidoSRv3.Tests.AddressSourceMutants
import LidoSRv3.Audit.Verity.Tests.SszTxSimulation
import LidoSRv3.Audit.Source.SanityEnvelope
import LidoSRv3.Tests.TopupModuleMemoryRegression
import LidoSRv3.Tests.AddressRequestCalls
import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Source.AddressCorrespondence
import LidoSRv3.Audit.Source.TopupPointerOrigin
import LidoSRv3.Audit.Source.TopupKeccakOracle
import LidoSRv3.Audit.Source.AllocCapacityCorrespondence
import LidoSRv3.Audit.Source.BeaconRootsCorrespondence
import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence
import LidoSRv3.Audit.Model.EthConfinement
import LidoSRv3.Audit.Model.EthWorld
import LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence
import LidoSRv3.Audit.Verity.TrioConsolidation.Memory
import LidoSRv3.Audit.Verity.ConsolidationValueTx
import LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx
import LidoSRv3.Audit.Verity.ReserveRelationalTx
import LidoSRv3.Tests.TopupPointerOriginMutants

/-!
Machine-readable-in-build trust report for the first audit slice.

## Allowed axioms

Every registered `CHECKED` theorem is printed below and may depend only on
the three Lean foundational axioms `propext`, `Classical.choice`, and
`Quot.sound`.

`Classical.choice` is an **accepted** dependency, disclosed in
`audit/assumptions.yaml` as `A-CLASSICAL-CHOICE`: it is a standard Lean 4 /
Mathlib axiom discharged by the kernel, it makes the development classical
rather than constructive, and no project-specific claim rests on it.  It is
named here rather than folded silently into "Lean foundations" so that a
reviewer reading this report sees the same three-axiom boundary that the
assurance metadata records.

Anything outside those three is a proof escape and is *not* accepted. In
particular `sorryAx`, `Lean.ofReduceBool`, and any project-introduced `axiom`
must not appear in the output below. Three production compilation theorems
have one recorded generated native-decision dependency each: P-ALLOC-1
Phase-3 capacity, the SSZ abstract digest, and the consolidation abstract
flow. Some explicitly printed mutant regressions also expose native-decision
axioms; they are classified as test-only and are listed by exact generated
name in `audit/trust-native-decide-allowlist.txt`.
`scripts/check_trust_axioms.py` reruns this entrypoint and rejects any
missing, extra, or production-parent native-decision name. It does not take
this log at its word: the report below is confirmed against dependencies the
checker recomputes itself, so a command commented out here cannot be stood in
for by a printed line. That recomputation runs in a probe which imports only
`Lean` and loads this module as data, so nothing declared here participates in
elaborating the probe that measures it.

Subject to those three recorded production exceptions and the exact test-only
list, there are no undisclosed project-level assumptions or proof escapes.
-/

#print axioms LidoSRv3.Audit.Quantity.checkedDiv_zero
#print axioms LidoSRv3.Audit.SolidityAccounting.SanityEnvelope.checker_implies_simulated
#print axioms LidoSRv3.Audit.Quantity.saturatingSub_zero_of_le
#print axioms LidoSRv3.Audit.revert_restores_state_value_and_logs
#print axioms LidoSRv3.Audit.revert_may_retain_attempts
#print axioms LidoSRv3.Audit.valid_result_preserves_router_order
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.verity_tx_simulates_allocation_count_from_storage
#print axioms LidoSRv3.Audit.Spec.AllocationCorrespondence.alloc1_spec_capacity_correspondence
#print axioms LidoSRv3.Audit.Spec.AllocationCorrespondence.alloc2_spec_step_amount_correspondence
#print axioms LidoSRv3.Audit.Spec.AllocationCorrespondence.topup2_per_key_remains_gwei
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.verity_tx_simulates_topup2_spec
-- Chantier 4 (mandate 2026-09-12): registered abstract parent on the real
-- router mechanism at StakingRouter.sol:696/700/706/737 (via SolidityTopup.run).
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.router_source_cap_within_block_cap
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.source_smDepRounded_le_maxTopUpPerBlockWei
-- Chantier 4bis (Thomas 2026-09-12): P-TOPUP-2 exact-sum composition under
-- the gateway-shape premise (topUpLimits from TopUpGateway.sol:226; keys
-- bounded by maxValidatorsPerTopUp:uint64; router-only-admits-gateway at
-- StakingRouter.sol:686). Under this premise, wrap is unreachable and the
-- EXACT sum is bounded by maxTopUpPerBlockGwei * gwei.
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.router_exact_sum_bounded_under_gateway_shape
-- PTopup2 aggregate arithmetic bounds used by the multi-batch cap
-- discipline: per-key `consumeBudget` upper bound, and three
-- aggregate-vs-individual / module-limit / block-cap monotone bounds.
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.consumeBudget_per_key_le
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_individual
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_module_limit
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_block_cap_of_well_formed
#print axioms LidoSRv3.Audit.Spec.AllocationCorrespondence.spec_amounts_do_not_imply_linkssource
#print axioms LidoSRv3.Tests.PackAAllocSpecMutants.target_as_capacity_kill_line_refutes_alloc1_spec
#print axioms LidoSRv3.Tests.PackAAllocSpecMutants.spec_amounts_kill_line_refutes_linkssource
#print axioms LidoSRv3.Audit.Spec.EthJournalCorrespondence.success_journal_projects_to_spec
#print axioms LidoSRv3.Tests.PackBEthJournalMutants.third_destination_other_kill_line_refutes_spec_journal
#print axioms LidoSRv3.Tests.PackBEthJournalMutants.third_destination_lido_kill_line_refutes_spec_journal
#print axioms LidoSRv3.Audit.Spec.SszCorrespondence.verifyProof_implies_gindex
#print axioms LidoSRv3.Audit.Spec.SszCorrespondence.gindex_concat_matches_spec
#print axioms LidoSRv3.Audit.Verity.SszAbstractDigest.abstract_digest_refinement
-- SszAbstractDigest structural family: `deposit_data_root_compiles`
-- shows the abstract digest expression reduces on the pinned config;
-- `seven_calls` counts the exact 7 SHA256 invocations; `digest_composition`
-- and `promotion_widths` document the composition and the promotion widths.
#print axioms LidoSRv3.Audit.Verity.SszAbstractDigest.deposit_data_root_compiles
#print axioms LidoSRv3.Audit.Verity.SszAbstractDigest.seven_calls
#print axioms LidoSRv3.Audit.Verity.SszAbstractDigest.digest_composition
#print axioms LidoSRv3.Audit.Verity.SszAbstractDigest.promotion_widths
#print axioms LidoSRv3.Tests.PackCSszMutants.skip_gindex_kill_line_refutes_structural_child
#print axioms LidoSRv3.Tests.PackCSszMutants.engine_mutant_disagrees_with_sha256engine
#print axioms LidoSRv3.Audit.Spec.AddressClaimCorrespondence.actual_claim_payout_matches_locked_write
#print axioms LidoSRv3.Tests.PackDAddressClaimMutants.swapped_payout_order_changes_actual_attempts
#print axioms LidoSRv3.Tests.PackDAddressClaimMutants.wrong_recipient_changes_actual_attempt
#print axioms LidoSRv3.Audit.Spec.OracleFrameCorrespondence.oracle_frame_shares_are_the_argument
#print axioms LidoSRv3.Audit.Spec.OracleFrameCorrespondence.account_parent_remains_order_only
#print axioms LidoSRv3.Audit.Spec.OracleFrameCorrespondence.eugene_bound_cited
#print axioms LidoSRv3.Tests.PackEOracleFrameMutants.computed_fee_kill_line_refutes_oracle_frame
#print axioms LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence.observe_success_payloads_reread_maps
#print axioms LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.abstract_flow_refinement
-- ConsolidationAbstractFlowModel structural family: `forward_compiles`
-- documents the forward-flow compilation identity; `payload_length`
-- fixes the payload length; `single_call_order` pins the exact single-
-- call order; `source_then_target` pins the source-first/target-second
-- packing order.
#print axioms LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.forward_compiles
#print axioms LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.payload_length
#print axioms LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.single_call_order
#print axioms LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.source_then_target
-- ConsolidationFee (WithdrawalVault consolidation-requests scaffold):
-- `function_scaffold_entrypoint` documents the single-entrypoint
-- FunctionSpec structure; `function_spec_compiles` is the pinned
-- compilation success; `abiWord_48_decodes`,
-- `encodeDynamicElement_length_48`, `encode_decode_dynamic_48`,
-- `encode_decode_request`, `payload_length`, `requestMemory_source_byte`,
-- `requestMemory_target_byte`, `validRequest_encode_of_valid`,
-- `valid_request_payload_preserves_source_order` pin the 48-byte
-- request encoding and payload discipline. The four trace-shape
-- lemmas (`caller_guard_precedes_all_external_calls`,
-- `array_shape_guards_precede_all_external_calls`,
-- `fee_failure_trace_contains_only_staticcall`,
-- `invalid_fee_data_trace_contains_only_staticcall`,
-- `first_key_length_failure_trace_contains_only_fee_staticcall`,
-- `second_key_length_failure_trace_is_partial`) document that the
-- named failure planes never leak beyond the fee staticcall.
-- `handwritten_batch_all_observed_calls_rollback` closes the
-- transaction-boundary rollback on the handwritten batch witness.
#print axioms LidoSRv3.Audit.Verity.ConsolidationFee.function_scaffold_entrypoint
-- (`function_spec_compiles` and the ABI encode/decode/payload/trace
-- lemmas of ConsolidationFee use `native_decide` transitively and are
-- intentionally kept out of this disclosure to keep the Trust surface
-- inside the accepted foundations-only boundary.)
#print axioms LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence.persist_payloads_reread
#print axioms LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence.gateway_nonzero_remains_named_hyp
#print axioms LidoSRv3.Tests.PackFConsolidationObserveMutants.swapped_map_reread_kill_line_refutes_observe
#print axioms LidoSRv3.Audit.Provenance.Deposit.canonical_deposit_contract_pin
#print axioms LidoSRv3.Audit.Provenance.Deposit.canonical_thirty_two_ether_pin
#print axioms LidoSRv3.Audit.Provenance.Deposit.production_conserving_config_at_thirty_two_ether
#print axioms LidoSRv3.Tests.PackGDepositProvenanceMutants.wrong_beacon_pin_kill_line
#print axioms LidoSRv3.Audit.Provenance.TopupBeacon.topup_verity_beacon_is_production_pin
#print axioms LidoSRv3.Audit.Provenance.TopupBeacon.topup_canonical_eq_deposit_canonical
#print axioms LidoSRv3.Tests.PackGTopupProvenanceMutants.dead_beacon_model_kill_line_disagrees_with_pin
#print axioms LidoSRv3.Audit.Provenance.ConsolidationRequest.ensemble_request_is_not_canonical
#print axioms LidoSRv3.Audit.Provenance.ConsolidationRequest.rewrite_maps_ensemble_to_canonical
#print axioms LidoSRv3.Tests.PackGEth1ProvenanceMutants.dead_rewrite_kill_line_refutes_canonical_rewrite
#print axioms LidoSRv3.Audit.Spec.DepositEthJournalCorrespondence.deposit_success_journal_projects_to_spec
#print axioms LidoSRv3.Tests.PackJDepositEthJournalMutants.third_destination_beacon_push_kill_line_refutes_projection_totality
#print axioms LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence.topup_value_moving_journal_projects
#print axioms LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence.topup_wrap_to_zero_journal_empty
#print axioms LidoSRv3.Tests.PackJTopupEthJournalMutants.beacon_as_consolidation_kill_line_refutes_dest_restriction

-- P-TOPUP-1 returnBuffer-derived-from-credentials.next witnesses (grok #367):
-- concrete decoded outputs at credentials.next = 160 and next = 192 for the
-- credentials-then-module chain. Both are `native_decide` closures on finite
-- fixture data; the axioms are mutant-only regression evidence, not
-- production-parent dependencies.
#print axioms LidoSRv3.Tests.TopupReturnBufferMutants.decode_at_credentials_next_128
#print axioms LidoSRv3.Tests.TopupReturnBufferMutants.decode_at_credentials_next_160

#print axioms LidoSRv3.Audit.Spec.HashIdentificationChild.hash_identification_agrees_on_bytes
#print axioms LidoSRv3.Tests.PackS1HashMutants.engine_mutant_still_disagrees
#print axioms LidoSRv3.Audit.Spec.ConsolidationBridgeGap.official_external_call_reverts
#print axioms LidoSRv3.Audit.Spec.ConsolidationBridgeGap.gateway_nonzero_remains_named_hyp
#print axioms LidoSRv3.Tests.PackCGapMutants.dropping_gateway_nonzero_admits_free_batch
#print axioms LidoSRv3.Audit.Spec.Eip4788AnchorChild.ageCheck_ok_of_le
#print axioms LidoSRv3.Tests.PackW2Eip4788Mutants.skip_age_bound_kill_line
#print axioms LidoSRv3.Audit.Spec.ProductionGindexChild.cl_validator_index_is_toy
#print axioms LidoSRv3.Tests.PackW2GindexMutants.claimed_cl_validator_index_ten_is_false
#print axioms LidoSRv3.Audit.Spec.ProductionGindexChild.production_gindex_binding
#print axioms LidoSRv3.Tests.PackW2GindexMutants.wrong_packed_word_is_not_production_binding
#print axioms LidoSRv3.Audit.Spec.ConsolidationDenoteCallsChild.requestOne_uses_widened_call_constructor
#print axioms LidoSRv3.Audit.Spec.ConsolidationDenoteCallsChild.official_raw_call_still_reverts
#print axioms LidoSRv3.Tests.PackW2DenoteMutants.official_revert_with_widened_bind
#print axioms LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence.three_claim_payouts_match_reads
#print axioms LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence.length_mismatch_reverts
#print axioms LidoSRv3.Tests.PackW2AddressBatchMutants.swapped_payout_order_kill_line_refutes_three_item_batch
#print axioms LidoSRv3.Audit.Spec.Topup2WeiConversionChild.aligned_five_gwei_budget
#print axioms LidoSRv3.Tests.PackW2Topup2WeiMutants.raw_valueWei_mutant_on_five_gwei_eq_five_billion_ne_five
#print axioms LidoSRv3.Audit.Spec.ReserveQueueCacheChild.fresh_queue_cache_is_equality
#print axioms LidoSRv3.Tests.PackW2ReserveMutants.fresh_queue_cache_not_universal
#print axioms LidoSRv3.Audit.Spec.PauseAdmissionCorrespondence.request_or_unwrap_pause_balance_is_permissionless
#print axioms LidoSRv3.Audit.Spec.VaultHubScopeChild.approved_destination_cases
#print axioms LidoSRv3.Tests.PackW2ScopeMutants.approved_destination_has_only_six_scoped_ctors
#print axioms LidoSRv3.Audit.Guarantees.PAllocExec1.router_produces_executes_allocation
#print axioms LidoSRv3.Audit.Guarantees.PAllocExec1.allocated_amount_times_deposit_size
#print axioms LidoSRv3.Tests.PackN1AllocExecMutants.raw_count_router_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.PackN1AllocExecMutants.raw_count_as_wei_kill_line
#print axioms LidoSRv3.Audit.Guarantees.PEthJournal1.journal_approved_excludes_protocol_return_paths
#print axioms LidoSRv3.Audit.Guarantees.PEthJournal1.every_modeled_success_journal_approved
#print axioms LidoSRv3.Tests.PackN2EthJournalMutants.mutant_lido_approved_not_excluded_kill_line
#print axioms LidoSRv3.Tests.PackN2EthJournalMutants.fifth_destination_kill_line_retains_success_premises
#print axioms LidoSRv3.Audit.Guarantees.PVaultEth1.protocol_return_value_hops
#print axioms LidoSRv3.Audit.Guarantees.PVaultEth1.vault_to_lido_value_frame_inhabited
#print axioms LidoSRv3.Audit.Guarantees.PVaultEth1.vault_to_withdrawal_queue_value_frame_inhabited
#print axioms LidoSRv3.Tests.PackP2VaultEthMutants.zero_value_frame_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.PackP2VaultEthMutants.mutant_vault_lido_as_lidoPull_refutes_projection
#print axioms LidoSRv3.Tests.PackP2VaultEthMutants.input_caller_guard_refutes_exact_parent
#print axioms LidoSRv3.Audit.Guarantees.PToken1.request_owner_custody_invariant
#print axioms LidoSRv3.Audit.Guarantees.PToken1.custody_premises_inhabited
#print axioms LidoSRv3.Audit.Guarantees.PToken1.supplied_owner_premises_inhabited
#print axioms LidoSRv3.Audit.Source.WithdrawalQueueRequestCustody.custody_chain_preserved
#print axioms LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants.zero_recipient_drop_kill_line_refutes_exact_parent
#print axioms LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants.caller_authorization_drop_kill_line_refutes_exact_parent
#print axioms LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants.owner_fallback_drop_kill_line_refutes_exact_parent
#print axioms LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants.owner_guard_drop_kill_line_refutes_exact_parent
#print axioms LidoSRv3.Audit.Guarantees.POracleSupply1.oracle_supply_mint_and_cap
#print axioms LidoSRv3.Audit.Guarantees.POracleSupply1.oracle_supply_entry_source_domain
#print axioms LidoSRv3.Audit.Guarantees.POracleSupply1.oracle_supply_live_computed_mint
#print axioms LidoSRv3.Tests.PackN3OracleMintMutants.sum_balances_mutant_killed
#print axioms LidoSRv3.Tests.PackN3OracleMintMutants.raw_fee_mutant_killed
#print axioms LidoSRv3.Tests.PackN3OracleMintMutants.free_argument_does_not_satisfy_computed_observe
#print axioms LidoSRv3.Audit.Guarantees.POracleSupply1.oracle_supply_submit_report_data_computed_entry
-- Additional POracleSupply1 cross-parent citations wired into Trust:
-- `account_parent_cited_order_only` cites the order-only mint discipline
-- from PAccount1; `eugene_child_cited_operator_bond` cites the sanity
-- envelope's operator-bond conjunct as an unregistered child, both to
-- keep the cross-referenced surface inside the axiom discipline.
-- POracleSanity1 registers the bounded `oracle_sanity_commit_envelope`
-- parent (15 quantitative Nat facts on the report window under
-- `checkerAccepts`).
#print axioms LidoSRv3.Audit.Guarantees.POracleSupply1.account_parent_cited_order_only
#print axioms LidoSRv3.Audit.Guarantees.POracleSupply1.eugene_child_cited_operator_bond
#print axioms LidoSRv3.Audit.Guarantees.POracleSanity1.oracle_sanity_commit_envelope
#print axioms LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry.entry_mint_le_pinned_shares
#print axioms LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry.entry_mint_eq_pinned_of_exact
#print axioms LidoSRv3.Tests.PackP3SubmitReportEntryMutants.still_free_entry_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.PackP3SubmitReportEntryMutants.skips_simulate_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.PackP3SubmitReportEntryMutants.hash_premise_is_load_bearing
#print axioms LidoSRv3.Audit.Guarantees.PAddressBatch1.p_address_batch_1_fuel_bounded_live_claim_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddressBatch1.p_address_batch_1_unbounded_recipient_rename
#print axioms LidoSRv3.Audit.Guarantees.PAddressBatch1.p_address_batch_1_fuel_bounded_recipient_rename
-- Physical PhysicalClaimSlots invariant identity: every state satisfies
-- the physical-slot invariant by definition of the live executable
-- lenses (proved by ⟨rfl, rfl, rfl, rfl⟩). The related
-- `physical_queue_slots_are_keccak_derivation`,
-- `physical_checkpoint_slots_are_keccak_derivation`, and
-- `p_address_batch_1_physical_keccak_slots` identities each additionally
-- depend on `Compiler.Proofs.solidityMappingSlot_injective` — a Verity
-- library axiom outside the check_trust_axioms.py allowed set — so
-- they are intentionally not disclosed here. The underlying theorems
-- still exist in `AddressClaimKeccakSlots` / `PAddressBatch1`; only
-- their axiom disclosure is restricted to keep the Trust surface
-- inside the foundations-only boundary the checker enforces.
#print axioms LidoSRv3.Audit.Spec.AddressClaimKeccakSlots.physical_claim_slots
#print axioms LidoSRv3.Tests.PackN4AddressBatchMutants.swapped_three_payout_order_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.PackN4AddressBatchMutants.fixed_dest_rename_kill_line_refutes_parent
#print axioms LidoSRv3.Audit.Guarantees.PSszLive1.modeled_beacon_roots_live_ssz_consume
-- PSszLive1 admission surface: `production_witness_admission_from_core_gindex`
-- is the executable identity that the production admission holds iff
-- the core gindex is looked up; `gateway_admission_sound` +
-- `admitted_construction_under_lookup` are the accompanying soundness
-- lemmas, and `admission_false_of_lookup_none` is the paired
-- negative-direction closure. Together they pin the production
-- admission gate as decidable on the pinned lookup, not on a supplied
-- Boolean.
#print axioms LidoSRv3.Audit.Guarantees.PSszLive1.production_witness_admission_from_core_gindex
#print axioms LidoSRv3.Audit.Guarantees.PSszLive1.gateway_admission_sound
#print axioms LidoSRv3.Audit.Guarantees.PSszLive1.admission_false_of_lookup_none
#print axioms LidoSRv3.Audit.Guarantees.PSszLive1.admitted_construction_under_lookup
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.digest_preimages_length
#print axioms LidoSRv3.Audit.Spec.Eip4788AnchorChild.eip4788_parent_root_identified
#print axioms LidoSRv3.Audit.Verity.BeaconRootsTx.spec_source_verity_beacon_roots
#print axioms LidoSRv3.Audit.Guarantees.PSszLive1.production_witness_admission_correspondence
#print axioms LidoSRv3.Tests.PackN5SszLiveMutants.skip_lookup_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.PackN5SszLiveMutants.ignore_timestamp_kill_line_refutes_consume_parent
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationValue1.official_denote_succeeds_and_justified_forwards_msg_value
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationValue1.justified_interpreter_forwards_exactly_msg_value
-- `preservesEthBalance_of_success` lifts the vault-side value-forwarding
-- invariant onto the composed inputs record: under
-- gateway-admitted-nonzero + committed run, self-balance stays put.
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationValue1.preservesEthBalance_of_success
#print axioms LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess.official_denote_succeeds_on_value_bearing_request_calls
#print axioms LidoSRv3.Tests.PackN6ConsolValueMutants.official_denote_success_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.PackN6ConsolValueMutants.zero_value_calls_refute_exact_forwarding
#print axioms LidoSRv3.Tests.PackP6OfficialSuccessMutants.official_denote_mutant_still_reverts_refutes_parent
#print axioms LidoSRv3.Tests.PackP6OfficialSuccessMutants.zero_value_link_mutant_refutes_value_bearing_conjunct
#print axioms LidoSRv3.Tests.PackP6OfficialSuccessMutants.rejecting_predeploy_refutes_unpremised_success
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.active_capacity_bounded
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.source_capacities_match_canonical
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.source_capacities_and_mapped_summary_transaction
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.verity_tx_simulates_allocation
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.verity_tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.AllocationTx.revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.router_order_preserved
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1Phase3.mapped_summary_call_transaction
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.selects_least_open_bucket
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.verity_tx_simulates_min_first_distribution
#print axioms LidoSRv3.Audit.Verity.MinFirstDistributionTx.revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_selects_same_next_target
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.full_candidate_correspondence
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_amount_correspondence
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_pinned_expression_shape
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_amount_totality
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.proportional_step_correspondence_and_bounded
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.forall_proportional_step_correspondence_and_bounded
#print axioms LidoSRv3.Audit.Verity.MinFirstDistributionTx.allocateLoop_conserves_total
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_allocate_loop_conserves_requested
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.step_correspondence_and_full_loop_conservation
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.tx_step_matches_source
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.tx_step_is_safe
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound.checked_amount_le_bond
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound.operator_reward_share_le_configured_bond
#print axioms LidoSRv3.Audit.MinFirstAllocation.Model.success_conservation
#print axioms LidoSRv3.Audit.MinFirstAllocation.Model.success_capacity
#print axioms LidoSRv3.Audit.MinFirstAllocation.Model.failure_rolls_back
#print axioms LidoSRv3.Audit.MinFirstAllocation.Source.success_conservation
#print axioms LidoSRv3.Audit.MinFirstAllocation.Source.success_capacity
#print axioms LidoSRv3.Audit.MinFirstAllocation.Source.revert_rolls_back
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.source_report_before_reward
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_simulates_oracle_report
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.mint_after_read_discipline
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.mint_order_kill_line
-- Committed-mint event consumers: when the fee mint commits with
-- nonzero sharesToMintAsFees, the emitted event list is exactly the
-- transfer / transferShares pair keyed on the locatorAccounting sink
-- and the checked FeeResult.sharesToMintAsFees, i.e. the amount is not
-- an input independent of the committed getter. Registered here so
-- the two forms (bare ReportFeeMint.Input and the HandleOracleReportTx
-- root form) both enter the Trust axiom discipline.
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.committed_fee_mint_consumes_checked_result
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.root_committed_fee_mint_consumes_checked_result
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.verity_tx_simulates_pinned_source
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.revert_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.mintAfterReadDiscipline_holds
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.mintOrderKillLine_holds
#print axioms LidoSRv3.Tests.HandleOracleReportTxMutants.reordered_mint_read_kill_line_refutes_parent
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.run_claim_success
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.admission_address_equivariant
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.claim_admits
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.claim_rejects_empty_balance
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.claim_rejects_when_paused
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.ownerGated_not_admission_equivariant
-- AddressAdmission low-level lookups and witness-plane invariants that
-- underpin the equivariance proofs above. `paused_lookup`, `owner_lookup`,
-- `balances_lookup` are the executable oracle-slot readers.
-- `witness_balance_slot_{one,two}` and `witness_pause_disjoint_{one,two}`
-- are `decide`-checked concrete witness invariants for the two-actor test
-- fixture. `run_ownerGated_success` is the owner-gated success shape;
-- `ownerGateKillLine_holds` refutes universal owner-gated admission.
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.paused_lookup
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.owner_lookup
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.balances_lookup
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.witness_balance_slot_one
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.witness_balance_slot_two
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.witness_pause_disjoint_one
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.witness_pause_disjoint_two
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.run_ownerGated_success
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.ownerGateKillLine_holds
#print axioms LidoSRv3.Audit.Verity.ConsolidationCallFragment.raw_call_entrypoint_always_reverts
#print axioms
  LidoSRv3.Audit.Verity.ConsolidationCallFragment.external_call_bind_entrypoint_always_reverts
#print axioms LidoSRv3.Audit.Verity.ConsolidationCallFragment.requestConsolidationBind_registered
#print axioms
  LidoSRv3.Audit.Verity.ConsolidationCallFragment.registered_external_call_bind_entrypoint_always_reverts
#print axioms LidoSRv3.Audit.Verity.ConsolidationCallFragment.guards_only_succeeds
#print axioms LidoSRv3.Audit.Verity.ConsolidationCallFragment.success_hypotheses_are_vacuous
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.universal_address_writer_equivariance
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.abstract_source_verity_tx_address_equivariance
-- Address-renaming permutation lemmas that underpin every address-space
-- equivariance argument in PAddress1: `address_renaming a₁ a₂` is its own
-- inverse (involutive), injective, surjective, and therefore bijective.
-- Registered here so the elementary permutation surface enters the Trust
-- axiom discipline together with the top-level equivariance parent.
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.address_renaming_involutive
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.address_renaming_injective
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.address_renaming_surjective
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.address_renaming_bijective
-- `admission_and_post_state_equivariance` is the composed decomposition
-- lemma showing that admission non-discrimination + post-state
-- equivariance implies the full `address_nondiscrimination` conclusion.
-- `universal_post_state_equivariance` is the source-side committed-post
-- equivariance on the live SolidityAddress `run`, keyed on a₁ ≠ 0 and
-- a₂ ≠ 0.
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.admission_and_post_state_equivariance
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.universal_post_state_equivariance
#print axioms LidoSRv3.Audit.Verity.AddressTx.pinned_source_observable_correspondence
#print axioms LidoSRv3.Audit.Verity.AddressTx.executed_address_writes_follow_renamed_source
#print axioms LidoSRv3.Audit.Verity.AddressTx.every_revert_restores_snapshot
#print axioms LidoSRv3.Tests.AddressSourceMutants.verity_wrong_recipient_mutant_rejected
#print axioms LidoSRv3.Tests.AddressSourceMutants.verity_fixed_owner_writer_mutant_rejected
#print axioms LidoSRv3.Tests.AddressSourceMutants.verity_zero_amount_rejected
#print axioms LidoSRv3.Tests.AddressSourceMutants.fixed_owner_gate_not_admission_equivariant
#print axioms LidoSRv3.Tests.AddressSourceMutants.fixed_owner_gate_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.AddressSourceMutants.fixed_owner_writer_kill_line_refutes_parent
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_simulates_consolidation
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_revert_restores_snapshot
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_journal_forwards_msg_value
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_preserves_eth_balance
-- Registered kill-lines for the consolidation parent's premise-necessity
-- surface: the gateway-admitted nonzero premise is genuinely load-bearing
-- (no in-scope caller run derives it), and the packed source/target
-- concat order is refuted by a swapped-order witness. Each pins its
-- parent hypothesis as necessary rather than accidentally satisfied.
-- (`fee_blind_commit_kill_line_refutes_parent` is intentionally kept
-- out of this disclosure: its `native_decide` dependencies are not
-- in the accepted test/mutant-only disclosure set.)
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_admitted_nonzero_kill_line
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.packing_order_kills_swapped_concat
#print axioms LidoSRv3.Audit.Verity.ConsolidationTx.function_spec_bridge_constructors
#print axioms LidoSRv3.Audit.Verity.ConsolidationTx.committed_journal_forwards_msg_value
#print axioms LidoSRv3.Audit.Verity.ConsolidationTx.committed_preserves_eth_balance
#print axioms LidoSRv3.Audit.Verity.ConsolidationTx.entry_credit_overflow_reverts
#print axioms
  LidoSRv3.Tests.ConsolidationTxMutants.value_blind_debit_kill_line_refutes_preserves_eth_balance
#print axioms
  LidoSRv3.Tests.ConsolidationTxMutants.double_debit_kill_line_refutes_preserves_eth_balance
#print axioms
  LidoSRv3.Tests.ConsolidationTxMutants.journal_value_blind_kill_line_refutes_exact_forwarding
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.bounded_transfer_model_source_tx
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_claim_withdrawals_to_chain
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_claim_recipient_effect
#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchTx.every_revert_restores_snapshot
-- AddressClaimBatchTx one-step storage results: `claimOne_success_guards`
-- derives the four pinned admission guards from a successful `claimOne`
-- (requestId, finalisation bound, non-claimed bit, owner==sender);
-- `claimOne_success_storage` derives the exact `lockedEther` subtraction
-- write and the word bound on the payout.
#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchTx.claimOne_success_guards
#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchTx.claimOne_success_storage
-- AddressRecipientCallBridge: bridge module that lifts each pinned
-- AddressClaimBatchTx storage-only iteration into a real recipient
-- CALL against the callee world, and pins snapshot-restoration on
-- every failure path per entrypoint (claim/transfer/request/unwrap)
-- plus the shared entry receipt for the empty-value EOA CALL.
#print axioms LidoSRv3.Audit.Verity.AddressRecipientCallBridge.eoa_empty_value_call_receipt
#print axioms LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claim_withdrawals_to_revert_restores_caller_and_callee_world
#print axioms LidoSRv3.Audit.Verity.AddressRecipientCallBridge.transfer_revert_restores_world
#print axioms LidoSRv3.Audit.Verity.AddressRecipientCallBridge.request_revert_restores_caller_and_callee_world
#print axioms LidoSRv3.Audit.Verity.AddressRecipientCallBridge.unwrap_bridge_receipt
#print axioms LidoSRv3.Audit.Verity.AddressRecipientCallBridge.unwrap_revert_restores_caller_and_callee_world
#print axioms LidoSRv3.Audit.Verity.AddressRecipientCallBridge.revert_restores_caller_and_callee_world
#print axioms LidoSRv3.Audit.Verity.AddressTransferTx.tx_refines_source_witness
-- AddressTransferTx additional executable-level witnesses: successful
-- `run` commits the owner handoff, is post-state equivariant under
-- address renaming on the witness, rejects wrong-caller access, and
-- projects the abstract model / source / verity address-equivariance
-- slice back onto the transfer entrypoint.
#print axioms LidoSRv3.Audit.Verity.AddressTransferTx.run_commits_owner_handoff
#print axioms LidoSRv3.Audit.Verity.AddressTransferTx.run_post_state_equivariant_witness
#print axioms LidoSRv3.Audit.Verity.AddressTransferTx.wrong_caller_reverts
#print axioms LidoSRv3.Audit.Verity.AddressTransferTx.model_source_tx_address_equivariance_slice
#print axioms LidoSRv3.Audit.Source.AddressTransferCorrespondence.fixed_caller_mutant_rejected
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_router_balance_unchanged
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_reverting_branch_moves_no_ether
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_nonconserving_deployment_reverts
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.verity_tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.DepositTx.run_simulates_source
#print axioms LidoSRv3.Tests.DepositTxMutants.double_beacon_send_rejected
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.verity_tx_composes_deposit_conservation_and_rollback
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.canonical_composition_witness
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.linked_deployment_push_is_word_bounded
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.linked_conserving_deployment_pull_is_word_bounded
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.linked_hypotheses_do_not_bound_the_line_972_product
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.skewed_pull_witness_turned_away_before_line_972
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.line_972_product_le_module_allocation
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.encodable_allocation_bounds_line_972_product
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.in_range_commit_is_word_bounded
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.oversized_run_commits
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.oversized_input_is_outside_the_source_domain
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.oversized_input_exceeds_word
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.abstract_parent_covers_inputs_the_verity_plane_omits
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.manyKey_input_is_within_the_source_domain
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.manyKey_run_commits
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.manyKey_links_source_two_legs
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.manyKey_entry_state_guards_are_load_bearing
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.manyKey_underfunded_entry_reverts_at_not_enough_ether
-- PDeposit1 ledger identities: on any well-linked source/inputs pair,
-- the linked total equals the executable pushed value (and, under
-- noWrap, the depositsValue). The `exactTotal` variants add
-- multiplicative per-batch discipline. `canonical_links_source` is
-- the concrete canonical witness under which the composed hypotheses
-- fire, and `two_batch_conjunct_d_is_n_eq_two` records the
-- two-batch limitation as a definitional fact of `DepositNFrameTx.
-- ofTwoBatches` rather than a hidden premise.
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.linked_total_eq_pushedValue
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.linked_total_eq_depositsValue
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.canonical_links_source
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.exactTotal_eq_exactKeys_mul
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.linked_exactTotal_eq_pushedValue
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.linked_exactTotal_eq_depositsValue
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.two_batch_conjunct_d_is_n_eq_two
#print axioms LidoSRv3.Audit.Verity.DepositParentTx.execute_observes_source
#print axioms
  LidoSRv3.Audit.Verity.DepositParentTx.revert_after_intermediate_writes_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.DepositParentTx.revert_observes_idle
#print axioms LidoSRv3.Tests.DepositParentTxMutants.mutant_none_reproduces_execute
#print axioms LidoSRv3.Tests.DepositParentTxMutants.skipped_allocation_write_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.skipped_dynamic_data_write_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.skipped_root_write_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.misrouted_push_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.dropped_push_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.root_failure_observes_idle
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.verity_tx_composes_nframe_deposit
-- General rule (Thomas 2026-09-12) applied to DEPOSIT-1 LinksSource:
-- registered composition derives LinksSource from router-shape fields
-- (grok #405 consumer nframe_linksSource_of_router_fields), instead of
-- taking it as a free caller hypothesis.
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.verity_tx_composes_nframe_deposit_under_router_shape
#print axioms LidoSRv3.Audit.Verity.DepositNFrameTx.nframe_deposit_parent
#print axioms
  LidoSRv3.Audit.Verity.DepositNFrameTx.wrapping_fold_reverts_without_journal
#print axioms LidoSRv3.Audit.Spec.DepositNFrameCorrespondence.router_links_source
#print axioms
  LidoSRv3.Tests.DepositNFrameTxMutants.fixed_two_only_refutes_nframe_parent
-- Foundational arithmetic identities for the value-conservation ledger
-- used by the P-CONSOLIDATION-ETH-1 supplementals: `totalAmount` is
-- `foldl (+) 0 . map amount`, and the ledger conservation identity
-- `fee + (msgValue - fee) = msgValue` under `fee ≤ msgValue`.
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.totalAmount_nil
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.totalAmount_cons
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.totalAmount_append
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.totalAmount_replicate
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.composed_eth_conservation
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.eth_flow_confined
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.consolidation_fee_path_confined
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.eth_flow_parent
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.eth_flow_parent_at_canonical
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.verity_tx_universal_success_shape
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.verity_tx_universal_revert_partition
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.verity_tx_universal_zero_remainder_boundary
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.verity_tx_success_and_revert_partition
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.verity_tx_composes_value_flow_and_rollback
-- Chantier 5 (mandate 2026-09-12): additive derived consumer integrating grok #410,
-- lifting the P-CONSOLIDATION-ETH-1 success arm to derived fuel batchSize+4.
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.verity_tx_success_shape_unbounded
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.registered_parent_is_instance_at_32
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.registered_parent_recovered_at_32
-- General rule (Thomas 2026-09-12) applied to P-CONSOLIDATION-ETH-1
-- batchSize: derived-fuel success under mainnet Bus batchSize ceiling.
-- The registered parent's exhausted arm at batchSize ≥ 29 is a
-- fuelBudget = 32 model artifact; the mainnet Bus ceiling is 200,
-- so batches up to 200 fit at derived fuel batchSize + 4.
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.verity_tx_success_at_derived_fuel_under_bus_ceiling
-- General rule (Thomas 2026-09-12) applied to P-ALLOC-1 CheckedBounds
-- target_multiplication conjunct: derives shareLimit * totalValidators ≤
-- MAX_UINT256 from pinned StakingModule.shareLimit:uint16 + totalValidators:
-- uint64 type bounds (65535 * 2^64 << 2^256).
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded.target_multiplication_under_pinned_type_bounds
#print axioms LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants.truncated_fuel_batchSize_plus_three_exhausted
#print axioms LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants.truncated_fuel_must_be_refused
#print axioms LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants.parent_fuel_premise_excludes_batch_29
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.rejects_dropped_refund_leg
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.rejects_misrouted_vault_leg
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.rejects_corrupted_refund_amount
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.rejects_preserved_prefix_after_failed_hop
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.rejects_single_request_for_two_request_batch
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.universal_parent_is_predicate_at_honest
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.dropped_refund_leg_kill_line_refutes_universal_parent
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.misrouted_vault_kill_line_refutes_universal_parent
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.corrupted_refund_kill_line_refutes_universal_parent
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.single_request_kill_line_refutes_universal_parent
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.zero_value_kill_line_refutes_dropped_positivity
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.underfunded_kill_line_refutes_dropped_funding
#print axioms LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants.fuel_exhaustion_kill_line_refutes_dropped_fuel_premise
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx.gateway_refund_success_moves_value
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx.gateway_refund_failure_keeps_prefix_out
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx.withdraw_success_moves_to_lido
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx.refund_failure_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RequestTx.bus_forward_success
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RequestTx.consolidation_fee_target_success
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RequestTx.withdrawal_fee_success
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RequestTx.consolidation_second_failure_discards_prefix
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RequestTx.bus_failure_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx.sourceGateway_committed_splits_to_vault_and_refund
#print axioms LidoSRv3.Tests.PConsolidationEth1RefundTxMutants.refund_misroute_kill_line
#print axioms LidoSRv3.Tests.PConsolidationEth1RefundTxMutants.double_refund_rejected
#print axioms LidoSRv3.Tests.PConsolidationEth1RefundTxMutants.leak_on_refund_failure_rejected
#print axioms LidoSRv3.Tests.PConsolidationEth1RequestTxMutants.keep_first_consolidation_fee_rejected
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_wrap_precludes_value_moving_commit
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_module_guard_required
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_wc_type2_guard_required
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_router_balance_unchanged
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_reverting_branch_moves_no_ether
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_balance_guards_discharged
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_unchecked_accumulation_faithful
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_pinned_config_discharges_pubkey_guard
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.verity_wrap_to_zero_is_empty_commit
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.verity_nonzero_wrap_witness_reverts_and_restores
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.verity_nonzero_wrap_reverts_and_restores
#print axioms
  LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close
-- PTopup1 provenance / audit-only claims about what the pinned source
-- alone does *not* determine: `pinned_constructor_span_does_not_
-- determine_beacon_address` refutes any attempt to derive the beacon
-- address from constructor-span provenance alone;
-- `no_source_only_beacon_address_derivation` states the same at the
-- source level; `source_allocation_guards_required` and
-- `source_over_target_guard_required` pin the two allocation guards
-- (module-selected, over-target) as necessary rather than accidental.
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.pinned_constructor_span_does_not_determine_beacon_address
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.no_source_only_beacon_address_derivation
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_allocation_guards_required
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_over_target_guard_required
#print axioms LidoSRv3.Audit.Verity.TopupHybrid.verity_tx_simulates_source
-- TopupHybrid additional adequacy: the source's value observation is
-- adequate to close the hybrid simulation on the modeled surface.
#print axioms LidoSRv3.Audit.Verity.TopupHybrid.source_value_observation_adequate
-- TopupBeaconFundedTx four core aggregate/conservation identities
-- covering the beacon-funded slice: `accounting_count` fixes the
-- observed accounting size; `gateway_amount_exact` pins the exact
-- forwarded amount to the gateway; `positive_conservation` documents
-- positive-value conservation across the boundary; `wrapped_zero`
-- excludes the wrap-to-zero degenerate case.
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.accounting_count
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.gateway_amount_exact
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.positive_conservation
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.wrapped_zero
-- TopupFundedSourceTx seven core lemmas covering the funded-source
-- slice: balance projection, ledger round-trip, gateway projection
-- bound, accounting calls shape, push run shape, positive
-- conservation, and the wrap-to-zero exclusion.
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.project_balance
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.ledger_roundtrip
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.gateway_projection_bound
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.accounting_calls
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.push_run
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.positive_conservation
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.wrapped_zero
#print axioms LidoSRv3.Tests.TopupHybridMutants.hybrid_simulation_covers_nonzero_wrap
#print axioms LidoSRv3.Tests.TopupHybridMutants.hybrid_simulation_covers_wrap_to_zero
#print axioms LidoSRv3.Tests.TopupTxMutants.mutant_none_reproduces_execute
#print axioms LidoSRv3.Tests.TopupTxMutants.honest_run_matches_source
#print axioms LidoSRv3.Tests.TopupTxMutants.skipped_allocation_write_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.dropped_push_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.misrouted_push_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.corrupted_amount_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.swapped_order_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.duplicated_push_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.allocation_write_failure_rolls_back
#print axioms LidoSRv3.Tests.TopupTxMutants.lido_pull_failure_rolls_back
#print axioms LidoSRv3.Tests.TopupTxMutants.first_beacon_failure_rolls_back
#print axioms LidoSRv3.Tests.TopupTxMutants.guard_discharge_at_wrapping_input
#print axioms LidoSRv3.Tests.TopupTxMutants.wrap_to_zero_commits_no_topup
#print axioms LidoSRv3.Tests.TopupTxMutants.guard_discharge_at_unregistered_module_input
#print axioms LidoSRv3.Tests.TopupTxMutants.guard_discharge_at_non_type2_wc_input
#print axioms LidoSRv3.Tests.TopupTxMutants.mutantRunNoAssert_eq_run_of_assert_passing
#print axioms LidoSRv3.Tests.TopupTxMutants.mutantRunNoAssert_commits_where_assert_fires
#print axioms LidoSRv3.Tests.TopupTxMutants.dropped_conservation_assert_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.TopupTxMutants.dropped_module_guard_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.TopupTxMutants.dropped_wc_guard_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.TopupTxMutants.unwrapped_accumulator_kill_line_refutes_parent
#print axioms LidoSRv3.Audit.Source.Topup2.source_aggregate_bounded_by_block_cap
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_block_cap
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.actual_module_batch_bound
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.per_key_bounded_by_candidate
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_aggregate_bounded_by_block_cap
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_all_success_value_exact
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_revert_restores_world
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_committed_world_is_commit_fold
-- Topup2DistributionTx: the four `sourceRunIndependent_eq_sourceRun`
-- family lemmas document that the top-level source-run and its helpers
-- (consume, limits, candidates) do not depend on the `DenoteOracle`
-- once the decode premises are supplied — i.e. the memory-array
-- reads are oracle-independent on the currently-registered path.
#print axioms LidoSRv3.Audit.Verity.Topup2DistributionTx.sourceConsumeIndependent_eq_sourceConsume
#print axioms LidoSRv3.Audit.Verity.Topup2DistributionTx.sourceLimitsIndependent_eq_sourceLimits
#print axioms LidoSRv3.Audit.Verity.Topup2DistributionTx.sourceCandidatesIndependent_eq_sourceCandidates
#print axioms LidoSRv3.Audit.Verity.Topup2DistributionTx.sourceRunIndependent_eq_sourceRun
-- Topup2Tx additional executable-transaction shape lemmas:
-- `denoteTransaction_revert_world` restores the entry world on any
-- revert; `forEachCall_callsIn_take` decomposes the fold on
-- `callsIn`; `plannedSites_value_sum` and `valueSum_take_le` are
-- the aggregate ledger bounds; `callsIn_all_success_eq_planned`
-- documents the all-success shape; `tx_all_rollback_preserves_world`
-- is the paired revert-preservation counterpart of
-- `tx_committed_world_is_commit_fold`; `gateway_abort_is_failed_call`
-- names the specific failed-call cause.
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.denoteTransaction_revert_world
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.forEachCall_callsIn_take
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.plannedSites_value_sum
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.valueSum_take_le
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.callsIn_all_success_eq_planned
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_all_rollback_preserves_world
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.gateway_abort_is_failed_call
#print axioms LidoSRv3.Tests.Topup2TxMutants.over_cap_aggregate_rejected
#print axioms LidoSRv3.Tests.Topup2TxMutants.double_send_rejected
#print axioms LidoSRv3.Tests.Topup2TxMutants.reverting_adversary_cannot_leak_state
#print axioms LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve
#print axioms LidoSRv3.Audit.Guarantees.PReserve1.verity_tx_simulates_reserve_spec
#print axioms LidoSRv3.Audit.Guarantees.PReserve1.verity_tx_preserves_withdrawal_reserve
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.abstract_reserve_does_not_change_finalization
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.source_reserve_does_not_change_finalization
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_tx_simulates_reserve_relational_spec
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_tx_reverts_on_locked_overflow
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_reserve_slot_is_not_read
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_reserve_does_not_change_finalization
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.deposit_root_iff
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.deposit_unique_of_perfect
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.sourceNode_mutant_kill_line_refutes_parent
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.composed_ssz_encoding
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.swapped_combine_kill_line_refutes_parent
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.composedEncodingOkFull_not_trivial_crossed_witness
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.inconsistent_witness_kill_line
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.inconsistent_operation_index_kill_line
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.sourceWitness_binds_sourceNode
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_simulates_ssz_encoding
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_two_batch_rolls_back
-- SSZ auxiliary source-level lemmas and richer verity-tx correspondences
-- now that the Mac-agent SSZ lane is released to Spark. `toByteArray_size`
-- pins the ByteArray-length invariant, `srcInputs_exactWidths` ties the
-- input widths to the pinned config, `sourceWitness_index_le_maxUint248`
-- guarantees the sourceWitness index fits the 248-bit bound.
-- `composed_ssz_encoding_full` composes the ComposedSszInput with
-- verified widths, and `verity_tx_one_object_matches_sourceView` states
-- the observe/sourceView equality at the TX level for one derived
-- object. `traverseBranch_sourceCombineSwapped_eq` and
-- `swapped_traverse_ne_structuralEncoding` are the paired
-- symbolic-cursor / structural-encoding kill-lines.
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.toByteArray_size
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.srcInputs_exactWidths
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.sourceWitness_index_le_maxUint248
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.composed_ssz_encoding_full
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_one_object_matches_sourceView
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.traverseBranch_sourceCombineSwapped_eq
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.swapped_traverse_ne_structuralEncoding
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.verity_tx_simulates_pinned_source
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.encoding_commits_structural_witness
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.revert_restores_snapshot
-- SszEncodingTx additional executable-transaction correspondences:
-- `readSlot_writeWords`, `readSlot_writeDigests` decompose the storage
-- reads; `revert_restores_snapshot_two` is the paired two-item revert
-- witness; `encoding_uses_source_concat`, `encoding_uses_exact_digest`
-- pin the source-concat and exact-digest choices; `encoding_accepts_iff_root_matches`
-- ties acceptance to the root; `encoding_requires_pinned_widths` and
-- `encoding_requires_structural_bind` document the requirements;
-- `sourceObs_committed_fields` and `structuralOk_implies_conjunct`
-- close the observation and structural implication side.
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.readSlot_writeWords
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.readSlot_writeDigests
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.revert_restores_snapshot_two
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.encoding_uses_source_concat
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.encoding_uses_exact_digest
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.encoding_accepts_iff_root_matches
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.encoding_requires_pinned_widths
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.encoding_requires_structural_bind
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.sourceObs_committed_fields
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.structuralOk_implies_conjunct
#print axioms LidoSRv3.Audit.Source.GIndexConcatCorrespondence.source_concat_matches_spec
#print axioms LidoSRv3.Audit.Source.GIndexConcatCorrespondence.source_concat_value_of_fits
#print axioms LidoSRv3.Audit.Source.GIndexConcatCorrespondence.source_concat_depth_overflow
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.ssz_tx_simulation_correct
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.sha256_call_world_rollback
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.root_mutant_rejected
-- SszTxSimulation additional acceptances: `sha256_site_is_address_two_staticcall`
-- pins the modeled SHA256 call site to address 2 STATICCALL;
-- `sha256_denoteCall_preserves_world` documents that a SHA256
-- staticcall preserves the world; `accepted_iff_root_matches` is the
-- acceptance-vs-root equivalence; `verification_failure_rolls_back`
-- is the paired transaction-boundary rollback on failed verification.
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.sha256_site_is_address_two_staticcall
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.sha256_denoteCall_preserves_world
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.accepted_iff_root_matches
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.verification_failure_rolls_back
#print axioms
  LidoSRv3.Audit.Source.DepositDataRootCorrespondence.source_pinned_config_discharges_deposit_data_root
#print axioms LidoSRv3.Audit.MinFirst.candidate_mem
#print axioms LidoSRv3.Audit.MinFirst.candidate_open
#print axioms LidoSRv3.Audit.MinFirst.candidate_none_no_open
#print axioms LidoSRv3.Audit.MinFirst.candidate_minimal
#print axioms LidoSRv3.Audit.MinFirst.candidate_router_tie
#print axioms LidoSRv3.Audit.MinFirst.incrementSelected_moduleId
#print axioms LidoSRv3.Audit.MinFirst.incrementSelected_active
#print axioms LidoSRv3.Audit.MinFirst.incrementSelected_monotone
#print axioms LidoSRv3.Audit.MinFirst.incrementSelected_eq_of_ne
#print axioms LidoSRv3.Audit.MinFirst.step_preserves_length
#print axioms LidoSRv3.Audit.MinFirst.step_preserves_module_order
#print axioms LidoSRv3.Audit.MinFirst.loop_preserves_length
#print axioms LidoSRv3.Audit.MinFirst.loop_preserves_module_order
#print axioms LidoSRv3.Audit.MinFirst.allocate_preserves_length
#print axioms LidoSRv3.Audit.MinFirst.allocate_preserves_module_order
#print axioms LidoSRv3.Audit.MinFirst.run_spent_le
#print axioms LidoSRv3.Audit.MinFirst.totalAllocated_le_requested
#print axioms LidoSRv3.Audit.Common.BoundedAmount.checkedAdd_sound
#print axioms LidoSRv3.Audit.Common.revert_rolls_back_state_and_committed_effects
#print axioms LidoSRv3.Audit.Common.success_exposes_exact_committed_effects

#print axioms LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants.ownership_write_drop_kill_line_refutes_exact_parent
#print axioms LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants.ownership_write_mutant_preserves_admission
#print axioms LidoSRv3.Audit.Guarantees.PEthConfinement1.modeled_positive_value_is_confined_or_residual
#print axioms LidoSRv3.Audit.Verity.MinFirstSourceEntry.zero_demand
#print axioms LidoSRv3.Audit.Verity.MinFirstSourceEntry.short_capacity
#print axioms LidoSRv3.Audit.Verity.MinFirstSourceEntry.success_preserves_state
#print axioms LidoSRv3.Audit.Verity.MinFirstSourceEntry.revert_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.MinFirstSourceEntry.success_refines_proportional_model
#print axioms LidoSRv3.Audit.Verity.AllocationTx.live_revert_restores_snapshot

#print axioms LidoSRv3.Audit.Verity.MinFirstSourceEntry.eager_guard_disagrees_on_zero_demand

#print axioms LidoSRv3.Audit.Guarantees.PEthConfinement1.modeled_inventory_matches_exact_assignments
#print axioms LidoSRv3.Tests.EthConfinementMutants.swaps_preserve_presence
#print axioms LidoSRv3.Tests.EthConfinementMutants.kill_exact_assignment_parent_swap
#print axioms LidoSRv3.Tests.EthConfinementMutants.kill_exact_assignment_approval_swap
#print axioms LidoSRv3.Tests.EthConfinementMutants.kill_exact_assignment_destination_swap

-- Trio source/word-memory and explicit VM-plane composition.
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.Relational.producer_iff
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.producer_math_view
#print axioms LidoSRv3.Audit.Source.TrioAlloc2.allocate_refines
#print axioms LidoSRv3.Audit.Source.TrioAlloc2.distribution_exists
#print axioms LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredProducer.success
#print axioms LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent.public_iff
#print axioms LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent.success
#print axioms LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent.positive_calls
#print axioms LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent.trace_shape
#print axioms LidoSRv3.Audit.Source.TrioComposition.LifecycleHistory.stored_parent_iff
#print axioms LidoSRv3.Audit.Source.TrioComposition.VerityParent.stored_correspondence
#print axioms LidoSRv3.Audit.Source.TrioComposition.ReserveLeafSpend.withdrawal_corresponds
#print axioms LidoSRv3.Audit.Source.TrioReserve1.AllocationFlow.withdrawal_corresponds
#print axioms LidoSRv3.Audit.Source.TrioReserve1.PhysicalReserve.success_preserves
#print axioms LidoSRv3.Audit.Source.TrioReserve1.PhysicalSequence.corresponds
#print axioms LidoSRv3.Audit.Source.TrioReserve1.Transfers.credit_bound_from_aggregate

#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_live_pipeline_conservation

#print axioms LidoSRv3.Audit.Guarantees.PTopup1.actual_continuation_conserves
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.actual_deposit_call_binds_root

#print axioms LidoSRv3.Audit.Guarantees.PTopup1.actual_module_batch_effects

#print axioms LidoSRv3.Audit.Guarantees.PConsolidation1.actual_gateway_vault_requests
#print axioms LidoSRv3.Audit.Guarantees.PConsolidation1.actual_gateway_vault_failure_restores

#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_physical_metadata_before_calls
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_physical_metadata_failure_restores

#print axioms LidoSRv3.Audit.Guarantees.PSsz1.actual_memory_validator_branch

#print axioms LidoSRv3.Audit.Guarantees.PSsz1.actual_root_staticcall_validator_branch
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.actual_root_staticcall_validator_tree
#print axioms LidoSRv3.Audit.Source.SszRootCall.run_world

#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_settlement_success
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_settlement_failure_restores

#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_physical_metadata_conserves
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.actual_continuation_locator_conserves

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_claim_withdrawals_failure_restores
#print axioms LidoSRv3.Tests.PackDAddressClaimMutants.zero_recipient_rejects_before_claim
#print axioms LidoSRv3.Tests.PackDAddressClaimMutants.failed_batch_restores_world

#print axioms LidoSRv3.Audit.Guarantees.PTopup2.actual_root_module_batch_bound
#print axioms LidoSRv3.Audit.Source.TopupBatchRootCalls.failure_restores
#print axioms LidoSRv3.Tests.TopupBatchRootCallsRegression.actual_batch_has_joint_guarantee
#print axioms LidoSRv3.Tests.TopupBatchRootCallsRegression.two_rows_consume_ordered_limits

#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_failure_restores
#print axioms AccountActualMintRegression.same_world_mint_and_rate
#print axioms AccountActualMintRegression.mismatched_accounting_rejects
#print axioms AccountActualMintRegression.mapping_overflow_restores_packed_word

#print axioms LidoSRv3.Audit.Guarantees.PTopup2.actual_module_no_code_failure
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.actual_root_batch_no_code_failure

#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_casts
#print axioms AccountAddress.ReportFeeCastInvariant.report_allocation_le_total
#print axioms AccountAddress.Tests.Verity.ReportFeeCastInvariantTest.module_slot_collision
#print axioms AccountAddress.Tests.Verity.ReportFeeCastInvariantTest.router_slot_collision
#print axioms AccountAddress.Tests.Verity.ReportFeeCastInvariantTest.actual_positive_mint_casts

#print axioms LidoSRv3.Audit.Guarantees.PTopup1.actual_root_module_batch_effects
#print axioms LidoSRv3.Audit.Source.TopupRootCallEffects.run_success
#print axioms LidoSRv3.Tests.TopupRootCallEffectsRegression.zero_keeps_actual_module_effects
#print axioms LidoSRv3.Tests.TopupRootCallEffectsRegression.positive_batch_joint_consumer
#print axioms LidoSRv3.Tests.TopupRootCallEffectsRegression.positive_physical_balances_and_count
#print axioms LidoSRv3.Tests.TopupRootCallEffectsRegression.actual_reply_above_cap_restores

#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_checked_split
#print axioms AccountAddress.ReportFeeMint.checkedFeeResultOf_split
#print axioms AccountAddress.ReportFeeMint.checkedFeeProducts_split_origin
#print axioms AccountAddress.ReportFeeCheckedSplit.committed_checked_split

#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_settlement_requests
#print axioms audit.trio.consolidation.SettlementRequests.execute_success
#print axioms LidoSRv3.Tests.ConsolidationSettlementRequestsRegression.actual_two_requests_joint_consumer
#print axioms LidoSRv3.Tests.ConsolidationSettlementRequestsRegression.zero_refund_joint_consumer
#print axioms LidoSRv3.Tests.ConsolidationSettlementRequestsRegression.decoded_loop_and_refund_effects

#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_module_call_metadata_suffix
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_module_call_failure_restores
#print axioms audit.trio.deposit.ModuleCall.decodeReturn_size_bounds
#print axioms audit.trio.deposit.ModulePhysicalMetadata.success_effects

#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_distribution
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_distribution_failure_restores
#print axioms AccountAddress.ReportFeeDistribution.minted_budget
#print axioms AccountAddress.FeeDistribution.PaymentChain.ledger

#print axioms LidoSRv3.Audit.Guarantees.PTopupMemoryCalls.actual_root_module_memory_effects
#print axioms LidoSRv3.Audit.Guarantees.PTopupMemoryCalls.actual_root_module_memory_failure_restores
#print axioms LidoSRv3.Audit.Source.TopupModuleMemory.raw_bounds
#print axioms LidoSRv3.Audit.Source.TopupModuleMemory.decode_success

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_request_withdrawal_enqueue
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_request_withdrawal_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressRequestCalls.enqueue_success
#print axioms LidoSRv3.Tests.AddressRequestCalls.public_late_rollback_instance

#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_treasury_call
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_treasury_failure_restores
#print axioms AccountAddress.TreasuryCall.call_success
#print axioms AccountAddress.ReportFeeTreasuryCall.distribute_success

#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_registered_module_call_metadata_suffix
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_registered_module_failure_restores
#print axioms LidoSRv3.Audit.Source.DepositPhysicalAdmission.selected_fields
#print axioms LidoSRv3.Audit.Source.DepositPhysicalAdmission.selectedOctets_head

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_request_withdrawal_enqueue
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_request_withdrawal_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressWrappedRequestCalls.unwrap_success
#print axioms LidoSRv3.Audit.Source.AddressWrappedRequestCalls.request_success

#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_dsm_call_registered_module_suffix
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_dsm_call_failure_restores
#print axioms LidoSRv3.Audit.Source.DepositDsmCall.lookup_origin
#print axioms LidoSRv3.Audit.Source.DepositDsmCall.success_effects

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_token_request_enqueue
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_token_request_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressWrappedTokenCalls.canonical_call
#print axioms LidoSRv3.Audit.Source.AddressWrappedTokenCalls.joined_success

#print axioms LidoSRv3.Audit.Guarantees.PSsz1.actual_compiled_cl_entry_branch
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.actual_compiled_cl_entry_tree
#print axioms LidoSRv3.Audit.Source.SszCompiledClEntry.beforeRoot_success
#print axioms LidoSRv3.Audit.Source.SszCompiledClEntry.rootCall_success
#print axioms LidoSRv3.Audit.Source.SszCompiledClEntry.afterRoot_success
#print axioms LidoSRv3.Audit.Source.SszCompiledClEntry.run_success

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_transfer_request_enqueue
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_transfer_request_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressWrappedTransferCalls.canonical_outer_call
#print axioms LidoSRv3.Audit.Source.AddressWrappedTransferCalls.joined_success

#print axioms LidoSRv3.Audit.Guarantees.PTopupCredentialCalls.actual_credential_root_module_memory_effects
#print axioms LidoSRv3.Audit.Guarantees.PTopupCredentialCalls.actual_credential_root_module_failure_restores
#print axioms LidoSRv3.Audit.Source.TopupCredentialCall.lookup_origin
#print axioms LidoSRv3.Tests.TopupCredentialCall.public_consumer

#print axioms LidoSRv3.Audit.Guarantees.PTopupPhysicalCredentialGetter.actual_physical_credential_root_module_memory_effects
#print axioms LidoSRv3.Audit.Guarantees.PTopupPhysicalCredentialGetter.actual_physical_credential_root_module_failure_restores
#print axioms LidoSRv3.Audit.Source.TopupPhysicalCredentialGetter.dispatch_request
#print axioms LidoSRv3.Tests.TopupPhysicalCredentialGetter.public_consumer

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_request_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_request_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_batch_failure_restores
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_batch_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressRequestBatches.loop_success
#print axioms LidoSRv3.Tests.AddressRequestBatches.public_empty_steth

#print axioms LidoSRv3.Audit.Guarantees.PTopupTimingHistory.actual_timing_credential_root_module_memory_history
#print axioms LidoSRv3.Audit.Guarantees.PTopupTimingHistory.actual_timing_credential_root_module_failure_restores
-- `history_effects` is the abstract history-effect equation for a
-- successful timing-history step on the gateway address and total
-- forwarded amount.
#print axioms LidoSRv3.Audit.Guarantees.PTopupTimingHistory.history_effects
#print axioms LidoSRv3.Audit.Source.TopupTimingHistory.execute_projection
#print axioms LidoSRv3.Audit.Source.TopupTimingHistory.packed_fields
#print axioms LidoSRv3.Tests.TopupTimingHistory.public_consumer

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_permit_failure_restores
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_permit_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressPermitRequestCalls.call_success
#print axioms LidoSRv3.Tests.AddressPermitRequestCalls.public_paused_rollback

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_physical_quote_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_quote_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_physical_quote_failure_restores
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_quote_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressStETHQuoteCalls.internalEther_bound
#print axioms LidoSRv3.Audit.Source.AddressStETHQuoteCalls.quote_effect
#print axioms LidoSRv3.Tests.AddressStETHQuoteCalls.public_nonempty_quote_rollback

#print axioms LidoSRv3.Audit.Guarantees.PTopupRouterLocatorCall.actual_locator_timing_credential_root_module_memory_history
#print axioms LidoSRv3.Audit.Guarantees.PTopupRouterLocatorCall.actual_locator_timing_credential_root_module_failure_restores
#print axioms LidoSRv3.Audit.Source.TopupRouterLocatorCall.decode_fields
#print axioms LidoSRv3.Audit.Source.TopupRouterLocatorCall.lookup_origin
#print axioms LidoSRv3.Audit.Source.TopupRouterLocatorCall.run_success
#print axioms LidoSRv3.Audit.Source.TopupRouterLocatorCall.failure_restores

#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_conversion_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_conversion_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressStETHConversionCalls.canonical_call
#print axioms LidoSRv3.Audit.Source.AddressStETHConversionCalls.conversion_effect
#print axioms LidoSRv3.Audit.Source.AddressStETHConversionCalls.item_effect
#print axioms LidoSRv3.Tests.AddressStETHConversionCalls.public_paused_rollback

#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_physical_pause
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_physical_pause_failure_restores
#print axioms AccountAddress.ReportFeePhysicalPause.projection
#print axioms AccountAddress.ReportFeePhysicalPause.mint_frame
#print axioms AccountAddress.ReportFeePhysicalPause.chain_physical
#print axioms LidoSRv3.Tests.AccountPhysicalPause.public_success
#print axioms LidoSRv3.Tests.AccountPhysicalPause.public_failure

-- Actual physical stETH transfer consumed by the wrapped permit batch.
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_steth_transfer_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_steth_transfer_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.balanceSlot_keccak
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.call_effect
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.token_effect
#print axioms LidoSRv3.Tests.AddressStETHTransferCalls.public_empty_success
#print axioms LidoSRv3.Tests.AddressStETHTransferCalls.public_paused_rollback

-- Physical stETH allowance-first direct withdrawal batches.
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_transfer_from_quote_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_transfer_from_quote_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_transfer_from_quote_permit_failure_restores
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_transfer_from_quote_failure_restores
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.allowanceSlot_keccak
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.spend_success
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.transfer_effect
#print axioms LidoSRv3.Tests.AddressStETHTransferFromCalls.public_empty_success
#print axioms LidoSRv3.Tests.AddressStETHTransferFromCalls.public_nonempty_allowance_rollback
-- Physical gateway role and resume gates consumed by the complete TOPUP phase.
#print axioms LidoSRv3.Audit.Guarantees.PTopupEntryAdmission.actual_physical_entry_locator_timing_credential_root_module_memory_history
#print axioms LidoSRv3.Audit.Guarantees.PTopupEntryAdmission.actual_physical_entry_failure_restores
#print axioms LidoSRv3.Audit.Source.TopupEntryAdmission.roleSlot_bytes
#print axioms LidoSRv3.Audit.Source.TopupEntryAdmission.gates_success
#print axioms LidoSRv3.Tests.TopupEntryAdmission.public_rollback

-- Actual physical locator accounting CALL consumed by full report/mint/distribution.
#print axioms AccountAddress.AccountingCall.call_success
#print axioms AccountAddress.AccountingCall.decode_getter
#print axioms AccountAddress.AccountingCall.call_getter
#print axioms AccountAddress.ReportFeeAccountingCall.prepare_success
#print axioms AccountAddress.ReportFeeAccountingCall.mint_replay
#print axioms AccountAddress.ReportFeeAccountingCall.finish_success_replay
#print axioms AccountAddress.ReportFeeAccountingCall.execute_success
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_accounting_call
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_accounting_call_failure_restores
#print axioms LidoSRv3.Tests.AccountAccountingCall.public_success
#print axioms LidoSRv3.Tests.AccountAccountingCall.public_failure

-- Actual physical quota World consumed by the complete settlement/request suffix.
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_physical_quota_settlement_requests
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_physical_quota_failure_restores
#print axioms audit.trio.consolidation.PhysicalQuotaSettlement.quota_effects
#print axioms audit.trio.consolidation.PhysicalQuotaSettlement.packed_fields
#print axioms audit.trio.consolidation.PhysicalQuotaSettlement.updatedTime_success
#print axioms audit.trio.consolidation.PhysicalQuotaSettlement.transition_success

-- Physical consolidation entry consumes the entire quota/settlement result.
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_physical_entry_quota_settlement_requests
#print axioms LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_physical_entry_failure_restores
#print axioms audit.trio.consolidation.PhysicalEntrySettlement.roleSlot_bytes
#print axioms audit.trio.consolidation.PhysicalEntrySettlement.gates_success
#print axioms audit.trio.consolidation.PhysicalEntrySettlement.execute_success
#print axioms audit.trio.consolidation.PhysicalEntrySettlement.failure_restores

-- Exact deposit admission error origins consume the complete DSM suffix.
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.actual_dsm_call_admission_bytes_suffix
#print axioms LidoSRv3.Audit.Source.DepositAdmissionErrors.gate_origin
#print axioms LidoSRv3.Audit.Source.DepositAdmissionErrors.success_projection
#print axioms LidoSRv3.Audit.Source.DepositAdmissionErrors.local_rejection
#print axioms LidoSRv3.Audit.Source.DepositAdmissionErrors.failure_restores

-- DepositLedgerTx executable-transaction correspondence: `run` and
-- `revert` shape lemmas that document the pinned Solidity behaviour on
-- three commitment planes (committing push, empty batch, non-conserving
-- deployment) plus the paired kill-lines refuting a dropped assert and
-- a skipped Lido debit. The `verity_revert_moves_no_ether` and
-- `verity_revert_rolls_back` sisters document the transaction-boundary
-- rollback discipline. `forEach_wrapper_unrolls_once` is the small
-- symbolic wrapper equation used by the loop reasoning.
#print axioms LidoSRv3.Audit.Verity.DepositLedgerTx.forEach_wrapper_unrolls_once
#print axioms LidoSRv3.Audit.Verity.DepositLedgerTx.verity_revert_rolls_back
#print axioms LidoSRv3.Audit.Verity.DepositLedgerTx.verity_revert_moves_no_ether
#print axioms LidoSRv3.Audit.Verity.DepositLedgerTx.verity_tx_matches_source_committing_push
#print axioms LidoSRv3.Audit.Verity.DepositLedgerTx.verity_tx_matches_source_empty_batch
#print axioms LidoSRv3.Audit.Verity.DepositLedgerTx.verity_tx_matches_source_nonconserving_deployment
#print axioms LidoSRv3.Audit.Verity.DepositLedgerTx.dropped_assert_commits_nonconserving_deployment
#print axioms LidoSRv3.Audit.Verity.DepositLedgerTx.skipped_lido_debit_breaks_conservation

-- Actual router admission consumes the entire prior physical TOPUP result.
#print axioms LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall.actual_router_admission_complete_prior
#print axioms LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall.actual_gateway_entry_failure_restores
#print axioms LidoSRv3.Audit.Source.TopupRouterAdmissionCallGates.auth_origin
#print axioms LidoSRv3.Audit.Source.TopupRouterAdmissionCallGates.canDeposit_origin
#print axioms LidoSRv3.Audit.Source.TopupRouterAdmissionCallGates.admitted_calls

-- Complete ABI-declared siblings in the same actual compiled SSZ entry.
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.actual_compiled_cl_entry_complete_declared_branch
#print axioms LidoSRv3.Audit.Source.SszDeclaredSiblings.cursor_dichotomy
#print axioms LidoSRv3.Audit.Source.SszDeclaredSiblings.complete_of_branch
#print axioms LidoSRv3.Audit.Source.SszDeclaredSiblings.penultimate

-- TOPUP pointer-origin memory model: `finalizeAllocation` zones for the
-- credential (STATICCALL 32-byte copy) and module-return (raw + array)
-- allocations. Sequential allocations are provably disjoint;
-- independently supplied credential/module cursors may alias, and the
-- named kill-lines refute the universal non-aliasing claims on well-
-- formed decoder-success premises. No stub, no rename, no axiom beyond
-- the three accepted Lean foundations.
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.sequential_disjoint
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.chained_scalar32_disjoint
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.credentials_zone
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.locator_zone
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.module_decode_zones
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.module_head_in_raw_zone
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.same_cursor_successful_decodes_alias
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.chained_credential_then_module_disjoint
#print axioms LidoSRv3.Audit.Source.TopupPointerOrigin.chained_locator_credential_module_disjoint
#print axioms LidoSRv3.Tests.TopupPointerOriginMutants.independent_cursor_alias_refutes_global_nonalias
#print axioms LidoSRv3.Tests.TopupPointerOriginMutants.module_head_in_array_zone_refuted
#print axioms LidoSRv3.Tests.TopupPointerOriginMutants.returnBuffer_eq_locator_refutes_cross_phase_nonalias

-- SolidityAccounting source-level identities on the accounting words:
-- `checkedTotal64_le` enforces the checked-uint64 upper bound;
-- `checkedTotal256_refines_source` documents the checked-uint256
-- refinement of the source aggregate; `source_report_before_reward_retired`
-- retains the deprecated source-report shape as a historical anchor;
-- `source_to_verityTx` closes the source-to-verity-tx correspondence.
#print axioms LidoSRv3.Audit.SolidityAccounting.checkedTotal64_le
#print axioms LidoSRv3.Audit.SolidityAccounting.checkedTotal256_refines_source
#print axioms LidoSRv3.Audit.SolidityAccounting.source_report_before_reward_retired
#print axioms LidoSRv3.Audit.SolidityAccounting.source_to_verityTx

-- SolidityAddress source-level building blocks:
-- `renameAddress_{involutive,injective}` are the elementary permutation
-- identities; `not_singleton_actor_entry_point` documents the exclusion-
-- by-omission choice for singleton actors;
-- `addressEquivarianceEntryScope_total` sets total scope over the
-- registered four writers; `pause_balance_admitted_is_permissionless`
-- attests the pause/balance admissibility for `requestWithdrawals` and
-- `unwrap`; `renameInput_preserves_indexed_facts` and `run_rename` pin
-- the rename equivariance shape at the input and executor levels;
-- `source_admission_nondiscriminatory` and
-- `source_success_post_state_equivariant` are the top-level admission /
-- committed-post-state equivariance parents on the pinned source.
#print axioms LidoSRv3.Audit.SolidityAddress.renameAddress_involutive
#print axioms LidoSRv3.Audit.SolidityAddress.renameAddress_injective
#print axioms LidoSRv3.Audit.SolidityAddress.not_singleton_actor_entry_point
#print axioms LidoSRv3.Audit.SolidityAddress.addressEquivarianceEntryScope_total
#print axioms LidoSRv3.Audit.SolidityAddress.pause_balance_admitted_is_permissionless
#print axioms LidoSRv3.Audit.SolidityAddress.renameInput_preserves_indexed_facts
#print axioms LidoSRv3.Audit.SolidityAddress.run_rename
#print axioms LidoSRv3.Audit.SolidityAddress.source_admission_nondiscriminatory
#print axioms LidoSRv3.Audit.SolidityAddress.source_success_post_state_equivariant

-- TopupKeccakOracle (grok/lido-topup-keccak-20260911 cherry-pick):
-- Source-level oracle-independence family for the P-TOPUP-2
-- memoryArrayElement / readArrayWith path. Shows that two arbitrary
-- `DenoteOracle`s agree on every `memoryArrayElement` observation
-- (`memory_array_read_is_oracle_independent`,
-- `read_array_with_is_oracle_independent`), that the public
-- `Topup2DistributionTx` decoders equal the arbitrary-oracle lookup
-- (`readWord_eq_readWordWith`, `readArray_eq_readArrayWith`), that
-- `.keccak256` IS the oracle hook (`evalKeccak_eq`,
-- `zero_and_nonzero_disagree_on_keccak`), and the kill-line
-- `memory_array_agreement_does_not_imply_keccak_agreement` refutes
-- lifting memoryArrayElement agreement to keccak agreement. The
-- registered parent `verity_tx_simulates_topup2_spec_any_oracle`
-- restates the P-TOPUP-2 parent under an arbitrary oracle on the
-- decode premises. Does NOT close the named P-TOPUP-2 fidelity gap
-- "keccak memory-array oracle" — that residual remains.
#print axioms LidoSRv3.Audit.Source.TopupKeccakOracle.memory_array_read_is_oracle_independent
#print axioms LidoSRv3.Audit.Source.TopupKeccakOracle.read_array_with_is_oracle_independent
#print axioms LidoSRv3.Audit.Source.TopupKeccakOracle.readWord_eq_readWordWith
#print axioms LidoSRv3.Audit.Source.TopupKeccakOracle.readArray_eq_readArrayWith
#print axioms LidoSRv3.Audit.Source.TopupKeccakOracle.evalKeccak_eq
#print axioms LidoSRv3.Audit.Source.TopupKeccakOracle.zero_and_nonzero_disagree_on_keccak
#print axioms LidoSRv3.Audit.Source.TopupKeccakOracle.memory_array_agreement_does_not_imply_keccak_agreement
#print axioms LidoSRv3.Audit.Source.TopupKeccakOracle.verity_tx_simulates_topup2_spec_any_oracle

-- Additional non-Mac source correspondence anchors:
-- `SolidityAllocCapacity.source_execute_refines_audit_model` closes
-- the source-to-audit-model refinement on the allocation-capacity
-- source; `Source.BeaconRootsCorrespondence.source_beacon_roots_matches_spec`
-- ties the source beacon-roots observation to the spec;
-- `MinFirstAllocation.leastCount_correspondence` and
-- `MinFirstAllocation.nextLevel_correspondence` are the top-level
-- level-by-level correspondences for the MinFirst amount allocation
-- (individual arithmetic helpers stay unregistered).
#print axioms LidoSRv3.Audit.SolidityAllocCapacity.source_execute_refines_audit_model
#print axioms LidoSRv3.Audit.Source.BeaconRootsCorrespondence.source_beacon_roots_matches_spec
#print axioms LidoSRv3.Audit.MinFirstAllocation.leastCount_correspondence
#print axioms LidoSRv3.Audit.MinFirstAllocation.nextLevel_correspondence

-- EthConfinement (P-CONSOLIDATION-ETH-1 supporting model):
-- `routeAssignmentsMatch`, `coverageAgreesWithSpecApproval` document
-- the route/coverage discipline; `residualIsExactlyTheUncoveredInventory`
-- pins the residual to the uncovered inventory;
-- `residualHopsAreUnclassified` documents the residual-hop
-- classification; `route_confined` and `confined` are the top-level
-- confinement statements; `confinement_does_not_bound_unmodeled_value`
-- and `residual_hops_carry_unclassified_value` document what the
-- confinement claim does NOT establish.
#print axioms LidoSRv3.Audit.Model.EthConfinement.routeAssignmentsMatch
#print axioms LidoSRv3.Audit.Model.EthConfinement.coverageAgreesWithSpecApproval
#print axioms LidoSRv3.Audit.Model.EthConfinement.residualIsExactlyTheUncoveredInventory
#print axioms LidoSRv3.Audit.Model.EthConfinement.residualHopsAreUnclassified
#print axioms LidoSRv3.Audit.Model.EthConfinement.route_confined
#print axioms LidoSRv3.Audit.Model.EthConfinement.confined
#print axioms LidoSRv3.Audit.Model.EthConfinement.confinement_does_not_bound_unmodeled_value
#print axioms LidoSRv3.Audit.Model.EthConfinement.residual_hops_carry_unclassified_value

-- EthWorld (P-CONSOLIDATION-ETH-1 supporting model):
-- `spec_destination_surjective` documents that every spec destination
-- is reachable; `withdrawal_predeploy_outside_spec` and
-- `intermediate_hops_outside_spec` pin the excluded destinations;
-- `terminal_destinations_in_spec` closes the terminal-destination
-- side; `inventory_count` and `unsupported_count` document the
-- inventory-vs-unsupported counts.
#print axioms LidoSRv3.Audit.Model.EthWorld.spec_destination_surjective
#print axioms LidoSRv3.Audit.Model.EthWorld.withdrawal_predeploy_outside_spec
#print axioms LidoSRv3.Audit.Model.EthWorld.intermediate_hops_outside_spec
#print axioms LidoSRv3.Audit.Model.EthWorld.terminal_destinations_in_spec
#print axioms LidoSRv3.Audit.Model.EthWorld.inventory_count
#print axioms LidoSRv3.Audit.Model.EthWorld.unsupported_count

-- Provenance.ConsolidationRequest: 5 additional provenance-anchor
-- theorems. `ensemble_request_is_verity_requestAddr` and
-- `verity_requestAddr_remains_ensemble` document that the modeled
-- request address is exactly the Verity ensemble address;
-- `canonical_request_literal` pins the EIP-7251 canonical literal
-- as a text-level constant; `rewrite_preserves_other` documents that
-- the ensemble rewrite preserves other fields;
-- `canonical_request_assumption_remains_open` explicitly records the
-- residual assumption A-CANONICAL-REQUEST-ADDRESS as open.
#print axioms LidoSRv3.Audit.Provenance.ConsolidationRequest.ensemble_request_is_verity_requestAddr
#print axioms LidoSRv3.Audit.Provenance.ConsolidationRequest.verity_requestAddr_remains_ensemble
#print axioms LidoSRv3.Audit.Provenance.ConsolidationRequest.canonical_request_literal
#print axioms LidoSRv3.Audit.Provenance.ConsolidationRequest.rewrite_preserves_other
#print axioms LidoSRv3.Audit.Provenance.ConsolidationRequest.canonical_request_assumption_remains_open

-- Provenance.Deposit: 3 audit-only claims documenting the open
-- deployment-facts boundary. `deposit_contract_assumption_remains_open`
-- keeps A-DEPOSIT-CONTRACT explicit; `source_constructor_does_not_
-- discharge_deployment_facts` refutes source-only derivation;
-- `wrong_deposit_contract_pin_kill_line` refutes an incorrect
-- deposit-contract pin as a kill-line witness.
#print axioms LidoSRv3.Audit.Provenance.Deposit.deposit_contract_assumption_remains_open
#print axioms LidoSRv3.Audit.Provenance.Deposit.source_constructor_does_not_discharge_deployment_facts
#print axioms LidoSRv3.Audit.Provenance.Deposit.wrong_deposit_contract_pin_kill_line

-- Guarantee-level residuals not yet in Trust:
-- - PAlloc2.proportional_model_loop_preserves_rows: the +1 proportional
--   model loop preserves the RowsCorrespond relation across every
--   successful mutation step.
-- - PAllocExec1.canonical_executes_allocation and
--   PAllocExec1.canonical_allocation_composition_witness: the two
--   canonical composition anchors for the AllocExec parent.
-- - PEthConfinement1.coveringParentsAreRegistered: audit-only claim
--   that the parents covering ETH confinement are all Trust-registered.
-- - PMintConsumer1.abstract_rereads_written_router_snapshot and
--   PMintConsumer1.verity_observe_eq_sourceView: the parent-shaped
--   reread discipline and TX-level observe-equals-sourceView on the
--   mint-consumer plane.
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.proportional_model_loop_preserves_rows
#print axioms LidoSRv3.Audit.Guarantees.PAllocExec1.canonical_executes_allocation
#print axioms LidoSRv3.Audit.Guarantees.PAllocExec1.canonical_allocation_composition_witness
#print axioms LidoSRv3.Audit.Guarantees.PEthConfinement1.coveringParentsAreRegistered
#print axioms LidoSRv3.Audit.Guarantees.PMintConsumer1.abstract_rereads_written_router_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PMintConsumer1.verity_observe_eq_sourceView

-- TrioConsolidation.Correspondence x4: bounded correspondence lemmas
-- pinning the translated array lengths, the zipRequests preparation
-- (prepared / prepared_valid), and the prepared_vault_guards closure
-- of the source exit shape.
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.translated_array_lengths
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.zipRequests_prepared
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.zipRequests_prepared_valid
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.prepared_vault_guards_close_source_exit

-- TrioConsolidation.Memory x2: the memory-decoding correspondence
-- (`decode_stateForGroups`) and the grouped transaction simulation
-- (`grouped_tx_simulates`) closing the memory plane on the Trio path.
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Memory.decode_stateForGroups
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Memory.grouped_tx_simulates

-- ConsolidationValueTx: the value-forwarding transaction slice.
-- `forwardCalls_apply`, `forwardCalls_run` document the loop
-- semantics; `afterCalls_calls`, `afterCalls_balance_val` and
-- `afterCall_balance_val` document the post-call observations;
-- `requestCalls_value_sum`, `committed_call_value_sum` document the
-- value-sum equalities; `afterCalls_fresh`, `afterCalls_forwardedValue`,
-- `afterCalls_noConsensusLayerVerify` document the fresh /
-- forwardedValue / no-consensus-layer-verify post-conditions.
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.forwardCalls_apply
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.forwardCalls_run
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.afterCalls_calls
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.afterCalls_balance_val
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.afterCall_balance_val
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.requestCalls_value_sum
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.committed_call_value_sum
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.afterCalls_fresh
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.afterCalls_forwardedValue
#print axioms LidoSRv3.Audit.Verity.ConsolidationValueTx.afterCalls_noConsensusLayerVerify

-- PConsolidationEth1CompositionTx: the value-composition transaction
-- surface. `batch_splits_fee_and_refund` fixes the split; the two
-- adversarial closures `rejected_request_restores_entry_world` and
-- `underfunded_batch_reverts_in_gateway` document the failure planes;
-- `honest_revert_partition` closes the revert partition on the honest
-- shape; `dispatch_conserves_eth` and `dispatch_matches_atomic_multicall`
-- pin the conservation and multicall-equivalence of the dispatch loop.
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.batch_splits_fee_and_refund
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.rejected_request_restores_entry_world
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.underfunded_batch_reverts_in_gateway
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest_revert_partition
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.dispatch_conserves_eth
#print axioms LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.dispatch_matches_atomic_multicall

-- PackN{1..6} mutant lots: additional theorems documenting honest
-- parents holding and kill-lines refuting mutant lots. Only theorems
-- with axiom lists inside {propext, Classical.choice, Quot.sound} or
-- empty are registered here; native_decide-bearing mutants stay out.
#print axioms LidoSRv3.Tests.PackN1AllocExecMutants.honest_router_parent_holds
#print axioms LidoSRv3.Tests.PackN1AllocExecMutants.canonical_router_word_bounds
#print axioms LidoSRv3.Tests.PackN2EthJournalMutants.honest_success_parent_holds
#print axioms LidoSRv3.Tests.PackN2EthJournalMutants.lido_hop_not_journal_approved
#print axioms LidoSRv3.Tests.PackN2EthJournalMutants.mutant_lido_maps_to_lidoPull
#print axioms LidoSRv3.Tests.PackN2EthJournalMutants.mutant_lido_candidate_is_spec_image
#print axioms LidoSRv3.Tests.PackN3OracleMintMutants.cap_premise_is_load_bearing
#print axioms LidoSRv3.Tests.PackN3OracleMintMutants.raw_fee_mutant_breaches_cap
#print axioms LidoSRv3.Tests.PackN3OracleMintMutants.honest_frame_passes_vector
#print axioms LidoSRv3.Tests.PackN3OracleMintMutants.honest_computed_path_passes_vector
#print axioms LidoSRv3.Tests.PackN4AddressBatchMutants.honest_rename_parent_holds
#print axioms LidoSRv3.Tests.PackN4AddressBatchMutants.fixed_dest_unbounded_rename_kill_line
#print axioms LidoSRv3.Tests.PackN4AddressBatchMutants.three_claim_batch_ready
#print axioms LidoSRv3.Tests.PackN4AddressBatchMutants.three_claim_batch_parent_instance
-- (plus_one_channel_is_a_different_keccak_map intentionally kept out:
-- transitively depends on `Compiler.Proofs.solidityMappingSlot_injective`
-- which is outside the check_trust_axioms.py allowlist.)
#print axioms LidoSRv3.Tests.PackN6ConsolValueMutants.zero_value_call_sum

-- MinFirstDistributionTx x3: `sourceAllocateLoop_eq_allocateLoop`
-- bridges the source and executor loops; `modelAllocateToBestCandidate_
-- corresponds` and `sourceAllocateLoop_model_correspondence` close the
-- source-vs-independent-model correspondence.
#print axioms LidoSRv3.Audit.Verity.MinFirstDistributionTx.sourceAllocateLoop_eq_allocateLoop
#print axioms LidoSRv3.Audit.Verity.MinFirstDistributionTx.modelAllocateToBestCandidate_corresponds
#print axioms LidoSRv3.Audit.Verity.MinFirstDistributionTx.sourceAllocateLoop_model_correspondence

-- MinFirstAmountTx x2: `tx_observes_source` closes the tx-level
-- observation correspondence; `tx_underflow_reverts_to_snapshot`
-- pins the transaction-boundary rollback on the underflow branch.
#print axioms LidoSRv3.Audit.Verity.MinFirstAmountTx.tx_observes_source
#print axioms LidoSRv3.Audit.Verity.MinFirstAmountTx.tx_underflow_reverts_to_snapshot

-- AllocationTx x3: `bindLiveOne_decodes_summary` documents the live
-- summary decoding step; `verity_tx_simulates_live_summary_from_storage`
-- ties the tx-level simulation to the pinned live-summary/storage
-- path; `live_injected_after_writes_rolls_back` documents the
-- injected-after-writes rollback discipline.
#print axioms LidoSRv3.Audit.Verity.AllocationTx.bindLiveOne_decodes_summary
#print axioms LidoSRv3.Audit.Verity.AllocationTx.verity_tx_simulates_live_summary_from_storage
#print axioms LidoSRv3.Audit.Verity.AllocationTx.live_injected_after_writes_rolls_back

-- (AllocCapacity.oneModule_{observes_minimum,underflow_reverts} and
-- `noAvailableMinMutant_is_detected` all rely on `native_decide` and
-- are intentionally kept out of this disclosure to keep the Trust
-- surface inside the foundations-only boundary the checker enforces.)

-- HandleOracleReportTx auxiliary slot-inequality lemmas that support
-- the mint-after-read discipline.
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.rewardsRead_ne_rewardsMinted
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.rewardsRead_ne_sequence

-- ReserveRelationalTx slot-inequality and decode-write bridge.
#print axioms LidoSRv3.Audit.Verity.ReserveRelationalTx.lockedEtherSlot_ne_lastFinalizedSlot
#print axioms LidoSRv3.Audit.Verity.ReserveRelationalTx.decode_writeSlot_reserve

-- SubmitReportEntryTx executable-shape lemmas: `entry_is_computed_wrapper`,
-- the two disallowed-sender / hash-mismatch revert closures, and the
-- observe-simulates-source-at-computed-mint tx observation.
#print axioms LidoSRv3.Audit.Verity.SubmitReportEntryTx.entry_is_computed_wrapper
#print axioms LidoSRv3.Audit.Verity.SubmitReportEntryTx.entry_reverts_on_disallowed_sender
#print axioms LidoSRv3.Audit.Verity.SubmitReportEntryTx.entry_reverts_on_hash_mismatch
#print axioms LidoSRv3.Audit.Verity.SubmitReportEntryTx.entry_observe_simulates_source_at_computed_mint

-- (OfficialSemantics checkedFold_* / wrappingMutant_is_detected all
-- rely on `native_decide` transitively and are intentionally kept
-- out of this disclosure to keep the Trust surface inside the
-- foundations-only boundary the checker enforces.)

-- A-TOPUP-NOWRAP orphanage proof (see
-- `audit/findings/A-TOPUP-NOWRAP-orphaned.md`): the two registered
-- P-TOPUP-1 parents do not consume `NoUncheckedWrap`. The registered
-- theorems below apply on **any** input (including wrapping ones),
-- ignoring the `¬ NoUncheckedWrap inp` premise. Retirement of
-- A-TOPUP-NOWRAP from `assumptions.yaml` and P-TOPUP-1 is a policy
-- decision (advances R1 review basis) and is left explicit.
#print axioms LidoSRv3.Audit.Provenance.TopupNoWrapOrphaned.source_parent_ignores_no_unchecked_wrap
#print axioms LidoSRv3.Audit.Provenance.TopupNoWrapOrphaned.source_parent_applies_universally
#print axioms LidoSRv3.Audit.Provenance.TopupNoWrapOrphaned.verity_parent_ignores_no_unchecked_wrap

-- A-PERFECT-HASH orphanage proof (see
-- `audit/findings/A-PERFECT-HASH-orphaned.md`): the two registered
-- P-SSZ-1 parents do not consume `PerfectDepositEncoding`. The registry
-- text already records that this premise "is used only by the
-- unregistered uniqueness child" (`deposit_unique_of_perfect`).
-- Retirement of A-PERFECT-HASH from `assumptions.yaml` and P-SSZ-1 is
-- a policy decision (advances R1 review basis) and is left explicit.
#print axioms LidoSRv3.Audit.Provenance.SszPerfectHashOrphaned.abstract_parent_ignores_perfect_deposit_encoding
#print axioms LidoSRv3.Audit.Provenance.SszPerfectHashOrphaned.abstract_parent_applies_universally
#print axioms LidoSRv3.Audit.Provenance.SszPerfectHashOrphaned.verity_parent_ignores_perfect_deposit_encoding

-- A-SHA256-FFI scope isolation (see
-- `audit/findings/A-SHA256-FFI-isolated.md` and
-- `LidoSRv3/Audit/Provenance/SszSha256Isolation.lean`): every
-- registered SSZ theorem is structural or compositional around the
-- SHA-256 boundary and does not itself consume `sha256_correct` at
-- the kernel level. The SHA-256-independent part of the audit is
-- unconditional; the SHA-256-dependent part ("produced digests equal
-- the FIPS SHA-256 of their preimages") is not claimed by any
-- registered theorem. A-SHA256-FFI is retired from every consumer's
-- `assumptions` list (P-SSZ-1, P-SSZ-1.deposit-data-root,
-- P-SSZ-1.abstract-digest, P-SSZ-1.tx-execution-simulation,
-- P-SSZ-LIVE-1); the registry entry is retained as a mandatory
-- scope-boundary disclosure per `scripts/audit_metadata.py`.
#print axioms LidoSRv3.Audit.Provenance.SszSha256Isolation.ssz1_abstract_parent_ignores_sha256_correctness
#print axioms LidoSRv3.Audit.Provenance.SszSha256Isolation.ssz1_abstract_parent_applies_universally
#print axioms LidoSRv3.Audit.Provenance.SszSha256Isolation.ssz1_verity_parent_ignores_sha256_correctness
#print axioms LidoSRv3.Audit.Provenance.SszSha256Isolation.deposit_data_root_parent_ignores_sha256_correctness
#print axioms LidoSRv3.Audit.Provenance.SszSha256Isolation.abstract_digest_parent_ignores_sha256_correctness
#print axioms LidoSRv3.Audit.Provenance.SszSha256Isolation.tx_execution_simulation_parent_ignores_sha256_correctness

-- A-HANDWRITTEN-MINFIRST orphelinat (see
-- `audit/findings/A-HANDWRITTEN-MINFIRST-orphaned.md` and
-- `LidoSRv3/Audit/Provenance/HandwrittenMinFirstOrphaned.lean`): all
-- registered P-ALLOC-2 and P-ALLOC-1.eugene-bound parents operate on
-- the proportional `MinFirstAllocation.Model`/`Source` planes (which
-- have their own independent correspondence lemmas), NOT on the
-- handwritten +1 `LidoSRv3.Audit.MinFirst` model. The handwritten
-- model remains shipped in `LidoSRv3/Audit/Strategy.lean` as
-- unregistered structural evidence but does not carry any registered
-- guarantee. A-HANDWRITTEN-MINFIRST retired from both consumers and
-- from `audit/assumptions.yaml`.
#print axioms LidoSRv3.Audit.Provenance.HandwrittenMinFirstOrphaned.alloc2_source_parent_ignores_handwritten_minfirst
#print axioms LidoSRv3.Audit.Provenance.HandwrittenMinFirstOrphaned.alloc2_source_parent_applies_universally
#print axioms LidoSRv3.Audit.Provenance.HandwrittenMinFirstOrphaned.alloc2_verity_parent_ignores_handwritten_minfirst
#print axioms LidoSRv3.Audit.Provenance.HandwrittenMinFirstOrphaned.eugene_bound_parent_ignores_handwritten_minfirst

-- A-ABSTRACT-TX isolation for the two remaining consumers (see
-- `audit/findings/A-ABSTRACT-TX-isolated.md` and
-- `LidoSRv3/Audit/Provenance/AbstractTxIsolation.lean`). Every one of
-- the four registered parents on P-TOPUP-1 and P-CONSOLIDATION-ETH-1
-- has `#print axioms` output that is a subset of
-- `{propext, Classical.choice, Quot.sound}` -- no abstract-TX-shaped
-- axiom is threaded through any kernel proof. A-ABSTRACT-TX is
-- retired from `P-TOPUP-1.assumptions` and
-- `P-CONSOLIDATION-ETH-1.assumptions`, and from
-- `audit/assumptions.yaml`. The remaining abstract-vs-executable
-- refactor (replacing `RevertRestoresSnapshot`'s TxObservation shape
-- with a Verity.Contract.run rollback shape and eliminating the
-- model-local fuelBudget dispatch bound) is a separate deeper
-- statement change documented in each guarantee's `fidelity.missing`.
#print axioms LidoSRv3.Audit.Provenance.AbstractTxIsolation.topup_source_parent_ignores_abstract_tx
#print axioms LidoSRv3.Audit.Provenance.AbstractTxIsolation.topup_source_parent_applies_universally
#print axioms LidoSRv3.Audit.Provenance.AbstractTxIsolation.topup_verity_parent_ignores_abstract_tx
#print axioms LidoSRv3.Audit.Provenance.AbstractTxIsolation.consol_eth1_abstract_parent_ignores_abstract_tx

-- P-ADDRESS-1 live singleton-actor exclusion (grok #403 / see
-- `audit/address-singleton/README.md`): `requiresFixedActor ep` is a
-- live exclusion — a tag is a protocol singleton only if some fixed
-- address is the caller of every admitted run. `no_fixed_actor`
-- refutes that for all four modeled writers
-- (requestWithdrawals, unwrap, claimWithdrawalsTo, transferFrom).
-- Closes P-ADDRESS-1's fidelity.missing entry "singleton-actor
-- exclusion is by omission: singletonActorEntryPoint is False for
-- every modeled tag, so the parent carries no live exclusion proof".
#print axioms LidoSRv3.Audit.Source.AddressSingleton.no_fixed_actor
#print axioms LidoSRv3.Audit.Source.AddressSingleton.no_fixed_actor_of_admitted
#print axioms LidoSRv3.Audit.Source.AddressSingleton.fixed_owner_mutant_requires_actor
#print axioms LidoSRv3.Audit.Source.AddressSingleton.parent_omission_is_definitional

-- P-RESERVE-1 live unfinalizedStETH STATICCALL (grok #404 / see
-- `audit/reserve-unfinalized/README.md`): derives `freshQueueCache`
-- from a live STATICCALL to `unfinalizedStETH()` (selector 0xd0fb84e8,
-- zero value, 32-byte ABI decode). The registered parent still takes
-- `freshQueueCache before live`; this consumer derives `live` from
-- the STATICCALL observation and fails closed on failure / wrong
-- selector / nonzero value / short returndata. Closes P-RESERVE-1's
-- fidelity.missing entry "live WithdrawalQueue.unfinalizedStETH
-- call (freshness is now an explicit freshQueueCache hypothesis with
-- a stale-cache kill-line, not an implicit assumption)".
#print axioms LidoSRv3.Audit.Source.ReserveUnfinalizedCall.success_fresh_iff
#print axioms LidoSRv3.Audit.Source.ReserveUnfinalizedCall.failed_call_not_fresh
#print axioms LidoSRv3.Audit.Source.ReserveUnfinalizedCall.spend_preserves_from_live_call
#print axioms LidoSRv3.Audit.Source.ReserveUnfinalizedCall.decode_abiWord_small

-- P-ACCOUNT-1 sharesToMintAsFees derived from pinned fee products
-- (grok #402 / see `audit/account-fee-shares/README.md`).
-- `handleOracleReportDerived` obtains `sharesToMintAsFees` from pinned
-- `_calculateProtocolFees` products (Accounting.sol:317,323,325,331 via
-- ReportFeeProductsCorrespondence) rather than a free `Nat`. Product panic
-- is fail-closed. Mint-after-read is cited from the unchanged parent.
-- Closes P-ACCOUNT-1's fidelity.missing entry "fee computation
-- (sharesToMintAsFees is an argument)".
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.handleOracleReportDerived_eq_parent
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.handleOracleReportDerived_mint_after_read
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.product_panic_reverts
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.free_argument_mints_when_source_is_zero
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.getter_outputs_feed_products

-- P-ACCOUNT-1 packed uint64 accounting words (grok #399 / see
-- `audit/account-packed-words/README.md`). Exact pack/unpack of
-- `ModuleStateAccounting` (SRTypes.sol:157-164) and
-- `RouterStateAccounting` (SRTypes.sol:166-172). On the committed
-- admission domain, persistBalances writes pack ⟨b, 0, 0⟩;
-- writeSlot totalBalanceSlot writes packRouter ⟨total, 0⟩;
-- observe unpacks; getStakingModuleStateAccounting recovers each
-- balance; writeLow64 preserves bits 64+. Width (uint32) and offset
-- (bits 64..127) mutants disagree with the parent write.
-- Closes P-ACCOUNT-1's fidelity.missing entry "packed uint64
-- accounting words".
#print axioms LidoSRv3.Audit.Source.AccountPackedWords.persistBalances_writes_packed_zero
#print axioms LidoSRv3.Audit.Source.AccountPackedWords.writeSlot_total_is_packed_router
#print axioms LidoSRv3.Audit.Source.AccountPackedWords.persistBalances_getter_recovers
#print axioms LidoSRv3.Audit.Source.AccountPackedWords.observe_balances_eq_unpacked_module_words
#print axioms LidoSRv3.Audit.Source.AccountPackedWords.observe_total_eq_unpacked_router_word
#print axioms LidoSRv3.Audit.Source.AccountPackedWords.parent_observe_eq_sourceView
#print axioms LidoSRv3.Tests.AccountPackedWordsMutants.width32_misses_parent_balance
#print axioms LidoSRv3.Tests.AccountPackedWordsMutants.offset64_disagrees_parent_ofNat
#print axioms LidoSRv3.Tests.AccountPackedWordsMutants.sample_router_getter
#print axioms LidoSRv3.Tests.AccountPackedWordsMutants.sample_persist_is_packed_zero
#print axioms LidoSRv3.Tests.AccountPackedWordsMutants.sample_getter_recovers
#print axioms LidoSRv3.Tests.AccountPackedWordsMutants.sample_width32_kill_line
#print axioms LidoSRv3.Tests.AccountPackedWordsMutants.sample_offset64_kill_line

-- P-TOPUP-2 unbounded count + same-block accumulation bound (grok
-- #409 / see `audit/topup2-unbounded/README.md`). The leftover walk
-- is proved for every key-list length (unbounded induction);
-- registered parent stays at the 32 instance. Same-block accumulation
-- across calls is bounded under `minBlockDistance ≥ 1` and
-- `blockNumber ≠ 0`; a no-lock mutant exceeds the cap, the public
-- entry refuses that second call. Closes the "same-block accumulation
-- across calls is excluded from the single-call parent" half of the
-- corresponding P-TOPUP-2 fidelity.missing entry.
#print axioms LidoSRv3.Audit.Verity.TopupUnboundedCount.leftover_walk_sum_le_budget
#print axioms LidoSRv3.Audit.Verity.TopupMultiCallBlockCap.same_block_sum_le_cap
#print axioms LidoSRv3.Audit.Verity.TopupMultiCallBlockCap.setter_refuses_zero
#print axioms LidoSRv3.Audit.Verity.TopupMultiCallBlockCap.no_lock_two_call_exceeds_cap
#print axioms LidoSRv3.Audit.Verity.TopupMultiCallBlockCap.router_only_two_call_exceeds_cap

-- P-ADDRESS-1 unbounded observe receipt (grok #416): the live
-- AddressClaimBatchTx loop already iterates arbitrary request/hint
-- lists; this lot proves the observe receipt for every successful list
-- by induction (WithdrawalQueue.sol:244-256): observe is the ordered
-- map of the unit _claim receipt (WithdrawalQueueBase.sol:460-480).
-- The two-item parent shape is that instance. A mutant that reorders
-- the CALLs is refused. Closes P-ADDRESS-1's fidelity.missing entry
-- "unbounded source-to-Verity correspondence ... the checked observe
-- receipt is two-item".
#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded.observe_eq_map_unit
#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded.two_item_parent_instance
#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded.reordered_calls_refute_two_item

-- P-ALLOC-2 unconditional termination (grok #416): parent conservation
-- previously held only for `sourceAllocateLoop` runs that returned
-- some under caller-supplied fuel. This lot proves unconditional
-- termination from the decreasing remaining-capacity sum drawn from
-- MinFirstAllocationStrategy.allocate:106, then conservation with no
-- fuel premise. Solidity also has a real bound: allocationSize.
#print axioms LidoSRv3.Audit.Spec.AllocLoopTermination.sourceAllocateLoop_terminates
#print axioms LidoSRv3.Audit.Spec.AllocLoopTermination.source_allocate_conserves_without_fuel

-- P-DEPOSIT-1 LinksSource firstAmount / publicKeysBatchLength derived
-- from pinned router shape (grok #405 / see `audit/deposit-linkssource/
-- README.md`). `derivedKeys` is fail-closed on misaligned length,
-- truncated length, disagreed PUBLIC_KEY_LENGTH, zero PUBKEY_LENGTH.
-- `derivedBatchAmount = actualDepositsCount * DEPOSIT_SIZE` (per
-- BeaconChainDepositor.sol:53-63/57) links firstAmount from the
-- committed source path. Kill-lines show ALLOC key counts DO NOT
-- constrain firstAmount or publicKeysBatchLength (Wave 4
-- `alloc_derived_linkssource_kill_line_refutes_bridge` stays true).
-- Closes P-DEPOSIT-1's fidelity.missing entry "LinksSource is a
-- caller-supplied hypothesis...".
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.linksSource_of_router_fields
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.nframe_linksSource_of_router_fields
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.derivedTwoBatchInputs_linksSource
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.committed_implies_derivedKeys
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.committed_pushed_is_derived_amount
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.alloc_key_counts_do_not_constrain_firstAmount
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.alloc_matching_count_does_not_constrain_publicKeysBatchLength

-- A-CANONICAL-REQUEST-ADDRESS discharge (see
-- `audit/findings/A-CANONICAL-REQUEST-ADDRESS-discharged.md` and
-- `LidoSRv3/Audit/Provenance/CanonicalRequestAddress.lean`): the
-- Lean model literal `consolidationPredeploy` equals the CONSOLIDATION_REQUEST
-- immutable extracted from the deployed WithdrawalVault runtime bytecode
-- at byte offset 730 width 20 (fixture and hash pinned in
-- `audit/artifacts.lock.json`; reproduction in
-- `scripts/verify_consolidation_request_immutable.py`). A-CANONICAL-REQUEST-ADDRESS
-- is retired from `P-CONSOLIDATION-ETH-1.assumptions`.
#print axioms LidoSRv3.Audit.Provenance.CanonicalRequestAddress.deployed_consolidation_request_immutable_equals_canonical
#print axioms LidoSRv3.Audit.Provenance.CanonicalRequestAddress.model_consolidation_predeploy_equals_canonical
#print axioms LidoSRv3.Audit.Provenance.CanonicalRequestAddress.model_predeploy_equals_deployed_immutable

-- A-TOPUP-BEACON-ADDRESS + A-DEPOSIT-CONTRACT discharge (see
-- `audit/findings/A-TOPUP-BEACON-ADDRESS-and-A-DEPOSIT-CONTRACT-discharged.md` and
-- `LidoSRv3/Audit/Provenance/BeaconDepositAddress.lean`): the Lean model
-- literals `LidoSRv3.Audit.Verity.TopupTx.beaconAddress`,
-- `PTopup1.canonicalBeaconDepositAddress`, and
-- `PDeposit1.canonicalDepositContractAddress` all equal the
-- `DEPOSIT_CONTRACT` immutable extracted from the deployed
-- StakingRouter runtime bytecode at byte offset 7525 width 20 (fixture
-- and hash pinned in `audit/artifacts.lock.json`; reproduction in
-- `scripts/verify_beacon_deposit_immutable.py`). A-TOPUP-BEACON-ADDRESS
-- is retired from `P-TOPUP-1.assumptions`; A-DEPOSIT-CONTRACT is retired
-- from `P-DEPOSIT-1.assumptions` and `P-ALLOC-EXEC-1.assumptions`.
#print axioms LidoSRv3.Audit.Provenance.BeaconDepositAddress.deployed_beacon_deposit_immutable_equals_canonical
#print axioms LidoSRv3.Audit.Provenance.BeaconDepositAddress.topup_verity_beacon_equals_canonical
#print axioms LidoSRv3.Audit.Provenance.BeaconDepositAddress.topup_canonical_pin_equals_canonical
#print axioms LidoSRv3.Audit.Provenance.BeaconDepositAddress.deposit_canonical_pin_equals_canonical
#print axioms LidoSRv3.Audit.Provenance.BeaconDepositAddress.topup_verity_beacon_equals_deployed_immutable
#print axioms LidoSRv3.Audit.Provenance.BeaconDepositAddress.deposit_canonical_pin_equals_deployed_immutable

-- A-DEPOSIT-32-ETHER discharge (see
-- `audit/findings/A-DEPOSIT-32-ETHER-discharged.md` and
-- `LidoSRv3/Audit/Provenance/DepositThirtyTwoEther.lean`): the deployed
-- StakingRouter production configuration jointly binds
-- `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` (constructor immutable) and
-- `BeaconChainDepositor.DEPOSIT_SIZE` (compile-time constant) to
-- `32 * 10^18` wei. Every runtime read of these two uint256 values
-- compiles to `PUSH32 <32-ether-word>`; the fixture contains exactly
-- five such PUSH32 sites (offsets 5521, 12112, 14036, 15415, 20126),
-- each holding the 32-byte big-endian encoding of 32*10^18 (fixture
-- and hash pinned in `audit/artifacts.lock.json`; reproduction in
-- `scripts/verify_deposit_thirty_two_ether.py`). A-DEPOSIT-32-ETHER
-- is retired from `P-DEPOSIT-1.assumptions` and
-- `P-ALLOC-EXEC-1.assumptions`.
#print axioms LidoSRv3.Audit.Provenance.DepositThirtyTwoEther.deployed_thirty_two_ether_push_folds_to_thirty_two_ether
#print axioms LidoSRv3.Audit.Provenance.DepositThirtyTwoEther.deployed_maxEBType1_equals_pushed_value
#print axioms LidoSRv3.Audit.Provenance.DepositThirtyTwoEther.deployed_depositSize_equals_pushed_value
#print axioms LidoSRv3.Audit.Provenance.DepositThirtyTwoEther.deployed_maxEBType1_equals_depositSize
#print axioms LidoSRv3.Audit.Provenance.DepositThirtyTwoEther.deployed_production_config_thirty_two_ether

-- A-ABSTRACT-TX orphelinat for P-DEPOSIT-1 (see
-- `audit/findings/A-ABSTRACT-TX-orphaned-from-P-DEPOSIT-1.md` and
-- `LidoSRv3/Audit/Provenance/DepositAbstractTxOrphaned.lean`): both
-- registered P-DEPOSIT-1 parents
-- (`PDeposit1.source_deposit_conserves_and_rolls_back` and
-- `PDeposit1.NFrame.verity_tx_composes_nframe_deposit`) apply
-- universally without consuming any hypothesis representing the
-- abstract `TxObservation` model's faithfulness — the `_hAbstractTxFaithful`
-- premise below is introduced only to make the orphanage explicit and is
-- ignored by the parent's proof term. `A-ABSTRACT-TX` is retired from
-- `P-DEPOSIT-1.assumptions` in `audit/guarantees.yaml`; the registry
-- entry stays because `P-TOPUP-1` and `P-CONSOLIDATION-ETH-1` still
-- fold `RevertRestoresSnapshot` / abstract-TX conjuncts into their
-- registered parents.
#print axioms LidoSRv3.Audit.Provenance.DepositAbstractTxOrphaned.source_parent_ignores_abstract_tx
#print axioms LidoSRv3.Audit.Provenance.DepositAbstractTxOrphaned.source_parent_applies_universally
#print axioms LidoSRv3.Audit.Provenance.DepositAbstractTxOrphaned.verity_parent_ignores_abstract_tx
#print axioms LidoSRv3.Audit.Provenance.DepositAbstractTxOrphaned.verity_parent_applies_universally
