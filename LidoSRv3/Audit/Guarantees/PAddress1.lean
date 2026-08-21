import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.AddressEquivariance
import LidoSRv3.Audit.Verity.AddressTransferTx
import LidoSRv3.Audit.Verity.AddressTx

namespace LidoSRv3.Audit.Guarantees.PAddress1

open Verity
open LidoSRv3.Audit.Source.AddressTransferCorrespondence
open LidoSRv3.Audit.Verity.AddressTransferTx
open LidoSRv3.Audit.SolidityAddress

abbrev Address := Nat

/-- P-ADDRESS-1 is closed by the universal source-shaped address transition and
its executable Verity transaction composition. -/
def guarantee : Guarantee := ⟨.pAddress1, [.model, .source, .verityTx]⟩

/-!
# P-ADDRESS-1: permissionless caller non-discrimination

The property compares arbitrary eligible users, not protocol-role holders.  The
right execution receives the complete environment of the left execution with
the two callers swapped.  Admission compares only success/failure.  A successful
post-state may contain the caller (for example as publisher or refund recipient),
so post-states are compared only after applying the same address swap.

Singleton-actor functions are outside address-equivariance in principle; they
are covered by authentication-integrity properties.  In particular
`WithdrawalVault.withdrawWithdrawals`, `addWithdrawalRequests`, and
`addConsolidationRequests`, whose callers must respectively be Lido,
TriggerableWithdrawalsGateway, and ConsolidationGateway, are simply not among
the modeled entrypoints.  The exclusion is not a premise of the theorems
below: `singletonActorEntryPoint` is `False` for every modeled `EntryPoint`
(`not_singleton_actor_entry_point`), so there is no modeled singleton-actor
entrypoint to exclude and the parent carries no such hypothesis.
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

/-! ## Universal abstract closure

The abstract transition ranges over all four mapped entrypoint tags and every
input, rather than a recovered concrete transfer witness.  The zero address is
fixed by a caller swap, hence the two ordinary callers are required nonzero. -/

theorem universal_post_state_equivariance
    (a₁ a₂ : Verity.Address) (h₁ : a₁ ≠ 0) (h₂ : a₂ ≠ 0)
    (inp : LidoSRv3.Audit.SolidityAddress.Input) (post : PostState)
    (h : run inp = .committed post) :
    run (renameInput a₁ a₂ inp) = .committed (renamePost a₁ a₂ post) :=
  source_success_post_state_equivariant a₁ a₂ h₁ h₂ inp post h

/-- Registered P-ADDRESS-1 parent. For two nonzero callers, the source-shaped
`run` admits `a₁` iff it admits `a₂` on the caller-swapped input, and a
successful post-state renames under the same swap. The claim is unconditional
over four modeled address-bearing writer projections: since wave 5,
`addressEquivarianceEntryScope` covers `claimWithdrawalsTo` too -- its
request-owner gate (`caller = requestOwner`) is caller-relative and renames
with the caller (`requestOwner` is an address-indexed input field renamed by
`renameInput`) -- so the scope is total over the modeled writers
(`addressEquivarianceEntryScope_total`). The wave-4 scope premise thereby
became vacuous: the source lemmas below hold for every `EntryPoint` via
`run_rename`, so the premise's deletion cannot break the proof, and per the
wave-4 load-bearing criterion it is no longer carried. On
`requestWithdrawals` and `unwrap`, admission is pause plus the caller's own
balance/allowance flags only (`pause_balance_admitted_is_permissionless`); it
does not test `caller = owner` or `caller = <fixed constant>`. Adding a
fixed-owner gate to that admission breaks equivariance via
`LidoSRv3.Tests.AddressSourceMutants.fixed_owner_gate_kill_line_refutes_parent`,
which negates this theorem's exact predicate shape on a mutant of this file's
own `admitted`/`run`/`renameInput` (not an unrelated toy entrypoint).

`wellFormedAddressInput` and `singletonActorEntryPoint` are deliberately not
carried as hypotheses here: neither restricts this conclusion (the proof
below needs only `a₁, a₂ ≠ 0`), and `singletonActorEntryPoint` is provably
`False` for every `EntryPoint` in this model
(`not_singleton_actor_entry_point`), so requiring its negation would add no
content while reading as a real exclusion. Carrying either as an unused
binder would hide that they are premise-free rather than making the claim
more honest. -/
theorem universal_address_writer_equivariance
    (a₁ a₂ : Verity.Address) (h₁ : a₁ ≠ 0) (h₂ : a₂ ≠ 0)
    (inp : LidoSRv3.Audit.SolidityAddress.Input) :
    succeeds (run (renameInput a₁ a₂ inp)) = succeeds (run inp) ∧
      ∀ post, run inp = .committed post →
        run (renameInput a₁ a₂ inp) = .committed (renamePost a₁ a₂ post) := by
  exact ⟨source_admission_nondiscriminatory a₁ a₂ h₁ h₂ inp,
    fun post h => universal_post_state_equivariance a₁ a₂ h₁ h₂ inp post h⟩

