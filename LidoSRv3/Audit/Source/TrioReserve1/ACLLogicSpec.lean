import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLLogicSpec

/-- Independent control result after the first child has returned. A visit
identifies the only further child evaluated and whether its bool is negated. -/
inductive Route where
  | finish (value : Bool)
  | visit (index : Nat) (negate : Bool)
  deriving DecidableEq

inductive Describes (op second third : Nat) (first : Bool) : Route → Prop
  | conditional (h : op = 12) : Describes op second third first
      (.visit (if first then second else third) false)
  | negate (h : op = 8) : Describes op second third first (.finish (!first))
  | or_short (h : op = 10) (hf : first = true) : Describes op second third first (.finish true)
  | and_short (h : op = 9) (hf : first = false) : Describes op second third first (.finish false)
  | binary (hc : op ≠ 12) (hn : op ≠ 8) (hor : op ≠ 10 ∨ first = false)
      (hand : op ≠ 9 ∨ first = true) : Describes op second third first
        (.visit second (decide (op = 11) && first))

theorem exists_route (op second third : Nat) (first : Bool) :
    ∃ route, Describes op second third first route := by
  by_cases hc : op = 12
  · exact ⟨_, .conditional hc⟩
  by_cases hn : op = 8
  · exact ⟨_, .negate hn⟩
  by_cases ho : op = 10
  · cases first
    · exact ⟨_, .binary hc hn (Or.inr rfl) (Or.inl (by omega))⟩
    · exact ⟨_, .or_short ho rfl⟩
  by_cases ha : op = 9
  · cases first
    · exact ⟨_, .and_short ha rfl⟩
    · exact ⟨_, .binary hc hn (Or.inl ho) (Or.inr rfl)⟩
  exact ⟨_, .binary hc hn (Or.inl ho) (Or.inl ha)⟩

theorem unique (op second third : Nat) (first : Bool) (a b : Route)
    (ha : Describes op second third first a) (hb : Describes op second third first b) : a = b := by
  cases ha <;> cases hb <;> simp_all <;> omega

end LidoSRv3.Audit.Source.TrioReserve1.ACLLogicSpec
