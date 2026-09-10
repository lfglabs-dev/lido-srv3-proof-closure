import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"
  testDriver := "LidoSRv3Test"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"e977aaad6e1a9e92e0132d41b3d33a14135a4d46"

/-- Stable definitions and public guarantees. Does not compile Tests, Legacy, or Trust. -/
@[default_target]
lean_lib «LidoSRv3» where
  globs := #[
    .one `LidoSRv3,
    .submodules `LidoSRv3.Audit.Common,
    .submodules `LidoSRv3.Audit.Guarantees,
    .submodules `LidoSRv3.Audit.Model,
    .submodules `LidoSRv3.Audit.Provenance,
    .submodules `LidoSRv3.Audit.Source,
    .andSubmodules `LidoSRv3.Audit.Spec,
    .one `LidoSRv3.Audit.AddressEquivariance,
    .one `LidoSRv3.Audit.AllGuarantees,
    .one `LidoSRv3.Audit.Allocation,
    .one `LidoSRv3.Audit.Arithmetic,
    .one `LidoSRv3.Audit.MinFirstAllocation,
    .one `LidoSRv3.Audit.Ssz,
    .one `LidoSRv3.Audit.SszDepositEquivalence,
    .one `LidoSRv3.Audit.Strategy,
    .one `LidoSRv3.Audit.StrategyProofs,
    .one `LidoSRv3.Audit.Trace,
    -- Immediate Verity modules only. `.submodules Verity` is recursive and
    -- would swallow `Audit/Verity/Tests`, which belongs to LidoSRv3Test.
    .one `LidoSRv3.Audit.Verity.AddressAdmission,
    .one `LidoSRv3.Audit.Verity.AddressClaimBatchTx,
    .one `LidoSRv3.Audit.Verity.AddressTransferTx,
    .one `LidoSRv3.Audit.Verity.AddressTx,
    .one `LidoSRv3.Audit.Verity.AddressYulInterface,
    .one `LidoSRv3.Audit.Verity.AllocCapacity,
    .one `LidoSRv3.Audit.Verity.AllocCapacityPhase3,
    .one `LidoSRv3.Audit.Verity.AllocationTx,
    .one `LidoSRv3.Audit.Verity.BeaconRootsTx,
    .one `LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel,
    .one `LidoSRv3.Audit.Verity.ConsolidationCallFragment,
    .one `LidoSRv3.Audit.Verity.ConsolidationFee,
    .one `LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess,
    .one `LidoSRv3.Audit.Verity.ConsolidationTx,
    .one `LidoSRv3.Audit.Verity.ConsolidationValueTx,
    .submodules `LidoSRv3.Audit.Verity.TrioConsolidation,
    .one `LidoSRv3.Audit.Verity.DepositLedgerTx,
    .one `LidoSRv3.Audit.Verity.DepositNFrameTx,
    .one `LidoSRv3.Audit.Verity.DepositParentTx,
    .one `LidoSRv3.Audit.Verity.DepositRollback,
    .one `LidoSRv3.Audit.Verity.DepositTx,
    .one `LidoSRv3.Audit.Verity.HandleOracleReportTx,
    .one `LidoSRv3.Audit.Verity.MinFirstAmountTx,
    .one `LidoSRv3.Audit.Verity.MinFirstDistributionTx,
    .one `LidoSRv3.Audit.Verity.MinFirstSourceEntry,
    .one `LidoSRv3.Audit.Verity.OfficialSemantics,
    .one `LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx,
    .one `LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal,
    .one `LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversalRevert,
    .one `LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx,
    .one `LidoSRv3.Audit.Verity.PConsolidationEth1RequestTx,
    .one `LidoSRv3.Audit.Verity.ReserveRelationalTx,
    .one `LidoSRv3.Audit.Verity.SszAbstractDigest,
    .one `LidoSRv3.Audit.Verity.SszEncodingTx,
    .one `LidoSRv3.Audit.Verity.SszTxSimulation,
    .one `LidoSRv3.Audit.Verity.SubmitReportEntryTx,
    .one `LidoSRv3.Audit.Verity.Topup2DistributionTx,
    .one `LidoSRv3.Audit.Verity.Topup2Tx,
    .one `LidoSRv3.Audit.Verity.TopupBeaconFundedTx,
    .one `LidoSRv3.Audit.Verity.TopupFundedSourceTx,
    .one `LidoSRv3.Audit.Verity.TopupHybrid,
    .one `LidoSRv3.Audit.Verity.TopupPackedStorage,
    .one `LidoSRv3.Audit.Verity.TopupParent,
    .one `LidoSRv3.Audit.Verity.TopupRollback,
    .one `LidoSRv3.Audit.Verity.TopupTx,
    .one `LidoSRv3.Audit.Verity.VaultEthTx
  ]

/-- Mutants, vectors, nested Verity tests, and leftover regressions. -/
lean_lib «LidoSRv3Test» where
  globs := #[
    .submodules `LidoSRv3.Tests,
    .submodules `LidoSRv3.Audit.Verity.Tests,
    .one `LidoSRv3.Audit.Regression.AllocCapacityLegacy
  ]