/-- Composition of (i) the universal source-shaped swap, (ii) each
`Contract.run` entrypoint's address-write `observe` matching
`sourceAddressView` when `amount < 2^256` and the balance/allowance
flags are coherent, (iii) any `Contract.run` revert restoring the
snapshot, (iv) the renamed input's TX view matching `postAddressView`
of the renamed post-state. Not a WQ claim. -/
theorem abstract_source_verity_tx_address_equivariance :
    (∀ (a₁ a₂ : Verity.Address), a₁ ≠ 0 → a₂ ≠ 0 →
      ∀ (inp : LidoSRv3.Audit.SolidityAddress.Input),
      succeeds (LidoSRv3.Audit.SolidityAddress.run (renameInput a₁ a₂ inp)) =
        succeeds (LidoSRv3.Audit.SolidityAddress.run inp)) ∧
    (∀ (a₁ a₂ : Verity.Address), a₁ ≠ 0 → a₂ ≠ 0 →
      ∀ (inp : LidoSRv3.Audit.SolidityAddress.Input) (post : PostState),
      LidoSRv3.Audit.SolidityAddress.run inp = .committed post →
      LidoSRv3.Audit.SolidityAddress.run (renameInput a₁ a₂ inp) =
        .committed (renamePost a₁ a₂ post)) ∧
    (∀ (inp : LidoSRv3.Audit.SolidityAddress.Input), inp.amount < 2 ^ 256 →
      (!inp.callerBalanceSufficient = true → inp.amount ≠ 0) →
      (!inp.callerAllowanceSufficient = true → inp.amount ≠ 0) →
      LidoSRv3.Audit.Verity.AddressTx.observeAddress inp
          ((LidoSRv3.Audit.Verity.AddressTx.executePinnedSource inp).run
            (LidoSRv3.Audit.Verity.AddressTx.stateFor inp)) =
        LidoSRv3.Audit.Verity.AddressTx.sourceAddressView inp) ∧
    (∀ (program : Verity.Contract Unit) (state rollback : Verity.ContractState)
      (reason : String),
      program.run state = Verity.ContractResult.revert reason rollback → rollback = state) ∧
    (∀ (a₁ a₂ : Verity.Address), a₁ ≠ 0 → a₂ ≠ 0 →
      ∀ (inp : LidoSRv3.Audit.SolidityAddress.Input) (post : PostState),
      LidoSRv3.Audit.SolidityAddress.run inp = .committed post →
      inp.amount < 2 ^ 256 →
      (!inp.callerBalanceSufficient = true → inp.amount ≠ 0) →
      (!inp.callerAllowanceSufficient = true → inp.amount ≠ 0) →
      LidoSRv3.Audit.Verity.AddressTx.observeAddress (renameInput a₁ a₂ inp)
          ((LidoSRv3.Audit.Verity.AddressTx.executePinnedSource
              (renameInput a₁ a₂ inp)).run
            (LidoSRv3.Audit.Verity.AddressTx.stateFor (renameInput a₁ a₂ inp))) =
        LidoSRv3.Audit.Verity.AddressTx.postAddressView inp.entryPoint
          (renamePost a₁ a₂ post)) := by
  exact ⟨LidoSRv3.Audit.Verity.AddressTx.composed_verity_tx_address_equivariance.1,
    LidoSRv3.Audit.Verity.AddressTx.composed_verity_tx_address_equivariance.2.1,
    LidoSRv3.Audit.Verity.AddressTx.composed_verity_tx_address_equivariance.2.2.2.1,
    LidoSRv3.Audit.Verity.AddressTx.composed_verity_tx_address_equivariance.2.2.2.2.1,
    LidoSRv3.Audit.Verity.AddressTx.composed_verity_tx_address_equivariance.2.2.2.2.2.2.2⟩

/-- Bounded horizontal slice only: MODEL→SOURCE→official-Denote composition
for the owner-operated WithdrawalQueue ERC-721 ownership handoff. This retained
regression theorem is subordinate to the universal parent composition above. -/
theorem bounded_transfer_model_source_tx :
    (∀ caller fromAddr to s, sourceTransfer caller fromAddr to s =
      modelTransfer caller fromAddr to s) ∧
    sourceTransfer 1 1 3 { owner := 1, approved := 9 } = some { owner := 3, approved := 0 } ∧
    sourceTransfer 2 2 (swap12 3) (renameState12 { owner := 1, approved := 9 }) =
      (sourceTransfer 1 1 3 { owner := 1, approved := 9 }).map renameState12 ∧
    observe (run 1 1 3 1 9) = (true, 3, 0) ∧
    observe (run 2 2 (swap12 3) (renameState12 { owner := 1, approved := 9 }).owner
      (renameState12 { owner := 1, approved := 9 }).approved) =
      (true, swap12 3, swap12 0) ∧
    swap12 3 != 4 ∧ swap12 9 != 8 ∧
    observe (run 9 1 3 1 9) = (false, 1, 9) :=
  model_source_tx_address_equivariance_slice

end LidoSRv3.Audit.Guarantees.PAddress1
