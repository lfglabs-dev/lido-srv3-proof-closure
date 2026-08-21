import LidoSRv3.Audit.Verity.AddressAdmission

/-!
# P-ADDRESS-1.denote-admission audit probe (round 2 note)

Machine-checked observations behind the round-2 note in
`report/P-ADDRESS-1.denote-admission.md`.  This module is **not evidence**: it
is not imported by any facade, not printed by `LidoSRv3.Audit.Trust`, and not
named in `audit/guarantees.yaml`.

1. `admission_equivariant_without_address_bounds` — the registered theorem's
   two `_ha` address-range binders are not load-bearing: the same three-line
   script proves the conclusion without them.
2. `high_bit_callers_share_a_balance_slot` — `callerKey` masks to 160 bits, so
   two senders differing by `2^160` are one account in the model.
3. `owner_gate_kill_line_with_parent_premises` — the registered row's kill-line
   restated in the registered theorem's exact premise shape.
4. `payCaller_*` — a permissionless entrypoint whose *payout* is the caller's
   own identity satisfies the registered equivariance statement, because only
   `DenoteResult.success` is compared.
-/

namespace LidoSRv3.Tests.AddressAdmissionAuditProbe

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open LidoSRv3.Audit.Verity.AddressAdmission

/-! ## 1. The address-range premises are decoration -/

private theorem swap_paused (oracle : DenoteOracle) (a₁ a₂ : Nat)
    (world : Verity.ContractState)
    (h₁ : PauseDisjoint oracle a₁) (h₂ : PauseDisjoint oracle a₂) :
    (swapBalances oracle a₁ a₂ world).storage (wordNormalize pausedSlot) =
      world.storage (wordNormalize pausedSlot) := by
  simp only [swapBalances]
  rw [Verity.ContractState.storage_writeSlot_other _ (fun h => h₂ h.symm),
    Verity.ContractState.storage_writeSlot_other _ (fun h => h₁ h.symm)]

private theorem swap_balance (oracle : DenoteOracle) (a₁ a₂ : Nat)
    (world : Verity.ContractState) :
    (swapBalances oracle a₁ a₂ world).storage (balanceSlotOf oracle a₂) =
      world.storage (balanceSlotOf oracle a₁) := by
  simp [swapBalances, Verity.ContractState.storage_writeSlot_same]

/-- **The registered theorem's `a < Address.modulus` binders are unused.**  The
registered `admission_address_equivariant` carries `_ha₁` and `_ha₂`; the same
proof goes through without them, so they restrict the claim's readership rather
than its content. -/
theorem admission_equivariant_without_address_bounds (oracle : DenoteOracle)
    (a₁ a₂ : Nat) (world : Verity.ContractState)
    (h₁ : PauseDisjoint oracle a₁) (h₂ : PauseDisjoint oracle a₂) :
    (run oracle claim a₁ world).success =
      (run oracle claim a₂ (swapBalances oracle a₁ a₂ world)).success := by
  rw [run_claim_success, run_claim_success]
  unfold admitted
  rw [swap_paused oracle a₁ a₂ world h₁ h₂, swap_balance oracle a₁ a₂ world]

/-! ## 1b. `PauseDisjoint` is necessary, with a consistent witness -/

/-- An oracle that aliases caller `1`'s balance entry onto the pause slot and
puts caller `2`'s entry at slot `102`. -/
def aliasOracle : DenoteOracle :=
  { mappingSlot := fun _ key => if key = 1 then pausedSlot else key + 100
    keccakMemorySlice := fun _ _ _ => 0 }

/-- Paused world for `aliasOracle`: the pause word holds `7`, which is also
"caller 1's balance", and caller `2`'s entry is `0`. -/
def aliasWorld : Verity.ContractState := Verity.defaultState.writeSlot 4 7

/-- **The side condition is load-bearing, on a world that exists.**  Round 1's
counterexample set the aliased word to both `0` (as `paused`) and `7` (as
`balances[a₁]`), which is not one world.  With a single consistent valuation the
refutation still goes through: caller `1` is rejected because the alias makes
the contract paused, and after the swap caller `2` is admitted because the swap
clears the pause word and moves `7` into caller `2`'s entry. -/
theorem pause_disjoint_is_load_bearing :
    ¬ ∀ (oracle : DenoteOracle) (a₁ a₂ : Nat) (world : Verity.ContractState),
        a₁ < Verity.Core.Address.modulus → a₂ < Verity.Core.Address.modulus →
        (run oracle claim a₁ world).success =
          (run oracle claim a₂ (swapBalances oracle a₁ a₂ world)).success := by
  intro h
  have hcex := h aliasOracle 1 2 aliasWorld (by decide) (by decide)
  rw [run_claim_success, run_claim_success,
    show admitted aliasOracle 1 aliasWorld = false from by decide,
    show admitted aliasOracle 2 (swapBalances aliasOracle 1 2 aliasWorld) = true from by
      decide] at hcex
  exact Bool.noConfusion hcex

