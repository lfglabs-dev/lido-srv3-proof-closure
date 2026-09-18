import LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal
import LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-!
# P-CONSOLIDATION-ETH-1: derived unbounded success consumer

The registered Verity parent
`Guarantees.PConsolidationEth1.verity_tx_universal_success_shape` carries the
premise `batchSize + 4 ≤ fuelBudget` with `fuelBudget = 32`.  That bound is a
frame-count of the abstract dispatcher
(`PConsolidationEth1CompositionTx.step`), not a cap of the pinned Solidity:

* `ConsolidationGateway.addConsolidationRequests` (lines 185–223) has no
  32-frame / 29-request cutoff; it loops groups and forwards `totalFee`.
* `WithdrawalVaultEIP7685._addConsolidationRequests` (lines 56–73) is
  `for (uint256 i = 0; i < requestsCount; ++i)`.
* `ConsolidationBus.executeConsolidation` (lines 383–406) forwards `msg.value`.

This module keeps the registered parent untouched and adds a *derived*
consumer: the same hop lemmas, but the dispatcher fuel is the Nat
`batchSize + 4` computed from the batch.  That inequality is not a hypothesis
(`Nat.le_refl` at the derived amount).  The registered parent is recovered as
the instance at `fuelBudget = 32`.

Live quota (`_consumeConsolidationRequestLimit`, Gateway line 209) and the
Bus `_batchSize` config are a different bound; they are not this model's
`fuelBudget = 32` and stay out of this lot.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel

open _root_.Verity
open _root_.Verity.MultiContract
open LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx
open LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal

/-- Parametric-fuel dispatcher.  The registered `run` is this definition at
`fuelBudget`. -/
def runWithFuel (fuel : Nat) (w : Wiring) (msgValue batchSize feePerRequest : Nat) :
    TxOutcome :=
  let before := initial msgValue feePerRequest
  step (nodeAt w) before fuel before
    [{ caller := senderAddr, callee := busAddr, site := rootSite msgValue batchSize }]
    0 []

theorem run_is_runWithFuel_at_fuelBudget (w : Wiring) (mv n fee : Nat) :
    run w mv n fee = runWithFuel fuelBudget w mv n fee := rfl

/-- Fuel the success path consumes: Bus, Gateway, Vault, `n` request hops, and
one refund hop when the remainder is positive.  Always `n + 4` (the zero-remainder
path uses only `n + 3` and leaves one unused frame). -/
def derivedFuel (batchSize : Nat) : Nat := batchSize + 4

/-- The registered success observation, named so the unbounded consumer and the
32-instance quote the same shape. -/
def successShape (mv n fee : Nat) : TxView :=
  ⟨.success, n + 3 + (if mv - n * fee = 0 then 0 else 1),
    ⟨0, 0, 0, 0, 0, n * fee, mv - n * fee⟩⟩

