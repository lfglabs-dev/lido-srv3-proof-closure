import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLSpec

/-- Independent comparison semantics; unsupported comparison operators deny. -/
def Comparison (op a b : Nat) (result : Bool) : Prop :=
  (result = true) ↔ (op = 1 ∧ a = b) ∨ (op = 2 ∧ a ≠ b) ∨
    (op = 3 ∧ a > b) ∨ (op = 4 ∧ a < b) ∨ (op = 5 ∧ a ≥ b) ∨ (op = 6 ∧ a ≤ b)

/-- Permission selection with independently supplied parameter-evaluation facts.
Their physical/source correspondence is a separate obligation. -/
def Grants (hasSpecific specificAllows hasWildcard wildcardAllows result : Bool) : Prop :=
  (result = true) ↔ (hasSpecific = true ∧ specificAllows = true) ∨
    (hasWildcard = true ∧ wildcardAllows = true)

theorem no_permission : Grants false false false false false := by simp [Grants]

theorem specific_short_circuit (wildcard wildcardAllows : Bool) :
    Grants true true wildcard wildcardAllows true := by simp [Grants]

end LidoSRv3.Audit.Source.TrioReserve1.ACLSpec
