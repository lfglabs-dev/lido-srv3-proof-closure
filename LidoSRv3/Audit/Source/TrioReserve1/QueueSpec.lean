/-!
Independent arithmetic specification of the queue's unfinalized demand.
No executable or Verity imports. Cumulative values are related to the low
128 bits of physical queue rows by a separate correspondence relation.
-/
namespace LidoSRv3.Audit.Source.TrioReserve1.QueueSpec

structure State where
  last : Nat
  finalized : Nat
  cumulative : Nat → Nat

inductive Outcome where
  | value (amount : Nat)
  | panic (code : Nat)
  deriving DecidableEq, Repr

/-- Checked subtraction in the source's uint128 expression. Success returns
the unique natural difference; reversed cumulative rows panic with code 0x11. -/
def Describes (s : State) : Outcome → Prop
  | .value amount =>
      s.cumulative s.finalized ≤ s.cumulative s.last ∧
      amount + s.cumulative s.finalized = s.cumulative s.last
  | .panic code =>
      s.cumulative s.last < s.cumulative s.finalized ∧ code = 0x11

end LidoSRv3.Audit.Source.TrioReserve1.QueueSpec