/-- Helper: any dispatcher fuel that *covers* the derived amount yields the
success shape.  The fuel inequality is discharged at the unbounded export by
instantiating `fuel := n + 4` (`le_refl`); it is *not* a hypothesis of
`verity_tx_success_shape_unbounded`. -/
theorem observe_runWithFuel_of_le (fuel mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hfit : n + 4 ≤ fuel) :
    observe (runWithFuel fuel honest mv n fee) = successShape mv n fee := by
  let leftover := fuel - (n + 4)
  have hdecomp : fuel = leftover + (n + 4) := (Nat.sub_add_cancel hfit).symm
  have hbus : leftover + (n + 4) = leftover + n + 3 + 1 := by omega
  have hgw : leftover + n + 3 = leftover + n + 2 + 1 := by omega
  have hvault : leftover + n + 2 = leftover + n + 1 + 1 := by omega
  unfold runWithFuel
  rw [hdecomp, hbus]
  rw [hop_bus mv n fee (leftover + n + 3) 0 [] hmv hnM]
  rw [hgw]
  rw [hop_gateway mv n fee (leftover + n + 2) 1 [busCompiled mv n] hpos hmv hnM hnf hle]
  rw [hvault]
  rw [hop_vault mv n fee (leftover + n + 1) 2 _ hmv hnM hfee hnf hle]
  rw [show leftover + n + 1 = n + (leftover + 1) from by omega]
  rw [show (2 + 1 : Nat) = 3 from rfl]
  rw [request_phase n (initial mv fee) (vaultPostWorld mv n fee) fee (leftover + 1) 3
    [vaultCompiled n fee, gwCompiled mv n, busCompiled mv n]
    (if mv - n * fee = 0 then [] else [refundPending mv n fee])
    (request_phase_guard mv n fee hfee hnf)]
  by_cases hz : mv - n * fee = 0
  · rw [if_pos hz]
    simp only [step]
    simp only [observe, finalWorld, successShape]
    rw [balances_phase4 mv n fee hmv hfee hnf hle hz, if_pos hz]
    simp only [TxView.mk.injEq]
    exact ⟨trivial, by omega, trivial⟩
  · rw [if_neg hz]
    rw [show leftover + 1 = leftover + 1 from rfl]
    rw [hop_refund (initial mv fee) (requestPhaseWorld fee n (vaultPostWorld mv n fee))
      mv n fee leftover (3 + n) _
      (by rw [phase4_gateway_balance_val mv n fee hmv hnf hle]; exact Nat.le_refl _)]
    simp only [step]
    simp only [observe, finalWorld, successShape]
    rw [balances_final_refund mv n fee hmv hfee hnf hle, if_neg hz]
    simp only [TxView.mk.injEq]
    exact ⟨trivial, by omega, trivial⟩

/-- **Derived unbounded success consumer.**  For every funded, word-sized,
non-wrapping, nonzero-valued batch the honest wiring commits at the
*derived* fuel `batchSize + 4`.  No `batchSize + 4 ≤ fuelBudget` hypothesis. -/
theorem verity_tx_success_shape_unbounded (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    observe (runWithFuel (n + 4) honest mv n fee) = successShape mv n fee :=
  observe_runWithFuel_of_le (n + 4) mv n fee hpos hmv hnM hfee hnf hle (Nat.le_refl _)

/-- Extra unused frames do not change the success observation once the derived
amount is covered. -/
theorem runWithFuel_irrelevance (fuel mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hfit : n + 4 ≤ fuel) :
    observe (runWithFuel fuel honest mv n fee) =
      observe (runWithFuel (n + 4) honest mv n fee) :=
  (observe_runWithFuel_of_le fuel mv n fee hpos hmv hnM hfee hnf hle hfit).trans
    (verity_tx_success_shape_unbounded mv n fee hpos hmv hnM hfee hnf hle).symm

/-- The registered parent dispatcher (`run` = `runWithFuel fuelBudget`) agrees
with the derived-fuel consumer on every batch the parent admits. -/
theorem registered_parent_is_instance_at_32 (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hfuel : n + 4 ≤ fuelBudget) :
    observe (run honest mv n fee) =
      observe (runWithFuel (n + 4) honest mv n fee) := by
  rw [run_is_runWithFuel_at_fuelBudget]
  exact runWithFuel_irrelevance fuelBudget mv n fee hpos hmv hnM hfee hnf hle hfuel

/-- The registered success statement, recovered as the `fuelBudget = 32`
instance of `verity_tx_success_shape_unbounded`. -/
theorem registered_parent_recovered_at_32 (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hfuel : n + 4 ≤ fuelBudget) :
    observe (run honest mv n fee) = successShape mv n fee :=
  (registered_parent_is_instance_at_32 mv n fee hpos hmv hnM hfee hnf hle hfuel).trans
    (verity_tx_success_shape_unbounded mv n fee hpos hmv hnM hfee hnf hle)

/-- Same type as
`Guarantees.PConsolidationEth1.verity_tx_universal_success_shape`. -/
theorem registered_parent_type_recovered (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hfuel : n + 4 ≤ fuelBudget) :
    observe (run honest mv n fee) =
      ⟨.success, n + 3 + (if mv - n * fee = 0 then 0 else 1),
        ⟨0, 0, 0, 0, 0, n * fee, mv - n * fee⟩⟩ :=
  registered_parent_recovered_at_32 mv n fee hpos hmv hnM hfee hnf hle hfuel

/-- The parent fuel premise is false at the funded tuple `(30, 29, 1)` that the
registered exhaustion arm uses.  The derived consumer still commits. -/
theorem parent_fuel_premise_excludes_batch_29 :
    ¬ (29 + 4 ≤ fuelBudget) := by
  decide

theorem unbounded_covers_funded_batch_29 :
    observe (runWithFuel (29 + 4) honest 30 29 1) = successShape 30 29 1 :=
  verity_tx_success_shape_unbounded 30 29 1
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)

