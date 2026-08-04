import LidoSRv3.Audit.AddressEquivariance

namespace LidoSRv3.Tests.AddressEquivariance

open Verity
open LidoSRv3.Audit
open LidoSRv3.Audit.AddressEquivariance

/-! Parametric vectors make every address position and non-address payload load-bearing. -/

theorem call_vector (rho : Renaming) (target : Address) (value : Wei)
    (selector : Uint256) :
    renameCall rho ⟨target, value, selector⟩ = ⟨rho target, value, selector⟩ := rfl

theorem move_vector (rho : Renaming) (sender recipient : Address) (amount : Wei) :
    renameMove rho ⟨sender, recipient, amount⟩ =
      ⟨rho sender, rho recipient, amount⟩ := rfl

theorem log_vector (rho : Renaming) (emitter : Address) (topic0 : Uint256)
    (data : List Uint256) :
    renameLog rho ⟨emitter, topic0, data⟩ = ⟨rho emitter, topic0, data⟩ := rfl

/-- A sender/recipient swap mutant is rejected whenever the actors differ. -/
theorem rejects_swapped_move_mutant (rho : Renaming) (sender recipient : Address)
    (amount : Wei) (h : sender ≠ recipient) :
    renameMove rho ⟨sender, recipient, amount⟩ ≠
      ⟨rho recipient, rho sender, amount⟩ := by
  intro equality
  have : rho sender = rho recipient := congrArg EthMove.sender equality
  exact h (rho.injective this)

/-- A dropped-call mutant is rejected for every singleton attempted-call trace. -/
theorem rejects_dropped_attempt_mutant (rho : Renaming) (before : State)
    (call : CallAttempt) :
    (renameObservation rho id
      (⟨before, [call], .reverted⟩ : TxObservation State)).attemptedCalls ≠ [] := by
  simp [renameObservation]

/-- A committed singleton call is retained and its address is renamed. -/
theorem committed_call_trace_vector (rho : Renaming) (before after : State)
    (target : Address) (value : Wei) (selector : Uint256) :
    (renameObservation rho id
      (⟨before, [], .committed after ⟨[⟨target, value, selector⟩], [], []⟩⟩ :
        TxObservation State)).committedTrace.calls =
      [⟨rho target, value, selector⟩] := rfl

end LidoSRv3.Tests.AddressEquivariance
