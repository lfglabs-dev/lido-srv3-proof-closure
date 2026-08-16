import LidoSRv3.Audit.Guarantees.PAddress1
import Verity.Core.Model.Denote

/-!
# P-ADDRESS-1 admission plane over the official Verity denotation

`LidoSRv3.Audit.Guarantees.PAddress1` states address-nondiscrimination against an
opaque `fn : Address → Input → Outcome State`.  Nothing there is bound to an
executable entrypoint, so the MODEL and transaction planes stay OPEN: the facade
theorem `admission_and_post_state_equivariance` is pure `And`-introduction, and
`AddressYulInterface.mutant_sensitive_harness` closes by `rfl` on a definitional
renaming.  Neither observes a caller.

This module supplies the missing observation for the **admission half only**.  A
permissionless entrypoint is written in the pinned deep EDSL and evaluated by the
official denotation `Compiler.CompilationModel.Denote.denoteFunction`, the same
semantic path already used by `LidoSRv3.Audit.Verity.OfficialSemantics`.
`denoteFunction` installs `DenoteTransaction.sender` into `ContractState.sender`
through `withTransactionContext`, and `Expr.caller` reads exactly that field, so
the caller is a genuine input of the run rather than an index on an abstract
function.

This module deliberately does **not** use `Contracts.Common.externalCallBind`: at
Verity pin `04729a9` that combinator is `pure ()` (`Contracts/Common.lean:582`),
so an entrypoint whose admission depended on a declared external call would be
definitionally insensitive to that call and the resulting statement would be
vacuous.  The entrypoint below contains no external call at all; its admission is
decided entirely by a global pause gate and a caller-indexed balance read, both
of which the official denotation genuinely evaluates.

## What is proved

* `run_claim_success` reduces the official denotation of the entrypoint to the
  exact pair of storage reads that decide admission.
* `admission_address_equivariant` — for every mapping-slot oracle, every caller
  pair, and every world, the success bit under caller `a₁` equals the success bit
  under caller `a₂` in the world whose two caller-indexed balance entries have
  been swapped.  This is `PAddress1.admission_nondiscriminatory` transported onto
  `denoteFunction`.
* `claim_admits`, `claim_rejects_empty_balance`, `claim_rejects_when_paused` — the
  entrypoint is not constant, so the equivariance statement is not vacuously true
  of an always-reverting or always-succeeding program.
* `ownerGated_not_admission_equivariant` — the owner-gated mutant of the same
  entrypoint refutes the equivariance property, so the property has teeth.

## What is not proved

Post-state equivariance (`PAddress1.post_state_equivariant`) is untouched: this
entrypoint writes no storage, so the module says nothing about renamed successful
post-states.  No correspondence to pinned Lido SRv3 Solidity is claimed — the
entrypoint is an audit-authored permissionless shape, not an extracted one — so
the SOURCE plane is unaffected and the parent transaction plane stays OPEN.
-/

namespace LidoSRv3.Audit.Verity.AddressAdmission

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote

/-! ## Storage layout -/

def balancesSlot : Nat := 3
def pausedSlot : Nat := 4
def ownerSlot : Nat := 5

def balancesField : Field :=
  { name := "balances", ty := .mappingTyped (.simple .address), «slot» := some balancesSlot }

def pausedField : Field :=
  { name := "paused", ty := .uint256, «slot» := some pausedSlot }

def ownerField : Field :=
  { name := "owner", ty := .uint256, «slot» := some ownerSlot }

/-! ## The permissionless entrypoint

`claim()` gates on a protocol-wide pause flag and on the caller's own balance.
It tests no privileged role and no singleton actor, so it is in P-ADDRESS-1 scope
rather than in the authentication-integrity exclusions recorded in the facade. -/

def claim : FunctionSpec :=
  { name := "claim"
    params := []
    returnType := some .uint256
    body :=
      [ .require (.eq (.storage "paused") (.literal 0)) "paused"
      , .require (.lt (.literal 0) (.mapping "balances" .caller)) "nothing to claim"
      , .return (.mapping "balances" .caller) ] }

/-- Owner-gated mutant: identical except for one privileged-role test. -/
def ownerGated : FunctionSpec :=
  { claim with
    name := "ownerGated"
    body :=
      [ .require (.eq (.storage "paused") (.literal 0)) "paused"
      , .require (.eq .caller (.storage "owner")) "not owner"
      , .require (.lt (.literal 0) (.mapping "balances" .caller)) "nothing to claim"
      , .return (.mapping "balances" .caller) ] }