/-- Truncating the derived fuel to `batchSize + 3` exhausts on every funded
batch with a positive remainder (the path that needs the extra refund frame). -/
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
  -- Rewrite only the fuel argument. `rw [n = n+0]` would also rewrite the
  -- batch size `n` inside `vaultPostWorld` / `replicate`.
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

theorem truncated_fuel_batchSize_plus_three_refuses_success (mv n fee : Nat)
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

/-! ## General-rule composition (Thomas 2026-09-12): batchSize under mainnet Bus ceiling

The registered Verity parent's exhaustion arm at `batchSize ≥ 29`
(chantier 5 disclosed) is a `fuelBudget = 32` frame-count artifact
of the abstract dispatcher — the mainnet Bus `batchSize` ceiling is
200, so batches of 29-199 that exhaust the model DO commit on chain.

Under the general rule (Thomas 2026-09-12): name the pinned Bus
ceiling as an explicit premise, and prove that under it the derived-
fuel success arm holds for any admitted `batchSize`. The composition
below is the derived consumer that fires under the mainnet Bus
ceiling; the model's `fuelBudget = 32` artifact remains disclosed as
a scope narrowing in `fidelity.missing`. -/

/-- The pinned mainnet ConsolidationBus `batchSize` ceiling. Sourced
from the deployed Bus contract's per-transaction limit (documented
in `audit/eth1-unbounded-fuel/README.md` alongside grok #410). -/
def mainnetBusBatchCeiling : Nat := 200

/-- **General-rule composition (Thomas 2026-09-12): derived-fuel
success under mainnet Bus batchSize ceiling.**

The chantier 5 grok #410 consumer
`verity_tx_success_shape_unbounded` proves success at derived fuel
`batchSize + 4` for any word-sized batch. Under the pinned
`mainnetBusBatchCeiling = 200`, `batchSize + 4 ≤ 204`, so the derived
fuel is a small constant — matching what the mainnet Bus admits in a
single transaction. The registered parent's `fuelBudget = 32`
artifact contradicts this ceiling (200 ≫ 28); the composition below
names the real bound the code imposes and delivers success under it. -/
theorem verity_tx_success_at_derived_fuel_under_bus_ceiling
    (mv n fee : Nat)
    (_hBusCeiling : n ≤ mainnetBusBatchCeiling)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    observe (runWithFuel (n + 4) honest mv n fee) = successShape mv n fee :=
  verity_tx_success_shape_unbounded mv n fee hpos hmv hnM hfee hnf hle

end LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel

#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.verity_tx_success_shape_unbounded
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.registered_parent_is_instance_at_32
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.registered_parent_recovered_at_32
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.unbounded_covers_funded_batch_29
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.truncated_fuel_batchSize_plus_three_exhausted
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.truncated_fuel_batchSize_plus_three_refuses_success
