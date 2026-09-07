import LidoSRv3.Audit.Source.TrioReserve1.ACLSpec
import LidoSRv3.Audit.Source.TrioReserve1.ACLTreeSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLLeafSpec

/-- Scalar input selection for leaves without an oracle call. `none` represents
an absent argument, which denies before the operator enum is checked. -/
inductive Input (id stored blockNumber timestamp count : Nat) (argument : Nat → Nat) :
    Option Nat → Prop where
  | block (h : id = 200) : Input id stored blockNumber timestamp count argument (some blockNumber)
  | time (h : id = 201) : Input id stored blockNumber timestamp count argument (some timestamp)
  | stored_value (h : id = 205) : Input id stored blockNumber timestamp count argument (some stored)
  | argument (hb : id ≠ 200) (ht : id ≠ 201) (hc : id ≠ 205) (hi : id < count) :
      Input id stored blockNumber timestamp count argument (some (argument id % 2^240))
  | missing (hb : id ≠ 200) (ht : id ≠ 201) (hc : id ≠ 205) (hi : count ≤ id) :
      Input id stored blockNumber timestamp count argument none

theorem input_exists (id stored blockNumber timestamp count : Nat) (argument : Nat → Nat) :
    ∃ input, Input id stored blockNumber timestamp count argument input := by
  by_cases hb : id = 200
  · exact ⟨_, .block hb⟩
  · by_cases ht : id = 201
    · exact ⟨_, .time ht⟩
    · by_cases hc : id = 205
      · exact ⟨_, .stored_value hc⟩
      · by_cases hi : id < count
        · exact ⟨_, .argument hb ht hc hi⟩
        · exact ⟨_, .missing hb ht hc (by omega)⟩

/-- Operator rules are independent of the source evaluator. Operators 8 through
12 on an atomic parameter are unsupported comparisons and deny; only operators
above 12 fail enum conversion. -/
inductive Evaluates (op compared : Nat) : Option Nat → ACLTreeSpec.Outcome → Prop where
  | missing : Evaluates op compared none (.value false)
  | invalid (value : Nat) (h : 12 < op) : Evaluates op compared (some value) .invalidOpcode
  | ret (value : Nat) (h : op = 7) : Evaluates op compared (some value) (.value (decide (0 < value)))
  | comparison (value : Nat) (answer : Bool) (hv : op ≤ 12) (hr : op ≠ 7)
      (h : ACLSpec.Comparison op value compared answer) :
      Evaluates op compared (some value) (.value answer)

/-- Raw oracle-call acceptance: failure, wrong byte count, or a zero returned
word denies. This is a scalar rule independent of any call interpreter. -/
def OracleAllows (succeeded : Bool) (size decodedWord : Nat) (answer : Bool) : Prop :=
  (answer = true) ↔ succeeded = true ∧ size = 32 ∧ decodedWord ≠ 0

end LidoSRv3.Audit.Source.TrioReserve1.ACLLeafSpec
