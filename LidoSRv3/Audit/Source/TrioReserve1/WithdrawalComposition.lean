import LidoSRv3.Audit.Source.TrioReserve1.Spending
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalTail

namespace LidoSRv3.Audit.Source.TrioReserve1.WithdrawalComposition
open Live

def adjustedNext (ctx : Context) (prepared : World) (nonce : Nat) : Nat :=
  let saved := (prepared.core.readContractSlot ctx.self.val nextSlot).val
  if nonce ≠ saved / width then 0 else saved % width

theorem spending_failure (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w statusWorld routerWorld : World) (fault : Fault)
    (statusTrace routerTrace : List Attempt)
    (hs : canDeposit external ctx w = ⟨.ok true, statusWorld, statusTrace⟩)
    (hr : stakingRouter external ctx statusWorld = ⟨.ok router, routerWorld, routerTrace⟩)
    (hauth : ctx.sender = router) (hn : amount.val ≠ 0)
    (hp : (spendDepositableEther external ctx amount routerWorld).outcome = .error fault) :
    run (withdrawDepositableEther external ctx amount seeds) w =
      ⟨.error fault, w, statusTrace ++ routerTrace ++
        (spendDepositableEther external ctx amount routerWorld).attempts⟩ := by
  simp [run, WithdrawalTail.source_decomposition, bind, bindExec, hs, hr, hauth, hn, hp,
    require, pure, pureExec, List.append_assoc]

/-- The parent no longer assumes successful spending. It composes the actual
allocation and frame executions through all accounting writes and guards.
Router identity remains the value obtained before those external calls. -/
theorem after_frame (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w statusWorld routerWorld allocated framed : World)
    (a : Live.Allocation) (nonce time : Nat)
    (statusTrace routerTrace allocationTrace frameTrace : List Attempt)
    (hs : canDeposit external ctx w = ⟨.ok true, statusWorld, statusTrace⟩)
    (hr : stakingRouter external ctx statusWorld = ⟨.ok router, routerWorld, routerTrace⟩)
    (hauth : ctx.sender = router) (hn : amount.val ≠ 0)
    (ha : getBufferedEtherAllocation external ctx routerWorld = ⟨.ok a, allocated, allocationTrace⟩)
    (hamount : amount.val ≤ a.deposits + a.unreserved)
    (hf : getCurrentFrame external ctx (Spending.beforeFrame ctx a amount allocated) =
      ⟨.ok (nonce, time), framed, frameTrace⟩) :
    let next := adjustedNext ctx (Spending.beforeFrame ctx a amount allocated) nonce
    let spent := Spending.afterFrame ctx amount next nonce framed
    let tail := WithdrawalTail.finish external ctx router amount seeds spent
    withdrawDepositableEther external ctx amount seeds w =
      ⟨tail.outcome, tail.world,
        statusTrace ++ routerTrace ++ allocationTrace ++ frameTrace ++ tail.attempts⟩ := by
  have hadjust := CallResults.adjusted_frame external ctx _ framed nonce time frameTrace hf
  have hspend := Spending.success_world external ctx amount routerWorld allocated framed a _ nonce
    allocationTrace frameTrace ha hamount hadjust
  have hparent := WithdrawalTail.after_spend external ctx router amount seeds w statusWorld routerWorld _
    statusTrace routerTrace (allocationTrace ++ frameTrace) hs hr hauth hn hspend
  simpa [adjustedNext, List.append_assoc] using hparent

theorem late_failure (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w statusWorld routerWorld allocated framed : World)
    (a : Live.Allocation) (nonce time : Nat) (fault : Fault)
    (statusTrace routerTrace allocationTrace frameTrace : List Attempt)
    (hs : canDeposit external ctx w = ⟨.ok true, statusWorld, statusTrace⟩)
    (hr : stakingRouter external ctx statusWorld = ⟨.ok router, routerWorld, routerTrace⟩)
    (hauth : ctx.sender = router) (hn : amount.val ≠ 0)
    (ha : getBufferedEtherAllocation external ctx routerWorld = ⟨.ok a, allocated, allocationTrace⟩)
    (hamount : amount.val ≤ a.deposits + a.unreserved)
    (hf : getCurrentFrame external ctx (Spending.beforeFrame ctx a amount allocated) =
      ⟨.ok (nonce, time), framed, frameTrace⟩)
    (ht : (WithdrawalTail.finish external ctx router amount seeds
      (Spending.afterFrame ctx amount
        (adjustedNext ctx (Spending.beforeFrame ctx a amount allocated) nonce) nonce framed)).outcome =
          .error fault) :
    run (withdrawDepositableEther external ctx amount seeds) w =
      ⟨.error fault, w, statusTrace ++ routerTrace ++ allocationTrace ++ frameTrace ++
        (WithdrawalTail.finish external ctx router amount seeds
          (Spending.afterFrame ctx amount
            (adjustedNext ctx (Spending.beforeFrame ctx a amount allocated) nonce) nonce framed)).attempts⟩ := by
  unfold run
  rw [after_frame external ctx router amount seeds w statusWorld routerWorld allocated framed
    a nonce time statusTrace routerTrace allocationTrace frameTrace hs hr hauth hn ha hamount hf]
  simp [ht]

end LidoSRv3.Audit.Source.TrioReserve1.WithdrawalComposition
