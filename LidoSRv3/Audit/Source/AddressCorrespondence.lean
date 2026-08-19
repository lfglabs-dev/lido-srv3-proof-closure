import LidoSRv3.Audit.AddressEquivariance

/-!
# P-ADDRESS-1 pinned-source correspondence

This module is a source-shaped, single-item reading of the four permissionless
entrypoints mapped at `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.
The single-item restriction removes only batch iteration; it retains every
caller/address-dependent guard and successful address write in the mapped
paths.  Non-address arithmetic and external-contract return values are explicit
inputs.  This is SOURCE evidence, not compiler/Yul/EVM evidence.
-/

namespace LidoSRv3.Audit.SolidityAddress

open Verity

def renameAddress (a₁ a₂ x : Address) : Address :=
  if x = a₁ then a₂ else if x = a₂ then a₁ else x

theorem renameAddress_involutive (a₁ a₂ : Address) :
    ∀ x, renameAddress a₁ a₂ (renameAddress a₁ a₂ x) = x := by
  intro x
  by_cases h₁ : x = a₁
  · subst x
    by_cases h : a₁ = a₂ <;> simp [renameAddress, h]
  · by_cases h₂ : x = a₂
    · subst x; simp [renameAddress, h₁]
    · simp [renameAddress, h₁, h₂]

theorem renameAddress_injective (a₁ a₂ : Address) :
    Function.Injective (renameAddress a₁ a₂) := by
  intro x y h
  have h' := congrArg (renameAddress a₁ a₂) h
  simpa only [renameAddress_involutive] using h'

inductive EntryPoint where
  | transferFrom | requestWithdrawals | claimWithdrawalsTo | unwrap
  deriving DecidableEq, Repr

structure Input where
  entryPoint : EntryPoint
  caller : Address
  senderFrom : Address
  recipient : Address
  requestOwner : Address
  amount : Nat
  requestId : Nat
  paused : Bool
  requestExists : Bool
  requestClaimed : Bool
  requestFinalized : Bool
  hintValid : Bool
  callerIsApprovedForAll : Bool
  callerIsTokenApproved : Bool
  amountInRange : Bool
  callerBalanceSufficient : Bool
  callerAllowanceSufficient : Bool
  externalCallSucceeds : Bool

/-- Successful address-bearing writes/returns observable at the mapped boundary. -/
structure PostState where
  owner : Address
  recipient : Address
  callerBalanceDebited : Address
  callerBalanceCredited : Address
  deriving DecidableEq, Repr

inductive Outcome where
  | reverted
  | committed (post : PostState)
  deriving DecidableEq, Repr

def succeeds : Outcome → Bool
  | .reverted => false
  | .committed _ => true

/-- Well-formedness for the registered P-ADDRESS-1 parent: amount stays below 2^256
and the caller-indexed balance/allowance flags are coherent with a nonzero amount. -/
def wellFormedAddressInput (inp : Input) : Prop :=
  inp.amount < 2 ^ 256 ∧
  (!inp.callerBalanceSufficient = true → inp.amount ≠ 0) ∧
  (!inp.callerAllowanceSufficient = true → inp.amount ≠ 0)

/-- Singleton-actor protocol entrypoints are excluded from address-equivariance.
The four pinned writers below are not singleton-actor gated; this predicate is
carried explicitly on the parent theorem rather than left implicit in prose. -/
def singletonActorEntryPoint (_ep : EntryPoint) : Prop :=
  False

/-- Scoped entrypoints for the Wave 1 parent: permissionless writers whose
admission is pause plus the caller's own balance/allowance flags. Request-owner
gates and singleton-actor callers are excluded (`claimWithdrawalsTo` deferred). -/
def addressEquivarianceEntryScope (ep : EntryPoint) : Prop :=
  match ep with
  | .transferFrom | .requestWithdrawals | .unwrap => True
  | .claimWithdrawalsTo => False

theorem not_singleton_actor_entry_point (ep : EntryPoint) :
    ¬ singletonActorEntryPoint ep := by
  intro h; cases h

/-- Conjunction of the exact caller/address guards on the mapped single-item paths. -/
def admitted (inp : Input) : Bool :=
  match inp.entryPoint with
  | .transferFrom =>
      decide (inp.recipient ≠ 0) && decide (inp.recipient ≠ inp.senderFrom) &&
        inp.requestExists && !inp.requestClaimed && decide (inp.senderFrom = inp.requestOwner) &&
        (decide (inp.caller = inp.requestOwner) || inp.callerIsApprovedForAll ||
          inp.callerIsTokenApproved)
  | .requestWithdrawals =>
      !inp.paused && inp.amountInRange && inp.callerBalanceSufficient &&
        inp.callerAllowanceSufficient && inp.externalCallSucceeds
  | .claimWithdrawalsTo =>
      decide (inp.recipient ≠ 0) && inp.requestExists && !inp.requestClaimed &&
        inp.requestFinalized && inp.hintValid && decide (inp.caller = inp.requestOwner) &&
        inp.externalCallSucceeds
  | .unwrap =>
      decide (inp.amount ≠ 0) && inp.callerBalanceSufficient && inp.externalCallSucceeds

/-- Permissionless admission on pause/balance/allowance entrypoints only. It
deliberately omits any fixed `caller = owner` test. -/
def permissionlessAdmission (inp : Input) : Bool :=
  match inp.entryPoint with
  | .requestWithdrawals =>
      !inp.paused && inp.amountInRange && inp.callerBalanceSufficient &&
        inp.callerAllowanceSufficient && inp.externalCallSucceeds
  | .unwrap =>
      decide (inp.amount ≠ 0) && inp.callerBalanceSufficient && inp.externalCallSucceeds
  | _ => admitted inp

theorem pause_balance_admitted_is_permissionless (inp : Input)
    (hScope : inp.entryPoint = .requestWithdrawals ∨ inp.entryPoint = .unwrap) :
    admitted inp = permissionlessAdmission inp := by
  rcases hScope with h | h <;> simp [admitted, permissionlessAdmission, h]

def successfulPost (inp : Input) : PostState :=
  match inp.entryPoint with
  | .transferFrom => ⟨inp.recipient, inp.recipient, inp.senderFrom, inp.recipient⟩
  | .requestWithdrawals =>
      let owner := if inp.recipient = 0 then inp.caller else inp.recipient
      ⟨owner, owner, inp.caller, owner⟩
  | .claimWithdrawalsTo => ⟨inp.caller, inp.recipient, inp.caller, inp.recipient⟩
  | .unwrap => ⟨inp.caller, inp.caller, inp.caller, inp.caller⟩

def run (inp : Input) : Outcome :=
  if admitted inp then .committed (successfulPost inp) else .reverted

def renameInput (a₁ a₂ : Address) (inp : Input) : Input :=
  { inp with
    caller := renameAddress a₁ a₂ inp.caller
    senderFrom := renameAddress a₁ a₂ inp.senderFrom
    recipient := renameAddress a₁ a₂ inp.recipient
    requestOwner := renameAddress a₁ a₂ inp.requestOwner }

def renamePost (a₁ a₂ : Address) (post : PostState) : PostState :=
  { owner := renameAddress a₁ a₂ post.owner
    recipient := renameAddress a₁ a₂ post.recipient
    callerBalanceDebited := renameAddress a₁ a₂ post.callerBalanceDebited
    callerBalanceCredited := renameAddress a₁ a₂ post.callerBalanceCredited }

def Eligible (inp : Input) : Prop := run inp ≠ .reverted

/-- Caller-indexed balance/allowance/approval observations and the request and
pause facts are transported unchanged when every address key is renamed. -/
theorem renameInput_preserves_indexed_facts (a₁ a₂ : Address) (inp : Input) :
    let renamed := renameInput a₁ a₂ inp
    renamed.callerBalanceSufficient = inp.callerBalanceSufficient ∧
    renamed.callerAllowanceSufficient = inp.callerAllowanceSufficient ∧
    renamed.callerIsApprovedForAll = inp.callerIsApprovedForAll ∧
    renamed.callerIsTokenApproved = inp.callerIsTokenApproved ∧
    renamed.requestExists = inp.requestExists ∧
    renamed.requestClaimed = inp.requestClaimed ∧
    renamed.requestFinalized = inp.requestFinalized ∧
    renamed.paused = inp.paused ∧
    renamed.requestOwner = renameAddress a₁ a₂ inp.requestOwner := by
  simp [renameInput]

/-- A swap away from the zero address preserves all source address guards. -/
theorem run_rename (a₁ a₂ : Address) (h₁ : a₁ ≠ 0) (h₂ : a₂ ≠ 0) (inp : Input) :
    run (renameInput a₁ a₂ inp) =
      match run inp with
      | .reverted => .reverted
      | .committed post => .committed (renamePost a₁ a₂ post) := by
  have hz : renameAddress a₁ a₂ 0 = 0 := by
    simp [renameAddress, Ne.symm h₁, Ne.symm h₂]
  have hinj := renameAddress_injective a₁ a₂
  have hzero (x : Address) : renameAddress a₁ a₂ x = 0 ↔ x = 0 := by
    constructor
    · intro h; apply hinj; exact h.trans hz.symm
    · intro h; subst x; exact hz
  have hadmitted : admitted (renameInput a₁ a₂ inp) = admitted inp := by
    cases inp.entryPoint <;>
      simp [admitted, renameInput, hzero, hinj.eq_iff]
  have hpost : successfulPost (renameInput a₁ a₂ inp) =
      renamePost a₁ a₂ (successfulPost inp) := by
    by_cases hr : inp.recipient = 0 <;>
      cases hentry : inp.entryPoint <;>
      simp_all [successfulPost, renameInput, renamePost]
  by_cases h : admitted inp <;> simp [run, hadmitted, hpost, h]

theorem source_admission_nondiscriminatory
    (a₁ a₂ : Address) (h₁ : a₁ ≠ 0) (h₂ : a₂ ≠ 0) (inp : Input) :
    succeeds (run (renameInput a₁ a₂ inp)) = succeeds (run inp) := by
  rw [run_rename a₁ a₂ h₁ h₂ inp]
  cases run inp <;> rfl

theorem source_success_post_state_equivariant
    (a₁ a₂ : Address) (h₁ : a₁ ≠ 0) (h₂ : a₂ ≠ 0) (inp : Input) (post : PostState)
    (h : run inp = .committed post) :
    run (renameInput a₁ a₂ inp) = .committed (renamePost a₁ a₂ post) := by
  rw [run_rename a₁ a₂ h₁ h₂ inp, h]

end LidoSRv3.Audit.SolidityAddress
