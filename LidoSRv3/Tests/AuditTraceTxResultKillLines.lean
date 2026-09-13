import LidoSRv3.Audit.Trace

/-! # Kill-lines for `Audit.Trace.TxObservation` semantics

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the audit-vocabulary rollback semantics: reverted transactions do
not commit state or logs, but retain attempted-call ghost evidence. -/

namespace LidoSRv3.Tests.AuditTraceTxResultKillLines

open LidoSRv3.Audit

/-- **Kill-line: reverted committedState = before.** -/
theorem reverted_committedState (State : Type) (before : State)
    (attempts : List CallAttempt) :
    (TxObservation.mk before attempts (.reverted : TxResult State)).committedState =
      before := rfl

/-- **Kill-line: reverted committedTrace has empty calls / ethMoves / logs.** -/
theorem reverted_committedTrace_empty (State : Type) (before : State)
    (attempts : List CallAttempt) :
    (TxObservation.mk before attempts (.reverted : TxResult State)).committedTrace =
      ⟨[], [], []⟩ := rfl

/-- **Kill-line: reverted committedTrace has no eth moves.** -/
theorem reverted_no_ethMoves (State : Type) (before : State)
    (attempts : List CallAttempt) :
    (TxObservation.mk before attempts (.reverted : TxResult State)).committedTrace.ethMoves =
      [] := rfl

/-- **Kill-line: reverted committedTrace has no logs.** -/
theorem reverted_no_logs (State : Type) (before : State)
    (attempts : List CallAttempt) :
    (TxObservation.mk before attempts (.reverted : TxResult State)).committedTrace.logs =
      [] := rfl

/-- **Kill-line: attempted calls preserved on revert (ghost evidence).**

Reverted transactions still expose their attempted-call list to
the audit vocabulary. -/
theorem reverted_retains_attempts (State : Type) (before : State)
    (attempts : List CallAttempt) :
    (TxObservation.mk before attempts (.reverted : TxResult State)).attemptedCalls =
      attempts := rfl

/-- **Kill-line: committed committedState = after (custom).** -/
theorem committed_committedState (State : Type) (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) :
    (TxObservation.mk before attempts (.committed after trace)).committedState =
      after := rfl

/-- **Kill-line: committed committedTrace preserves the trace.** -/
theorem committed_committedTrace (State : Type) (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) :
    (TxObservation.mk before attempts (.committed after trace)).committedTrace =
      trace := rfl

/-- **Kill-line: TxResult.reverted and TxResult.committed are distinct.** -/
theorem txResult_reverted_ne_committed (State : Type) [Inhabited State]
    (after : State) (trace : CommitTrace) :
    (TxResult.reverted : TxResult State) ≠ TxResult.committed after trace := by
  intro h; cases h

#print axioms reverted_committedState
#print axioms reverted_committedTrace_empty
#print axioms reverted_retains_attempts
#print axioms committed_committedState
#print axioms committed_committedTrace
#print axioms txResult_reverted_ne_committed

end LidoSRv3.Tests.AuditTraceTxResultKillLines
