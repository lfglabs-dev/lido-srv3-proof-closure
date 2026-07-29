import LidoSRv3.Audit.Arithmetic
import Verity.Core.Address

namespace LidoSRv3.Audit

/-!
# Minimal transaction observations

This is an audit vocabulary, not an EVM. Attempted calls are ghost evidence.
Only the committed branch can expose state changes, value movement, or logs.
-/

open Verity

structure CallAttempt where
  target : Address
  value : Wei
  selector : Uint256
  deriving DecidableEq, Repr

structure EthMove where
  sender : Address
  recipient : Address
  amount : Wei
  deriving DecidableEq, Repr

structure LogEntry where
  emitter : Address
  topic0 : Uint256
  data : List Uint256
  deriving DecidableEq, Repr

structure CommitTrace where
  calls : List CallAttempt
  ethMoves : List EthMove
  logs : List LogEntry
  deriving DecidableEq, Repr

inductive TxResult (State : Type)
  | reverted
  | committed (after : State) (trace : CommitTrace)
  deriving Repr

/-- The pre-state and attempts remain observable even when the call reverts. -/
structure TxObservation (State : Type) where
  before : State
  attemptedCalls : List CallAttempt
  result : TxResult State
  deriving Repr

def TxObservation.committedState (tx : TxObservation State) : State :=
  match tx.result with
  | .reverted => tx.before
  | .committed after _ => after

def TxObservation.committedTrace (tx : TxObservation State) : CommitTrace :=
  match tx.result with
  | .reverted => ⟨[], [], []⟩
  | .committed _ trace => trace

theorem revert_restores_state_value_and_logs
    (tx : TxObservation State) (h : tx.result = .reverted) :
    tx.committedState = tx.before ∧
      tx.committedTrace.ethMoves = [] ∧
      tx.committedTrace.logs = [] := by
  simp [TxObservation.committedState, TxObservation.committedTrace, h]

theorem revert_may_retain_attempts
    (before : State) (attempts : List CallAttempt) :
    (TxObservation.mk before attempts (.reverted : TxResult State)).attemptedCalls =
      attempts := rfl

end LidoSRv3.Audit
