import LidoSRv3.Audit.Source.TrioComposition.ReserveLeafAllocation
import LidoSRv3.Audit.Source.TrioComposition.ReserveLeafFrame
import LidoSRv3.Audit.Source.TrioReserve1.Spend

/-! Both final spending-stage leaves are replaced by independent exhaustive
lookup/CALL/ABI/partition rules. Saved accounting and all returned worlds retain
their source order; the withdrawal parent owns root rollback. Raw adversarial
CALL and deployed/physical primitive interpretation remain explicit boundaries.
-/
namespace LidoSRv3.Audit.Source.TrioComposition.ReserveLeafSpend
open TrioReserve1
open TrioReserve1.Live

def Describes (external : External) (ctx : Context) (amount : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  SpendSpec.Executes (.reason "NOT_ENOUGH_ETHER") amount.val
    (fun a : Live.Allocation => a.deposits+a.unreserved)
    (fun a w => Spending.beforeFrame ctx a amount w) (Spend.committed ctx amount)
    (fun w outcome after trace => ReserveLeafAllocation.Describes external ctx w outcome after trace)
    (fun w outcome after trace => ReserveLeafFrame.Describes external ctx w outcome after trace) before

theorem describes_eq (external : External) (ctx : Context) (amount : Word) (before : World) :
    Describes external ctx amount before = Spend.Describes external ctx amount before := by
  have allocation :
      (fun w outcome after trace => ReserveLeafAllocation.Describes external ctx w outcome after trace) =
      (fun w outcome after trace => getBufferedEtherAllocation external ctx w = ⟨outcome,after,trace⟩) := by
    funext w outcome after trace
    exact propext (ReserveLeafAllocation.corresponds external ctx w after outcome trace)
  have frame :
      (fun w outcome after trace => ReserveLeafFrame.Describes external ctx w outcome after trace) =
      (fun w outcome after trace => getCurrentFrame external ctx w = ⟨outcome,after,trace⟩) := by
    funext w outcome after trace
    exact propext (ReserveLeafFrame.corresponds external ctx w after outcome trace)
  unfold Describes Spend.Describes
  rw [allocation,frame]

theorem corresponds (external : External) (ctx : Context) (amount : Word) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes external ctx amount before outcome after trace ↔
      spendDepositableEther external ctx amount before = ⟨outcome,after,trace⟩ := by
  rw [describes_eq]
  exact Spend.corresponds external ctx amount before after outcome trace

def Withdrawal (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => Lookup.Status external ctx w outcome after trace)
    (fun w outcome after trace => Lookup.Describes external ctx 0xef6c064c w outcome after trace)
    (fun w outcome after trace => Describes external ctx amount w outcome after trace)
    (fun router w outcome after trace => Tail.Describes external ctx router amount seeds w outcome after trace) before

/-- Exhaustive parent equivalence, including every revert and transaction
rollback. No allocation/frame execution equality remains in this independent
parent relation, and no callee success or desired reserve property is assumed. -/
theorem withdrawal_corresponds (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawal external ctx amount seeds before outcome after trace ↔
      run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome,after,trace⟩ := by
  have spending :
      (fun w outcome after trace => Describes external ctx amount w outcome after trace) =
      (fun w outcome after trace => Spend.Describes external ctx amount w outcome after trace) := by
    funext w outcome after trace
    rw [describes_eq]
  unfold Withdrawal
  rw [spending]
  exact Spend.withdrawal_corresponds external ctx amount seeds before after outcome trace

#print axioms corresponds
#print axioms withdrawal_corresponds
end LidoSRv3.Audit.Source.TrioComposition.ReserveLeafSpend
