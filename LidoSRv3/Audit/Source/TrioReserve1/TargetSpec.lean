namespace LidoSRv3.Audit.Source.TrioReserve1.TargetSpec

/-- Independent transaction rule after authorization. Allowed calls commit the
writer against the world returned by authorization; denial and propagated faults
restore the original transaction world. Attempted calls remain observable. -/
def Completes {State Fault Event : Type} (denied : Fault) (write : State → State)
    (before : State) (authorization : Except Fault Bool) (afterAuthorization : State)
    (calls : List Event) (outcome : Except Fault Unit) (after : State) (trace : List Event) : Prop :=
  match authorization with
  | .ok true => outcome = .ok () ∧ after = write afterAuthorization ∧ trace = calls
  | .ok false => outcome = .error denied ∧ after = before ∧ trace = calls
  | .error fault => outcome = .error fault ∧ after = before ∧ trace = calls

end LidoSRv3.Audit.Source.TrioReserve1.TargetSpec