def spec : CompilationModel :=
  { name := "AddressAdmission"
    fields := [balancesField, pausedField, ownerField]
    constructor := none
    functions := [claim] }

def claimSelector : Nat := 0x4e71d92d

def txFrom (sender : Nat) : DenoteTransaction :=
  { sender := sender, functionSelector := claimSelector, args := [] }

/-- Run an entrypoint of `spec` under the official denotation with `sender` as the
caller. -/
def run (oracle : DenoteOracle) (fn : FunctionSpec) (sender : Nat)
    (world : Verity.ContractState) : DenoteResult :=
  denoteFunction oracle spec fn (txFrom sender) world

/-- The denotation resolves `paused` to the declared scalar slot. -/
theorem paused_lookup :
    findFieldWithResolvedSlot (effectiveFields spec) "paused" =
      some (pausedField, pausedSlot) := rfl

/-- The denotation resolves `owner` to the declared scalar slot. -/
theorem owner_lookup :
    findFieldWithResolvedSlot (effectiveFields spec) "owner" =
      some (ownerField, ownerSlot) := rfl

/-- The denotation resolves `balances` to the declared mapping base slot. -/
theorem balances_lookup :
    findFieldWithResolvedSlot (effectiveFields spec) "balances" =
      some (balancesField, balancesSlot) := rfl

/-! ## Caller-indexed storage and the caller swap -/

/-- The address word actually observed by `Expr.caller` for transaction sender
`sender`.  `withTransactionContext` stores `wordToAddress sender`, so this is the
masked address rather than the raw word. -/
def callerKey (sender : Nat) : Nat :=
  (Verity.wordToAddress (sender : Verity.Core.Uint256)).val

/-- The normalized storage slot holding `balances[sender]`, as resolved by the
denotation's mapping-slot oracle. -/
def balanceSlotOf (oracle : DenoteOracle) (sender : Nat) : Nat :=
  wordNormalize (oracle.mappingSlot balancesSlot (callerKey sender))

/-- Swap the two caller-indexed balance entries and fix every other slot.  This is
the P-ADDRESS-1 renaming `rename_input` restricted to the address-indexed storage
this entrypoint actually reads. -/
def swapBalances (oracle : DenoteOracle) (a₁ a₂ : Nat)
    (world : Verity.ContractState) : Verity.ContractState :=
  { world with
    storage := fun s =>
      if s = balanceSlotOf oracle a₁ then world.storage (balanceSlotOf oracle a₂)
      else if s = balanceSlotOf oracle a₂ then world.storage (balanceSlotOf oracle a₁)
      else world.storage s }

/-- Storage-disjointness side condition: the mapping-slot oracle does not alias a
caller's balance entry onto the scalar `paused` slot.  A colliding oracle would
let the caller swap rewrite the pause gate, so this is stated explicitly rather
than assumed silently. -/
def PauseDisjoint (oracle : DenoteOracle) (a : Nat) : Prop :=
  balanceSlotOf oracle a ≠ wordNormalize pausedSlot

/-! ## Reduction of the official denotation

`run_claim_success` is the load-bearing step: it evaluates `denoteFunction` on the
entrypoint down to the two storage reads that actually decide admission.  Every
statement below is a consequence of it, so nothing here depends on an abstract
re-statement of the program. -/

/-- The admission predicate the official denotation actually computes. -/
def admitted (oracle : DenoteOracle) (a : Nat) (w : Verity.ContractState) : Bool :=
  decide ((w.storage (wordNormalize pausedSlot)).val = 0) &&
    decide (0 < (w.storage (balanceSlotOf oracle a)).val)

