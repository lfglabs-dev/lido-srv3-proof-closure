import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.AddressEquivariance
import LidoSRv3.Audit.Verity.AddressTransferTx

namespace LidoSRv3.Audit.Guarantees.PAddress1

open Verity

/-- The abstract relation is specified, but no modeled entrypoint discharges it yet. -/
def guarantee : Guarantee := ⟨.pAddress1, []⟩

/-!
# P-ADDRESS-1: permissionless caller non-discrimination

The property compares arbitrary eligible users, not protocol-role holders.  The
right execution receives the complete environment of the left execution with
the two callers swapped.  Admission compares only success/failure.  A successful
post-state may contain the caller (for example as publisher or refund recipient),
so post-states are compared only after applying the same address swap.

Singleton-actor functions are excluded from address-equivariance; they are
covered by authentication-integrity properties.  In particular this excludes
`WithdrawalVault.withdrawWithdrawals`, `addWithdrawalRequests`, and
`addConsolidationRequests`, whose callers must respectively be Lido,
TriggerableWithdrawalsGateway, and ConsolidationGateway.
-/

/-- A bijective rename which swaps two callers and fixes every other address. -/
def address_renaming (a₁ a₂ x : Address) : Address :=
  if x = a₁ then a₂ else if x = a₂ then a₁ else x

theorem address_renaming_involutive (a₁ a₂ : Address) :
    ∀ x, address_renaming a₁ a₂ (address_renaming a₁ a₂ x) = x := by
  intro x
  by_cases h₁ : x = a₁
  · subst x
    by_cases h : a₁ = a₂
    · simp [address_renaming]
    · simp [address_renaming]
  · by_cases h₂ : x = a₂
    · subst x
      simp [address_renaming, h₁]
    · simp [address_renaming, h₁, h₂]

theorem address_renaming_injective (a₁ a₂ : Address) :
    Function.Injective (address_renaming a₁ a₂) := by
  intro x y h
  have h' := congrArg (address_renaming a₁ a₂) h
  simpa only [address_renaming_involutive] using h'

theorem address_renaming_surjective (a₁ a₂ : Address) :
    Function.Surjective (address_renaming a₁ a₂) := by
  intro x
  exact ⟨address_renaming a₁ a₂ x, address_renaming_involutive a₁ a₂ x⟩

theorem address_renaming_bijective (a₁ a₂ : Address) :
    Function.Injective (address_renaming a₁ a₂) ∧
      Function.Surjective (address_renaming a₁ a₂) :=
  ⟨address_renaming_injective a₁ a₂, address_renaming_surjective a₁ a₂⟩

/-- Address-indexed state relevant to permissionless admission. -/
structure Input where
  amount : Nat
  recipient : Address
  deadline : Nat
  blockTimestamp : Nat
  balances : Address → Nat
  allowances : Address → Address → Nat
  ownership : Nat → Option Address
  requestState : Address → Nat
  externalCallEnvironment : Address → Bool

/-- Rename every address position in the caller-dependent input environment. -/
def rename_input (rho : Address → Address) (inp : Input) : Input where
  amount := inp.amount
  recipient := rho inp.recipient
  deadline := inp.deadline
  blockTimestamp := inp.blockTimestamp
  balances := fun a => inp.balances (rho a)
  allowances := fun owner spender => inp.allowances (rho owner) (rho spender)
  ownership := fun requestId => (inp.ownership requestId).map rho
  requestState := fun a => inp.requestState (rho a)
  externalCallEnvironment := fun a => inp.externalCallEnvironment (rho a)

structure Config where
  paused : Bool

def globally_active (cfg : Config) : Prop := cfg.paused = false

/-- Ordinary validity checks contain no privileged-role or singleton-actor test. -/
def ordinary_preconditions (caller : Address) (inp : Input) : Prop :=
  inp.amount > 0 ∧
  inp.deadline > inp.blockTimestamp ∧
  inp.balances caller ≥ inp.amount ∧
  inp.allowances caller inp.recipient ≥ inp.amount ∧
  inp.externalCallEnvironment caller = true

