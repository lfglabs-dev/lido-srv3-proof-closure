/-! Independent scalar specification of the internal reserve writers.
Production ACL and the enclosing oracle report are separate obligations. -/
namespace LidoSRv3.Audit.Source.TrioReserve1.WriterSpec

structure State where
  buffer : Nat
  reserve : Nat
  target : Nat

/-- Setting a target immediately lowers excess reserve and leaves buffer alone. -/
def Target (before : State) (requested : Nat) (after : State) : Prop :=
  after.buffer = before.buffer ∧ after.target = requested ∧
    after.reserve = min before.reserve requested

/-- Report rebalance raises reserve to its target, without a buffer cap. -/
def Rebalance (before after : State) : Prop :=
  after.buffer = before.buffer ∧ after.target = before.target ∧
    after.reserve = max before.reserve before.target

end LidoSRv3.Audit.Source.TrioReserve1.WriterSpec