set_option maxHeartbeats 2000000 in
/-- The official denotation of the permissionless entrypoint admits exactly when
the protocol is unpaused and the caller's own balance entry is non-zero. -/
theorem run_claim_success (oracle : DenoteOracle) (a : Nat) (w : Verity.ContractState) :
    (run oracle claim a w).success = admitted oracle a w := by
  unfold run admitted
  simp only [denoteFunction, claim, txFrom,
    show bindExternalParams claimSelector [] [] = some [] from rfl,
    paused_lookup, balances_lookup,
    execStmtList, execStmt, evalExpr, readFieldWord, pausedField, balancesField,
    withTransactionContext, Verity.ContractState.readSlot, successResult, revertedResult,
    balanceSlotOf, callerKey, boolWord]
  by_cases hp : (w.storage (wordNormalize pausedSlot)).val = 0 <;>
    by_cases hb : 0 < (w.storage (wordNormalize
      (oracle.mappingSlot balancesSlot (Verity.wordToAddress (a : Verity.Core.Uint256)).val))).val <;>
    simp [hp, hb, -Verity.wordToAddress, show wordNormalize 0 = 0 from rfl]

/-! ## Admission equivariance -/

private theorem swap_reads_paused (oracle : DenoteOracle) (a₁ a₂ : Nat)
    (world : Verity.ContractState)
    (h₁ : PauseDisjoint oracle a₁) (h₂ : PauseDisjoint oracle a₂) :
    (swapBalances oracle a₁ a₂ world).storage (wordNormalize pausedSlot) =
      world.storage (wordNormalize pausedSlot) := by
  simp only [swapBalances]
  rw [if_neg (fun h => h₁ h.symm), if_neg (fun h => h₂ h.symm)]

private theorem swap_reads_balance (oracle : DenoteOracle) (a₁ a₂ : Nat)
    (world : Verity.ContractState) :
    (swapBalances oracle a₁ a₂ world).storage (balanceSlotOf oracle a₂) =
      world.storage (balanceSlotOf oracle a₁) := by
  simp only [swapBalances]
  by_cases h : balanceSlotOf oracle a₂ = balanceSlotOf oracle a₁
  · rw [if_pos h, h]
  · rw [if_neg h]
    simp

/-- **P-ADDRESS-1 admission non-discrimination over the official denotation.**

For every mapping-slot oracle, every pair of callers whose balance entries do not
alias the pause slot, and every world, the official denotation admits caller `a₁`
exactly when it admits caller `a₂` in the caller-swapped world.

This is the `denoteFunction` instance of
`LidoSRv3.Audit.Guarantees.PAddress1.admission_nondiscriminatory`: the caller is
read by `Expr.caller` from `ContractState.sender`, which `denoteFunction`
populates from `DenoteTransaction.sender`.  Post-state equivariance is not
claimed. -/
theorem admission_address_equivariant (oracle : DenoteOracle) (a₁ a₂ : Nat)
    (world : Verity.ContractState)
    (h₁ : PauseDisjoint oracle a₁) (h₂ : PauseDisjoint oracle a₂) :
    (run oracle claim a₁ world).success =
      (run oracle claim a₂ (swapBalances oracle a₁ a₂ world)).success := by
  rw [run_claim_success, run_claim_success]
  unfold admitted
  rw [swap_reads_paused oracle a₁ a₂ world h₁ h₂, swap_reads_balance oracle a₁ a₂ world]

/-! ## Non-vacuity

An always-reverting or always-succeeding entrypoint would satisfy
`admission_address_equivariant` trivially.  The concrete runs below show the
official denotation of `claim` takes both values, and that each of the two gates
is individually load-bearing. -/

/-- A concrete mapping-slot oracle: `balances[key]` lives at `key + 100`. -/
def witnessOracle : DenoteOracle :=
  { mappingSlot := fun _ key => key + 100
    keccakMemorySlice := fun _ _ _ => 0 }

/-- Unpaused world with `owner = 1`, `balances[1] = 7` and `balances[2] = 0`.
Slot `101` is `balances[1]`, slot `102` is `balances[2]`, slot `5` is `owner`,
and slot `4` (`paused`) is `0`. -/
def witnessWorld : Verity.ContractState :=
  { Verity.defaultState with
    storage := fun s => if s = 101 then 7 else if s = 5 then 1 else 0 }

/-- The paused variant of `witnessWorld`; only the pause gate differs. -/
def pausedWorld : Verity.ContractState :=
  { witnessWorld with
    storage := fun s => if s = 4 then 1 else witnessWorld.storage s }

theorem witness_balance_slot_one : balanceSlotOf witnessOracle 1 = 101 := by decide

theorem witness_balance_slot_two : balanceSlotOf witnessOracle 2 = 102 := by decide

theorem witness_pause_disjoint_one : PauseDisjoint witnessOracle 1 := by
  unfold PauseDisjoint; decide