/-- The result shape deliberately separates admission from the successful state. -/
structure Outcome (State : Type) where
  succeeded : Prop
  postState : State

/-- Property A: equivalent address-renamed users are admitted or rejected together. -/
def admission_nondiscriminatory (cfg : Config)
    (fn : Address → Input → Outcome State) : Prop :=
  ∀ (a₁ a₂ : Address) (inp : Input),
    ordinary_preconditions a₁ inp →
    globally_active cfg →
    (fn a₁ inp).succeeded ↔
      (fn a₂ (rename_input (address_renaming a₁ a₂) inp)).succeeded

/-- Property B: successful post-states commute with the caller swap. -/
def post_state_equivariant (cfg : Config) (rename_state : (Address → Address) → State → State)
    (fn : Address → Input → Outcome State) : Prop :=
  ∀ (a₁ a₂ : Address) (inp : Input),
    ordinary_preconditions a₁ inp →
    globally_active cfg →
    (fn a₁ inp).succeeded →
    rename_state (address_renaming a₁ a₂) (fn a₁ inp).postState =
      (fn a₂ (rename_input (address_renaming a₁ a₂) inp)).postState

/-- The repaired P-ADDRESS-1 model is exactly the conjunction of A and B. -/
def address_nondiscrimination (cfg : Config)
    (rename_state : (Address → Address) → State → State)
    (fn : Address → Input → Outcome State) : Prop :=
  admission_nondiscriminatory cfg fn ∧ post_state_equivariant cfg rename_state fn

/-- Logical composition helper only; this is not evidence for any modeled entrypoint. -/
theorem admission_and_post_state_equivariance
    (cfg : Config) (rename_state : (Address → Address) → State → State)
    (fn : Address → Input → Outcome State)
    (hAdmission : admission_nondiscriminatory cfg fn)
    (hPostState : post_state_equivariant cfg rename_state fn) :
    address_nondiscrimination cfg rename_state fn := by
  exact ⟨hAdmission, hPostState⟩

/-- Bounded horizontal slice only: MODEL→SOURCE→official-Denote composition
for the owner-operated WithdrawalQueue ERC-721 ownership handoff. The umbrella
guarantee remains open for the other mapped entrypoints and omitted set/event
effects. -/
theorem bounded_transfer_model_source_tx :
    (∀ caller fromAddr to s,
      LidoSRv3.Audit.Source.AddressTransferCorrespondence.sourceTransfer caller fromAddr to s =
      LidoSRv3.Audit.Source.AddressTransferCorrespondence.modelTransfer caller fromAddr to s) ∧
    LidoSRv3.Audit.Source.AddressTransferCorrespondence.sourceTransfer 1 1 3
      { owner := 1, approved := 9 } = some { owner := 3, approved := 0 } ∧
    LidoSRv3.Audit.Source.AddressTransferCorrespondence.sourceTransfer 2 2 3
      { owner := 2, approved := 9 } = some { owner := 3, approved := 0 } ∧
    LidoSRv3.Audit.Verity.AddressTransferTx.observe
      (LidoSRv3.Audit.Verity.AddressTransferTx.run 1 1 3 1 9) = (true, 3, 0) ∧
    LidoSRv3.Audit.Verity.AddressTransferTx.observe
      (LidoSRv3.Audit.Verity.AddressTransferTx.run 2 2 3 2 9) = (true, 3, 0) ∧
    LidoSRv3.Audit.Source.AddressTransferCorrespondence.swap12 3 ≠ 4 ∧
    LidoSRv3.Audit.Source.AddressTransferCorrespondence.swap12 9 ≠ 8 ∧
    LidoSRv3.Audit.Verity.AddressTransferTx.observe
      (LidoSRv3.Audit.Verity.AddressTransferTx.run 9 1 3 1 9) = (false, 1, 9) :=
  LidoSRv3.Audit.Verity.AddressTransferTx.model_source_tx_address_equivariance_slice

end LidoSRv3.Audit.Guarantees.PAddress1
