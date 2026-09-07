import LidoSRv3.Audit.Source.TrioReserve1.ACLLogicSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLTreeSpec

inductive Outcome where
  | value (allowed : Bool)
  | invalidOpcode
  deriving DecidableEq

inductive Node where
  | atom
  | missing
  | invalid
  | logic (op first second third : Nat)
  deriving DecidableEq

/-- Fuel-free finite evaluation of an indexed graph. Cycles are not forbidden;
only the children selected by the control relation need finite derivations.
The independent leaf relation is explicit and may include oracle observations. -/
inductive Evaluates {Event : Type} (nodes : Nat → Node)
    (leaf : Nat → Outcome → List Event → Prop) : Nat → Outcome → List Event → Prop
  | atom {i result trace} (hn : nodes i = .atom) (hl : leaf i result trace) :
      Evaluates nodes leaf i result trace
  | missing {i} (hn : nodes i = .missing) : Evaluates nodes leaf i (.value false) []
  | invalid {i} (hn : nodes i = .invalid) : Evaluates nodes leaf i .invalidOpcode []
  | first_failure {i op a b c trace} (hn : nodes i = .logic op a b c)
      (ha : Evaluates nodes leaf a .invalidOpcode trace) :
      Evaluates nodes leaf i .invalidOpcode trace
  | finish {i op a b c first result trace} (hn : nodes i = .logic op a b c)
      (ha : Evaluates nodes leaf a (.value first) trace)
      (hr : ACLLogicSpec.Describes op b c first (.finish result)) :
      Evaluates nodes leaf i (.value result) trace
  | visit {i op a b c first next negate result left right} (hn : nodes i = .logic op a b c)
      (ha : Evaluates nodes leaf a (.value first) left)
      (hr : ACLLogicSpec.Describes op b c first (.visit next negate))
      (hb : Evaluates nodes leaf next (.value result) right) :
      Evaluates nodes leaf i (.value (if negate then !result else result)) (left ++ right)
  | visit_failure {i op a b c first next negate left right} (hn : nodes i = .logic op a b c)
      (ha : Evaluates nodes leaf a (.value first) left)
      (hr : ACLLogicSpec.Describes op b c first (.visit next negate))
      (hb : Evaluates nodes leaf next .invalidOpcode right) :
      Evaluates nodes leaf i .invalidOpcode (left ++ right)

end LidoSRv3.Audit.Source.TrioReserve1.ACLTreeSpec