theorem witness_pause_disjoint_two : PauseDisjoint witnessOracle 2 := by
  unfold PauseDisjoint; decide

/-- The entrypoint really admits: a caller with a non-zero balance succeeds. -/
theorem claim_admits : (run witnessOracle claim 1 witnessWorld).success = true := by
  rw [run_claim_success]; decide

/-- The balance gate is load-bearing: the same world rejects a caller whose own
balance entry is zero. -/
theorem claim_rejects_empty_balance :
    (run witnessOracle claim 2 witnessWorld).success = false := by
  rw [run_claim_success]; decide

/-- The pause gate is load-bearing: the caller admitted by `claim_admits` is
rejected once `paused` is set. -/
theorem claim_rejects_when_paused :
    (run witnessOracle claim 1 pausedWorld).success = false := by
  rw [run_claim_success]; decide

/-! ## The property has teeth

The owner-gated mutant differs from `claim` by a single privileged-role test.
Reducing it through the same official denotation and evaluating one witness
refutes admission equivariance, so `admission_address_equivariant` is not a
statement every entrypoint of this shape would satisfy. -/

/-- The admission predicate the official denotation computes for the mutant. -/
def admittedOwner (oracle : DenoteOracle) (a : Nat) (w : Verity.ContractState) : Bool :=
  decide ((w.storage (wordNormalize pausedSlot)).val = 0) &&
    decide ((w.storage (wordNormalize ownerSlot)).val = callerKey a) &&
    decide (0 < (w.storage (balanceSlotOf oracle a)).val)

set_option maxHeartbeats 2000000 in
theorem run_ownerGated_success (oracle : DenoteOracle) (a : Nat) (w : Verity.ContractState) :
    (run oracle ownerGated a w).success = admittedOwner oracle a w := by
  unfold run admittedOwner
  simp only [denoteFunction, ownerGated, claim, txFrom,
    show bindExternalParams claimSelector [] [] = some [] from rfl,
    paused_lookup, balances_lookup, owner_lookup,
    execStmtList, execStmt, evalExpr, readFieldWord, pausedField, balancesField, ownerField,
    withTransactionContext, Verity.ContractState.readSlot, successResult, revertedResult,
    balanceSlotOf, callerKey, boolWord]
  by_cases hp : (w.storage (wordNormalize pausedSlot)).val = 0
  · by_cases ho : (w.storage (wordNormalize ownerSlot)).val =
        (Verity.wordToAddress (a : Verity.Core.Uint256)).val
    · by_cases hb : 0 < (w.storage (wordNormalize
        (oracle.mappingSlot balancesSlot (Verity.wordToAddress (a : Verity.Core.Uint256)).val))).val <;>
        simp [hp, ho, hb, -Verity.wordToAddress, show wordNormalize 0 = 0 from rfl]
    · simp [hp, ho, Ne.symm ho, -Verity.wordToAddress, show wordNormalize 0 = 0 from rfl]
  · simp [hp, -Verity.wordToAddress, show wordNormalize 0 = 0 from rfl]

/-- **Negative mutant.**  The owner-gated entrypoint refutes the admission
equivariance property that `claim` satisfies: under `witnessOracle`, caller `1`
is the owner and is admitted, while caller `2` in the balance-swapped world is
rejected by the privileged-role test even though its balance entry now holds the
admitted caller's value. -/
theorem ownerGated_not_admission_equivariant :
    ¬ ∀ (oracle : DenoteOracle) (a₁ a₂ : Nat) (world : Verity.ContractState),
        PauseDisjoint oracle a₁ → PauseDisjoint oracle a₂ →
        (run oracle ownerGated a₁ world).success =
          (run oracle ownerGated a₂ (swapBalances oracle a₁ a₂ world)).success := by
  intro h
  have hcex := h witnessOracle 1 2 witnessWorld
    witness_pause_disjoint_one witness_pause_disjoint_two
  rw [run_ownerGated_success, run_ownerGated_success,
    show admittedOwner witnessOracle 1 witnessWorld = true from by decide,
    show admittedOwner witnessOracle 2 (swapBalances witnessOracle 1 2 witnessWorld) = false from by
      decide] at hcex
  exact Bool.noConfusion hcex

end LidoSRv3.Audit.Verity.AddressAdmission
