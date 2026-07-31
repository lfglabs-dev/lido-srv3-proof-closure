import LidoSRv3.Audit.Common.Result
import LidoSRv3.Audit.Common.Trace

namespace LidoSRv3.Audit.Common

structure Observation (State : Type) where
  before : State
  result : Result State Attempt Effect
  deriving Repr

def Observation.stateAfter (observation : Observation State) : State :=
  observation.result.stateAfter observation.before

def Observation.trace (observation : Observation State) : Trace :=
  { attempted := observation.result.attempted
    committed := observation.result.committed }

theorem revert_rolls_back_state_and_committed_effects
    (before : State) (attempted : List Attempt) :
    let observation : Observation State :=
      ⟨before, .revert attempted⟩
    observation.stateAfter = before ∧
      observation.trace.attempted = attempted ∧
      observation.trace.committed = [] := by
  simp [Observation.stateAfter, Observation.trace, Result.stateAfter,
    Result.attempted, Result.committed]

theorem success_exposes_exact_committed_effects
    (before after : State) (attempted : List Attempt)
    (committed : List Effect) :
    let observation : Observation State :=
      ⟨before, .success after attempted committed⟩
    observation.stateAfter = after ∧
      observation.trace.attempted = attempted ∧
      observation.trace.committed = committed := by
  simp [Observation.stateAfter, Observation.trace, Result.stateAfter,
    Result.attempted, Result.committed]

end LidoSRv3.Audit.Common
