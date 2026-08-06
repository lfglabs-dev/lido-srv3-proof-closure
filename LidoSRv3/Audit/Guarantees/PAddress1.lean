import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.AddressEquivariance

namespace LidoSRv3.Audit.Guarantees.PAddress1

/-- Abstract-transaction evidence only; no Yul, bytecode, or Verity projection. -/
def guarantee : Guarantee := ⟨.pAddress1, [.model, .abstractTx]⟩

/-- The bounded observation renamer satisfies the exact abstract equivariance relation. -/
theorem abstract_address_equivariance
    (rho : LidoSRv3.Audit.AddressEquivariance.Renaming)
    (renameState : State → State) (tx : LidoSRv3.Audit.TxObservation State) :
    LidoSRv3.Audit.AddressEquivariance.Equivariant rho renameState tx
      (LidoSRv3.Audit.AddressEquivariance.renameObservation rho renameState tx) :=
  LidoSRv3.Audit.AddressEquivariance.rename_is_equivariant rho renameState tx

/-!
## Role-indexed non-discrimination model

`onlyRole` is deliberately not an ordinary precondition here.  Caller identity
is represented only by the role assignment: callers in the same role must have
the same result for the same ordinary input.
-/

open Verity
open LidoSRv3.Audit
open LidoSRv3.Audit.AddressEquivariance

/-- Human-readable role identifiers used by the pinned contracts. -/
abbrev Role := String

/-- The role (if any) assigned to each caller address. -/
def RoleAssignment := Address → Option Role

/-- Inputs shared by the abstract transfer and redemption operations. -/
structure Input where
  amount : Nat
  recipient : Option Address
  deadline : Nat
  blockTimestamp : Nat

/-- The only global switch relevant to this bounded model. -/
structure Config where
  paused : Bool

/-- Transfer/redemption outcomes use the campaign's existing transaction observation. -/
abbrev Outcome (State : Type) := TxObservation State

/-- Two callers are role-equivalent when both carry the same assigned role. -/
def same_role (roles : RoleAssignment) (a₁ a₂ : Address) : Prop :=
  roles a₁ = roles a₂ ∧ (roles a₁).isSome

/-- Preconditions which do not inspect or otherwise depend on caller identity. -/
def ordinary_preconditions (inp : Input) : Prop :=
  inp.amount > 0 ∧ inp.recipient.isSome ∧ inp.deadline > inp.blockTimestamp

/-- Same role and same ordinary inputs cannot produce selectively different outcomes. -/
def not_selectively_blocked (fn : Address → Input → Outcome State)
    (roles : RoleAssignment) (cfg : Config) : Prop :=
  ∀ (a₁ a₂ : Address) (inp : Input),
    same_role roles a₁ a₂ →
    ordinary_preconditions inp →
    cfg.paused = false →
    fn a₁ inp = fn a₂ inp

/-- The operation commutes with the existing abstract address-renaming relation. -/
def address_equivariant (fn : Address → Input → Outcome State) : Prop :=
  ∀ (rho : Renaming) (renameState : State → State) (a : Address) (inp : Input),
    Equivariant rho renameState (fn a inp) (fn (rho a) inp)

/-- Ordinary behavior is invariant under a role-compatible caller renaming. -/
def role_invariant_on_ordinary_inputs (fn : Address → Input → Outcome State)
    (roles : RoleAssignment) : Prop :=
  ∀ (a₁ a₂ : Address) (inp : Input),
    same_role roles a₁ a₂ → ordinary_preconditions inp →
    ∃ rho : Renaming,
      rho a₁ = a₂ ∧ renameObservation rho id (fn a₁ inp) = fn a₁ inp

/-- Existing address equivariance, restricted to ordinary role-invariant behavior,
rules out selective blocking by the concrete caller address. -/
theorem equivariance_implies_not_blocked
    (fn : Address → Input → Outcome State)
    (roles : RoleAssignment) (cfg : Config)
    (h_equiv : address_equivariant fn)
    (h_ordinary : role_invariant_on_ordinary_inputs fn roles) :
    not_selectively_blocked fn roles cfg := by
  intro a₁ a₂ inp hrole hord _
  obtain ⟨rho, hrho, hinvariant⟩ := h_ordinary a₁ a₂ inp hrole hord
  have hcanonical :
      Equivariant rho id (fn a₁ inp) (renameObservation rho id (fn a₁ inp)) :=
    abstract_address_equivariance rho id (fn a₁ inp)
  have hrenamed : fn (rho a₁) inp = renameObservation rho id (fn a₁ inp) :=
    h_equiv rho id a₁ inp
  rw [← hrho, hrenamed, hinvariant]

/-- A transaction observation records success exactly when it committed. -/
def succeeds (out : Outcome State) : Prop :=
  ∃ after trace, out.result = .committed after trace

/-- Every assigned role has a caller for which an ordinary active call succeeds. -/
def representative_success (fn : Address → Input → Outcome State)
    (roles : RoleAssignment) (cfg : Config) : Prop :=
  ∀ (a : Address) (inp : Input),
    (roles a).isSome → ordinary_preconditions inp → cfg.paused = false →
    ∃ representative : Address,
      same_role roles representative a ∧ succeeds (fn representative inp)

/-- While globally active, valid transfer/redemption inputs succeed for every
caller in an assigned role, not merely for a favored representative address. -/
theorem global_active_preservation
    (fn : Address → Input → Outcome State)
    (roles : RoleAssignment) (cfg : Config)
    (hnotblocked : not_selectively_blocked fn roles cfg)
    (hrepresentative : representative_success fn roles cfg) :
    ∀ (a : Address) (inp : Input),
      (roles a).isSome → ordinary_preconditions inp → cfg.paused = false →
      succeeds (fn a inp) := by
  intro a inp hrole hord hactive
  obtain ⟨representative, hsame, hsuccess⟩ :=
    hrepresentative a inp hrole hord hactive
  rw [hnotblocked representative a inp hsame hord hactive] at hsuccess
  exact hsuccess

end LidoSRv3.Audit.Guarantees.PAddress1
