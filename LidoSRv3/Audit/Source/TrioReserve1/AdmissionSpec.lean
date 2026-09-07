/-! Independent ordered admission rules. Observations must be related to actual
queue/router calls and the post-bunker-call pause word by the source theorem.
This specification does not replace CALL/ABI failures with a permission flag. -/
namespace LidoSRv3.Audit.Source.TrioReserve1.AdmissionSpec

structure Observations where
  bunker : Nat
  active : Nat
  caller : Nat
  router : Nat
  amount : Nat

inductive Verdict where
  | allowed
  | cannotDeposit
  | unauthorized
  | zeroAmount

def Describes (o : Observations) : Verdict → Prop
  | .cannotDeposit => o.bunker ≠ 0 ∨ o.active = 0
  | .unauthorized => o.bunker = 0 ∧ o.active ≠ 0 ∧ o.caller ≠ o.router
  | .zeroAmount => o.bunker = 0 ∧ o.active ≠ 0 ∧ o.caller = o.router ∧ o.amount = 0
  | .allowed => o.bunker = 0 ∧ o.active ≠ 0 ∧ o.caller = o.router ∧ o.amount ≠ 0

end LidoSRv3.Audit.Source.TrioReserve1.AdmissionSpec
