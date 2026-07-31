namespace LidoSRv3.Audit.Common

/-!
Attempted effects are evidence about execution. Only committed effects become
externally visible on success; a revert has no committed post-state.
-/

inductive Result (State Attempt Effect : Type)
  | success (after : State) (attempted : List Attempt) (committed : List Effect)
  | revert (attempted : List Attempt)
  deriving Repr

def Result.attempted :
    Result State Attempt Effect → List Attempt
  | .success _ attempted _ => attempted
  | .revert attempted => attempted

def Result.committed :
    Result State Attempt Effect → List Effect
  | .success _ _ committed => committed
  | .revert _ => []

def Result.stateAfter (before : State) :
    Result State Attempt Effect → State
  | .success after _ _ => after
  | .revert _ => before

@[simp] theorem Result.revert_committed
    (attempted : List Attempt) :
    (Result.revert attempted : Result State Attempt Effect).committed = [] := rfl

end LidoSRv3.Audit.Common
