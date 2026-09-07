import LidoSRv3.Audit.Source.TrioReserve1.ACLTreeSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLPermissionSpec
open ACLTreeSpec

/-- A stored permission either denies because it is absent, grants unconditionally,
or evaluates its parameter graph. Presence is checked before the parameter hash. -/
inductive Attempt {Event : Type} (present unconditional : Prop)
    (tree : Outcome → List Event → Prop) : Outcome → List Event → Prop where
  | absent (h : ¬present) : Attempt present unconditional tree (.value false) []
  | unconditional (hp : present) (hu : unconditional) : Attempt present unconditional tree (.value true) []
  | parameters {outcome trace} (hp : present) (hu : ¬unconditional) (ht : tree outcome trace) :
      Attempt present unconditional tree outcome trace

/-- Permission lookup is ordered. Specific success or failure never requires a
wildcard derivation; only specific denial visits the wildcard permission. -/
inductive Select {Event : Type} (specific wildcard : Outcome → List Event → Prop) :
    Outcome → List Event → Prop where
  | accepted {trace} (h : specific (.value true) trace) : Select specific wildcard (.value true) trace
  | failed {trace} (h : specific .invalidOpcode trace) : Select specific wildcard .invalidOpcode trace
  | fallback {left right outcome} (hs : specific (.value false) left) (hw : wildcard outcome right) :
      Select specific wildcard outcome (left ++ right)

end LidoSRv3.Audit.Source.TrioReserve1.ACLPermissionSpec
