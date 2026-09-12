import LidoSRv3.Audit.Source.DepositLinksSource
import LidoSRv3.Audit.Verity.DepositNFrameTx

/-! P-DEPOSIT-1 router-derived `firstAmount` / `publicKeysBatchLength` vectors. -/

namespace LidoSRv3.Tests.DepositLinksSourceMutants

open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Guarantees.PDeposit1
open LidoSRv3.Audit.Verity.DepositParentTx
open LidoSRv3.Audit.Source.DepositLinksSource

private def cfg : SourceDepositConfig := canonicalSourceConfig
private def inp : SourceDepositInput := canonicalSourceInput

/-- Happy path: 240-byte batch is 5 keys of `PUBKEY_LENGTH = 48`
    (`StakingRouter.sol:966-967` / BCD:43-45). -/
example : derivedKeys cfg 240 = some 5 := by native_decide

example : derivedKeys cfg inp.publicKeysBatchLength = some 5 := by native_decide

/-- Canonical 2+3 split with depositor-loop wei `64` and `96`. -/
example : routerShapedAmount cfg batchA :=
  (routerShapedAmount_iff cfg batchA).mpr (by decide)

example : routerShapedAmount cfg batchB :=
  (routerShapedAmount_iff cfg batchB).mpr (by decide)

example : LinksSource cfg inp canonicalInputs :=
  linksSource_of_router_fields cfg inp canonicalInputs
    (by decide)
    (by decide)
    ((routerShapedAmount_iff cfg canonicalInputs.first).mpr (by decide))
    ((routerShapedAmount_iff cfg canonicalInputs.second).mpr (by decide))

/-- Fail-closed constructor overwrites wei and yields `LinksSource`. -/
example : derivedTwoBatchInputs cfg inp canonicalInputs =
    some canonicalInputs := by native_decide

example : LinksSource cfg inp canonicalInputs :=
  derivedTwoBatchInputs_linksSource
    (show derivedTwoBatchInputs cfg inp canonicalInputs = some canonicalInputs
      from by native_decide)

/-- StakingRouter.sol:966 `WrongPubkeyLength`: 145 is not a multiple of 48. -/
example : derivedKeys cfg 145 = none := by native_decide

example : derivedTwoBatchInputs cfg
    { inp with publicKeysBatchLength := 145 } canonicalInputs = none := by
  native_decide

/-- Truncating `241 / 48 = 5` matches ALLOC key composition but fails
    alignment, so the derived consumer refuses the link. -/
example : actualDepositsCount cfg { inp with publicKeysBatchLength := 241 } = 5 := by
  decide

example : derivedKeys cfg 241 = none := by native_decide

example : derivedTwoBatchInputs cfg
    { inp with publicKeysBatchLength := 241 } canonicalInputs = none := by
  native_decide

/-- One 48-byte key cannot witness the 2+3 ALLOC split. -/
example : derivedKeys cfg 48 = some 1 := by native_decide

example : derivedTwoBatchInputs cfg
    { inp with publicKeysBatchLength := 48 } canonicalInputs = none := by
  native_decide

/-- Free wei `65 ≠ 2 * 32` is not the depositor loop (`BeaconChainDepositor.sol:57`). -/
example : ¬ routerShapedAmount cfg { batchA with amount := 65 } := by
  intro h
  exact absurd ((routerShapedAmount_iff cfg _).mp h) (by decide)

/-- Skewed `(65, 95)` still satisfies `valueMatches` (`160 = 5 * 32`) but
    is not router-shaped, so `LinksSource.firstAmount` fails. -/
private def skewed : Inputs :=
  { canonicalInputs with
    first := { batchA with amount := 65 }
    second := { batchB with amount := 95 } }

example : (skewed.first.amount.val + skewed.second.amount.val
    = (skewed.first.keys.val + skewed.second.keys.val) * cfg.depositSize) := by
  decide

example : ¬ routerShapedAmount cfg skewed.first := by
  intro h
  exact absurd ((routerShapedAmount_iff cfg _).mp h) (by decide)

/-- The constructor repairs skewed wei: it overwrites amounts with the
    depositor-loop products. -/
example : derivedTwoBatchInputs cfg inp skewed = some canonicalInputs := by
  native_decide

/-- `PUBLIC_KEY_LENGTH ≠ PUBKEY_LENGTH` fails BCD:43-45 even when aligned. -/
private def skewedLengths : SourceDepositConfig :=
  { cfg with publicKeyLength := 32 }

example : derivedKeys skewedLengths 240 = none := by native_decide

/-- Zero `PUBKEY_LENGTH` is a modulo-by-zero panic, not a key count. -/
example : derivedKeys { cfg with pubkeyLength := 0 } 240 = none := by native_decide

/-- Committed canonical run determines both fields. -/
example : run cfg inp = .committedDeposits 5 160 160 0 := by decide

example : derivedKeys cfg inp.publicKeysBatchLength = some 5 :=
  committed_implies_derivedKeys
    (show run cfg inp = .committedDeposits 5 160 160 0 from by decide)

example : derivedBatchAmount cfg 5 = 160 := by
  simp [derivedBatchAmount_eq, cfg, canonicalSourceConfig]

/-- NFrame: the same two router-shaped legs yield `NFrame.LinksSource`. -/
private def nInputs : LidoSRv3.Audit.Verity.DepositNFrameTx.Inputs :=
  { authorized := true, moduleActive := true, allocationValid := true,
    lidoCallOk := true, depositSize := 32, lido := 101, module := 202, beacon := 303,
    batches := [batchA, batchB] }

example : NFrame.LinksSource cfg inp nInputs :=
  nframe_linksSource_of_router_fields cfg inp nInputs
    (by decide)
    (by decide)
    (by
      intro batch hMem
      have hCases : batch = batchA ∨ batch = batchB := by
        simpa [nInputs] using hMem
      rcases hCases with rfl | rfl
      · exact (routerShapedAmount_iff cfg batchA).mpr (by decide)
      · exact (routerShapedAmount_iff cfg batchB).mpr (by decide))

#print axioms LidoSRv3.Audit.Source.DepositLinksSource.linksSource_of_router_fields
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.nframe_linksSource_of_router_fields
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.derivedTwoBatchInputs_linksSource
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.committed_implies_derivedKeys
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.committed_pushed_is_derived_amount
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.alloc_key_counts_do_not_constrain_firstAmount
#print axioms LidoSRv3.Audit.Source.DepositLinksSource.alloc_matching_count_does_not_constrain_publicKeysBatchLength

end LidoSRv3.Tests.DepositLinksSourceMutants
