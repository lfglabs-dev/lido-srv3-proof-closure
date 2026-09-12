import Lake
open Lake DSL

package accountAddress where
  srcDir := "."

@[default_target]
lean_lib AccountAddress where
  roots := #[`PAccount1, `ReportWriteFee, `StETHMintShares, `ReportFeeMint, `PAddress1, `PAddress1Physical,
    `Tests.Verity.PAccount1Test, `Tests.Verity.ReportWriteFeeTest,
    `Tests.Verity.StETHMintSharesTest,
    `Tests.Verity.PAddress1Test, `Tests.Verity.PAddress1PhysicalTest]