/-! ## 2. Senders differing by `2^160` are one account -/

/-- `callerKey` is `wordToAddress`, so the model cannot tell these two senders
apart: they share one balance slot and the caller swap between them is a
storage no-op. -/
theorem high_bit_callers_share_a_balance_slot :
    callerKey (1 + 2 ^ 160) = callerKey 1 ∧
      balanceSlotOf witnessOracle (1 + 2 ^ 160) = balanceSlotOf witnessOracle 1 := by
  native_decide

/-! ## 3. The kill-line in the registered premise shape -/

/-- The row's kill-line `ownerGated_not_admission_equivariant` negates a `∀`
that omits the registered theorem's two address-range premises.  Restating it
with those premises retained costs two `decide`s. -/
theorem owner_gate_kill_line_with_parent_premises :
    ¬ ∀ (oracle : DenoteOracle) (a₁ a₂ : Nat) (world : Verity.ContractState),
        a₁ < Verity.Core.Address.modulus → a₂ < Verity.Core.Address.modulus →
        PauseDisjoint oracle a₁ → PauseDisjoint oracle a₂ →
        (run oracle ownerGated a₁ world).success =
          (run oracle ownerGated a₂ (swapBalances oracle a₁ a₂ world)).success := by
  intro h
  have hcex := h witnessOracle 1 2 witnessWorld (by decide) (by decide)
    witness_pause_disjoint_one witness_pause_disjoint_two
  rw [run_ownerGated_success, run_ownerGated_success,
    show admittedOwner witnessOracle 1 witnessWorld = true from by decide,
    show admittedOwner witnessOracle 2 (swapBalances witnessOracle 1 2 witnessWorld) = false from by
      decide] at hcex
  exact Bool.noConfusion hcex

/-! ## 4. Only the success bit is compared -/

/-- Mutant of `claim` that pays out the caller's own identity instead of the
caller's balance.  The two `require`s, and therefore the admission bit, are
exactly `claim`'s. -/
def payCaller : FunctionSpec :=
  { claim with
    name := "payCaller"
    body :=
      [ .require (.eq (.storage "paused") (.literal 0)) "paused"
      , .require (.lt (.literal 0) (.mapping "balances" .caller)) "nothing to claim"
      , .return .caller ] }

set_option maxHeartbeats 2000000 in
theorem run_payCaller_success (oracle : DenoteOracle) (a : Nat)
    (w : Verity.ContractState) :
    (run oracle payCaller a w).success = admitted oracle a w := by
  unfold run admitted
  simp only [denoteFunction, payCaller, claim, txFrom,
    show bindExternalParams claimSelector [] [] = some [] from rfl,
    paused_lookup, balances_lookup,
    execStmtList, execStmt, evalExpr, readFieldWord, pausedField, balancesField,
    withTransactionContext, Verity.ContractState.readSlot, Verity.ContractState.storage,
    successResult, revertedResult,
    balanceSlotOf, callerKey, boolWord]
  by_cases hp : (w.storageWords (.slot (wordNormalize pausedSlot))).val = 0 <;>
    by_cases hb : 0 < (w.storageWords (.slot (wordNormalize
      (oracle.mappingSlot balancesSlot (Verity.wordToAddress (a : Verity.Core.Uint256)).val)))).val <;>
    simp [hp, hb, -Verity.wordToAddress, show wordNormalize 0 = 0 from rfl]

/-- **A caller-discriminating payout satisfies the registered claim.**  The
registered theorem compares `DenoteResult.success` only, so an entrypoint whose
returned amount is a function of *who* the caller is passes it unchanged. -/
theorem payCaller_admission_equivariant (oracle : DenoteOracle) (a₁ a₂ : Nat)
    (world : Verity.ContractState)
    (_ha₁ : a₁ < Verity.Core.Address.modulus)
    (_ha₂ : a₂ < Verity.Core.Address.modulus)
    (h₁ : PauseDisjoint oracle a₁) (h₂ : PauseDisjoint oracle a₂) :
    (run oracle payCaller a₁ world).success =
      (run oracle payCaller a₂ (swapBalances oracle a₁ a₂ world)).success := by
  rw [run_payCaller_success, run_payCaller_success]
  unfold admitted
  rw [swap_paused oracle a₁ a₂ world h₁ h₂, swap_balance oracle a₁ a₂ world]

/-- The uncompared projection really does discriminate: caller `1` is paid `1`
and the swapped caller `2` is paid `2`, on the row's own witness world. -/
theorem payCaller_return_value_discriminates :
    (run witnessOracle payCaller 1 witnessWorld).returnValue = some 1 ∧
      (run witnessOracle payCaller 2
        (swapBalances witnessOracle 1 2 witnessWorld)).returnValue = some 2 := by
  native_decide

end LidoSRv3.Tests.AddressAdmissionAuditProbe