/-- Narrow DEPOSIT actual-callee necessary-success check; kept outside the
default package while P-DEPOSIT-1 integration consumes the theorem. -/
lean_lib «TrioDepositCommitted» where
  roots := #[`audit.trio.deposit.LiveBeaconCommitted,
    `audit.trio.deposit.Tests.Verity.LiveBeaconCommitted]
  globs := #[.one `audit.trio.deposit.Deposit,
    .one `audit.trio.deposit.RouterDeposit,
    .one `audit.trio.deposit.WithdrawDepositableEther,
    .one `audit.trio.deposit.LiveBeacon,
    .one `audit.trio.deposit.WithdrawalLedger,
    .one `audit.trio.deposit.WithdrawalLedgerMinimal,
    .one `audit.trio.deposit.PhysicalMetadataLedger,
    .one `audit.trio.deposit.PhysicalMetadata,
    .one `audit.trio.deposit.LiveBeaconCommitted,
    .one `audit.trio.deposit.Tests.Verity.LiveBeaconCommitted]

/-- Trust inspection. Imports production and test modules; not part of the facade. -/
lean_lib «LidoSRv3Audit» where
  roots := #[`LidoSRv3.Audit.Trust]

/-- Isolated accounting/address slices, with kernel-checked regression proofs. -/
lean_lib «AccountAddressChecks» where
  srcDir := "audit/trio/account-address"
  roots := #[`PAccount1, `ReportWriteFee, `StETHMintShares, `ReportFeeMint, `ReportFeeCastInvariant, `PAddress1, `PAddress1Physical,
    `Tests.Verity.PAccount1Test, `Tests.Verity.ReportWriteFeeTest,
    `Tests.Verity.StETHMintSharesTest, `Tests.Verity.ReportFeeMintTest,
    `Tests.Verity.ReportFeeCastInvariantTest,
    `Tests.Verity.PAddress1Test, `Tests.Verity.PAddress1PhysicalTest]

/-- Cross-check the staged indexed parent against the integrated source/ABI parent. -/
lean_lib «TrioIntegrationChecks» where
  globs := #[
    .submodules `audit.trio.consolidation,
    .one `audit.trio.MainGuaranteeChecks,
    .one `audit.trio.integration.IndexedParentBridge,
    .one `audit.trio.alloc2.composition.Composition,
    .one `audit.trio.alloc2.composition.LibraryABI,
    .one `audit.trio.alloc2.composition.AllocationMemoryBridge,
    .one `audit.trio.alloc2.composition.MemoryExtent,
    .one `audit.trio.alloc2.composition.Parent,
    .one `audit.trio.alloc2.composition.ParentErrors,
    .one `audit.trio.alloc2.composition.ParentInversion,
    .one `audit.trio.alloc2.composition.ProducerMemory,
    .one `audit.trio.alloc2.composition.ProducerMemoryVectors,
    .one `audit.trio.alloc2.composition.MemoryWrite,
    .one `audit.trio.alloc2.composition.MemoryWriteVectors,
    .one `audit.trio.alloc2.composition.IndexedMemory,
    .one `audit.trio.alloc2.composition.ByteMemory,
    .one `audit.trio.alloc2.composition.ByteFrame,
    .one `audit.trio.alloc2.composition.ByteIndexed,
    .one `audit.trio.alloc2.composition.ByteInitialize,
    .one `audit.trio.alloc2.composition.ByteProducer,
    .one `audit.trio.alloc2.composition.ByteVectors,
    .one `audit.trio.alloc2.runtime.ByteMemory,
    .one `audit.trio.alloc2.runtime.ByteCoverage,
    .one `audit.trio.alloc2.runtime.ByteLoop,
    .one `audit.trio.alloc2.runtime.ByteInitialize,
    .one `audit.trio.alloc2.runtime.ByteVectors,
    .one `audit.trio.alloc2.runtime.ByteABI,
    .one `audit.trio.alloc2.runtime.ByteABIFrame,
    .one `audit.trio.alloc2.runtime.ByteABIProducer,
    .one `audit.trio.alloc2.runtime.ByteABIVectors,
    .one `audit.trio.alloc2.runtime.ByteWordCopy,
    .one `audit.trio.alloc2.composition.ParentPostconditions,
    .one `audit.trio.alloc2.composition.ParentVectors,
    .one `audit.trio.alloc2.composition.MemoryVectors,
    .one `audit.trio.alloc2.composition.LibraryABIVectors
  ]

/-- Superseded P1–P15 lane. Not a default target. -/
lean_lib «LidoSRv3Legacy» where
  globs := #[.submodules `LidoSRv3.Legacy]
