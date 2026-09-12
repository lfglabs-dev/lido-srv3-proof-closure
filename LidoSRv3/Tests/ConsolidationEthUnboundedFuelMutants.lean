import LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx
import LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal

/-!
Mutants for the derived unbounded P-CONSOLIDATION-ETH-1 success consumer.

This file does not import `ConsolidationEthUnboundedFuel` (that Verity module
is additive and is not yet a `lakefile.lean` `.one` target).  `runWithFuel`
here is the same `step` call the Verity file names; the required kill-line is
fuel truncated to `batchSize + 3`.

See `audit/eth1-unbounded-fuel/README.md` for the Spark raccord that would
let this file import the Verity module directly.
-/

namespace LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants

open _root_.Verity
open _root_.Verity.MultiContract
open LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx
open LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal

/-- Same parametric dispatcher as
`Verity.ConsolidationEthUnboundedFuel.runWithFuel`. -/
def runWithFuel (fuel : Nat) (w : Wiring) (msgValue batchSize feePerRequest : Nat) :
    TxOutcome :=
  let before := initial msgValue feePerRequest
  step (nodeAt w) before fuel before
    [{ caller := senderAddr, callee := busAddr, site := rootSite msgValue batchSize }]
    0 []

def successShape (mv n fee : Nat) : TxView :=
  ⟨.success, n + 3 + (if mv - n * fee = 0 then 0 else 1),
    ⟨0, 0, 0, 0, 0, n * fee, mv - n * fee⟩⟩

/-- Fuel `batchSize + 3` exhausts on every funded positive-remainder batch. -/
theorem truncated_fuel_batchSize_plus_three_exhausted (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hrem : mv - n * fee ≠ 0) :
    (runWithFuel (n + 3) honest mv n fee).control = .exhausted := by
  have hbus : n + 3 = n + 2 + 1 := by omega
  have hgw : n + 2 = n + 1 + 1 := by omega
  unfold runWithFuel
  rw [hbus]
  rw [hop_bus mv n fee (n + 2) 0 [] hmv hnM]
  rw [hgw]
  rw [hop_gateway mv n fee (n + 1) 1 [busCompiled mv n] hpos hmv hnM hnf hle]
  rw [hop_vault mv n fee n 2 _ hmv hnM hfee hnf hle]
  rw [show (2 + 1 : Nat) = 3 from rfl]
  conv =>
    lhs
    arg 1
    arg 3
    rw [show n = n + 0 from (Nat.add_zero n).symm]
  rw [request_phase n (initial mv fee) (vaultPostWorld mv n fee) fee 0 3
    [vaultCompiled n fee, gwCompiled mv n, busCompiled mv n]
    (if mv - n * fee = 0 then [] else [refundPending mv n fee])
    (request_phase_guard mv n fee hfee hnf)]
  rw [if_neg hrem]
  simp only [step]

theorem truncated_fuel_must_be_refused (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hrem : mv - n * fee ≠ 0) :
    observe (runWithFuel (n + 3) honest mv n fee) ≠ successShape mv n fee := by
  have hctl :=
    truncated_fuel_batchSize_plus_three_exhausted mv n fee hpos hmv hnM hfee hnf hle hrem
  intro heq
  have hsucc : (runWithFuel (n + 3) honest mv n fee).control = .success := by
    have hobs : observe (runWithFuel (n + 3) honest mv n fee) = successShape mv n fee := heq
    simp [observe, successShape] at hobs
    exact hobs.1
  cases hctl.symm.trans hsucc

/-- Concrete funded remainder: `(10, 2, 3)` needs 6 frames and is refused at 5. -/
theorem numeral_truncated_fuel_batchSize_plus_three_exhausted :
    (runWithFuel 5 honest 10 2 3).control = .exhausted :=
  truncated_fuel_batchSize_plus_three_exhausted 10 2 3
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)
    (by decide)

theorem numeral_truncated_fuel_batchSize_plus_three_refused :
    observe (runWithFuel 5 honest 10 2 3) ≠ successShape 10 2 3 :=
  truncated_fuel_must_be_refused 10 2 3
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)
    (by decide)

/-- The parent's `batchSize + 4 ≤ 32` is not the unbounded statement: it is
false at the funded 29-request tuple the registered exhaustion arm uses. -/
theorem parent_fuel_premise_excludes_batch_29 :
    ¬ (29 + 4 ≤ fuelBudget) := by
  decide

end LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants

#print axioms LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants.truncated_fuel_must_be_refused
#print axioms LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants.numeral_truncated_fuel_batchSize_plus_three_exhausted
#print axioms LidoSRv3.Tests.ConsolidationEthUnboundedFuelMutants.parent_fuel_premise_excludes_batch_29
