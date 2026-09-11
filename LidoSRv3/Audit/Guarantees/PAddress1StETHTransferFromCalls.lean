import LidoSRv3.Audit.Source.AddressStETHTransferFromCalls
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressPermitRequestCalls
open LidoSRv3.Audit.Source.AddressStETHTransferFromCalls
open LidoSRv3.Audit.Source.AddressStETHQuoteCalls (quote StItem transcript_map st_item)
open LidoSRv3.Audit.Source.AddressRequestCalls (resolvedOwner)

/-- Entire ee24 direct physical-quote permit conclusion, specialized only by
actual stETH transferFrom. Original general interpreter theorem is unchanged. -/
def DirectQuotePermitEffect (permit : External) (ctx : Context) (target owner : Address)
    (p : PermitInput) (amounts : List Word) (ids : List Nat) (before after : World) (attempts : List Attempt) : Prop :=
  JoinedEffect permit ctx target p (StETHEffect callee (quote target) ctx target owner amounts) ids before after attempts ∧
    ∃ permitted pa ba, PermitEffect permit ctx target p before permitted pa ∧ Resumed permitted ∧
      Transcript (StItem callee ctx target (resolvedOwner ctx owner)) amounts ids permitted after ba ∧ attempts = pa ++ ba

/-- Actual allowance-first transferFrom, consumed physical quote and full enqueue
on every same item World, with complete old permit/quote effects preserved. -/
theorem actual_steth_transfer_from_quote_permit_batch (permit : External) (ctx : Context)
    (target owner : Address) (p : PermitInput) (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).outcome = .ok ids) :
    DirectQuotePermitEffect permit ctx target owner p amounts ids before
      (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).world
      (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).attempts ∧
    ∃ permitted pa ba, PermitEffect permit ctx target p before permitted pa ∧ Resumed permitted ∧
      Transcript (Item ctx target (resolvedOwner ctx owner)) amounts ids permitted
        (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).world ba ∧
      (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).attempts = pa ++ ba := by
  have old := actual_steth_physical_quote_permit_batch permit callee ctx target owner p amounts ids before h
  refine ⟨old,?_⟩
  obtain ⟨permitted,pa,ba,hp,hr,ht,hj⟩ := old.2
  exact ⟨permitted,pa,ba,hp,hr,transcript_map (item_effect ctx target (resolvedOwner ctx owner)) ht,hj⟩

/-- Direct no-permit requestWithdrawals entry, retaining the old batch result. -/
theorem actual_steth_transfer_from_quote_batch (ctx : Context) (target owner : Address)
    (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts before).outcome = .ok ids) :
    StETHEffect callee (quote target) ctx target owner amounts ids before
      (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts before).world
      (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts before).attempts ∧
    Transcript (Item ctx target (resolvedOwner ctx owner)) amounts ids before
      (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts before).world
      (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts before).attempts := by
  have old := actual_steth_request_batch callee (quote target) ctx target owner amounts ids before h
  refine ⟨old,?_⟩
  exact transcript_map (fun amount id w after ats hi => item_effect ctx target (resolvedOwner ctx owner) amount id w after ats
    (st_item callee ctx target (resolvedOwner ctx owner) amount id w after ats hi)) old.2.1

theorem actual_steth_transfer_from_quote_permit_failure_restores (permit : External) (ctx : Context)
    (target owner : Address) (p : PermitInput) (amounts : List Word) (before : World) (fault : Fault)
    (h : (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).outcome = .error fault) :
    (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).world = before :=
  actual_steth_physical_quote_failure_restores permit callee ctx target owner p amounts before fault h

theorem actual_steth_transfer_from_quote_failure_restores (ctx : Context) (target owner : Address)
    (amounts : List Word) (before : World) (fault : Fault)
    (h : (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts before).outcome = .error fault) :
    (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts before).world = before :=
  actual_steth_batch_failure_restores callee (quote target) ctx target owner amounts before fault h

#print axioms actual_steth_transfer_from_quote_permit_batch
#print axioms actual_steth_transfer_from_quote_batch
#print axioms actual_steth_transfer_from_quote_permit_failure_restores
#print axioms actual_steth_transfer_from_quote_failure_restores
end LidoSRv3.Audit.Guarantees.PAddress1
