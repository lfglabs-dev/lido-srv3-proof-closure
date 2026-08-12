import LidoSRv3.Audit.Trace

namespace LidoSRv3.Audit.AddressEquivariance

open Verity
open LidoSRv3.Audit

/-!
# Abstract address renaming

This module only renames the address-bearing fields of the abstract transaction
vocabulary.  It does not model Yul, bytecode, storage, or EVM execution.
-/

/-- An address renaming is injective, so distinct actors remain distinct. -/
structure Renaming where
  apply : Address → Address
  injective : Function.Injective apply

instance : CoeFun Renaming (fun _ => Address → Address) := ⟨Renaming.apply⟩

def renameCall (rho : Renaming) (call : CallAttempt) : CallAttempt :=
  { call with target := rho call.target }

def renameMove (rho : Renaming) (move : EthMove) : EthMove :=
  { move with sender := rho move.sender, recipient := rho move.recipient }

def renameLog (rho : Renaming) (entry : LogEntry) : LogEntry :=
  { entry with emitter := rho entry.emitter }

def renameTrace (rho : Renaming) (trace : CommitTrace) : CommitTrace :=
  { calls := trace.calls.map (renameCall rho)
  , ethMoves := trace.ethMoves.map (renameMove rho)
  , logs := trace.logs.map (renameLog rho) }

def renameResult (rho : Renaming) (renameState : State → State) :
    TxResult State → TxResult State
  | .reverted => .reverted
  | .committed after trace => .committed (renameState after) (renameTrace rho trace)

def renameObservation (rho : Renaming) (renameState : State → State)
    (tx : TxObservation State) : TxObservation State :=
  { before := renameState tx.before
  , attemptedCalls := tx.attemptedCalls.map (renameCall rho)
  , result := renameResult rho renameState tx.result }

/-- Exact bounded relation: the right observation is the field-wise renaming of the left. -/
def Equivariant (rho : Renaming) (renameState : State → State)
    (left right : TxObservation State) : Prop :=
  right = renameObservation rho renameState left

theorem rename_is_equivariant (rho : Renaming) (renameState : State → State)
    (tx : TxObservation State) :
    Equivariant rho renameState tx (renameObservation rho renameState tx) := rfl

theorem rename_reverted (rho : Renaming) (renameState : State → State)
    (before : State) (attempts : List CallAttempt) :
    renameObservation rho renameState ⟨before, attempts, .reverted⟩ =
      ⟨renameState before, attempts.map (renameCall rho), .reverted⟩ := rfl

theorem rename_committed (rho : Renaming) (renameState : State → State)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace) :
    renameObservation rho renameState ⟨before, attempts, .committed after trace⟩ =
      ⟨renameState before, attempts.map (renameCall rho),
        .committed (renameState after) (renameTrace rho trace)⟩ := rfl

theorem renamed_move_preserves_distinct_actors (rho : Renaming) (move : EthMove)
    (h : move.sender ≠ move.recipient) :
    (renameMove rho move).sender ≠ (renameMove rho move).recipient := by
  simpa [renameMove] using rho.injective.ne h

end LidoSRv3.Audit.AddressEquivariance
