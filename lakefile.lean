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
    .one `LidoSRv3.Audit.Verity.DepositLedgerTx,
    .one `LidoSRv3.Audit.Verity.DepositNFrameTx,
    .one `LidoSRv3.Audit.Verity.DepositParentTx,
    .one `LidoSRv3.Audit.Verity.DepositRollback,
    .one `LidoSRv3.Audit.Verity.DepositTx,
    .one `LidoSRv3.Audit.Verity.HandleOracleReportTx,
    .one `LidoSRv3.Audit.Verity.MinFirstAmountTx,
    .one `LidoSRv3.Audit.Verity.MinFirstDistributionTx,
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

/-- Trust inspection. Imports production and test modules; not part of the facade. -/
lean_lib «LidoSRv3Audit» where
  roots := #[`LidoSRv3.Audit.Trust]

/-- Superseded P1–P15 lane. Not a default target. -/
lean_lib «LidoSRv3Legacy» where
  globs := #[.submodules `LidoSRv3.Legacy]
