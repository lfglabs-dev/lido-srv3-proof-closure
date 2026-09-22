import LidoSRv3.Audit.Source.AddressStETHQuoteCalls
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressPermitRequestCalls
open LidoSRv3.Audit.Source.AddressStETHQuoteCalls
open LidoSRv3.Audit.Source.AddressRequestCalls (resolvedOwner)
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)

/-- Complete old permit/batch effect plus a physical quote at every same item
world. The supplied queueQuote interpreter has been replaced in the runner. -/
theorem actual_steth_physical_quote_permit_batch (permit callee : External) (ctx : Context)
    (target owner : Address) (p : PermitInput) (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).outcome = .ok ids) :
    JoinedEffect permit ctx target p (StETHEffect callee (quote target) ctx target owner amounts) ids before
      (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).world
      (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).attempts ∧
    ∃ permitted pa ba,
      PermitEffect permit ctx target p before permitted pa ∧ Resumed permitted ∧
      Transcript (StItem callee ctx target (resolvedOwner ctx owner)) amounts ids permitted
        (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).world ba ∧
      (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).attempts = pa ++ ba := by
  have old := actual_steth_permit_batch permit callee (quote target) ctx target owner p amounts ids before h
  refine ⟨old,?_⟩
  obtain ⟨permitted,pa,ba,hp,⟨hr,ht,hlen⟩,hj⟩ := old
  exact ⟨permitted,pa,ba,hp,hr,transcript_map (st_item callee ctx target (resolvedOwner ctx owner)) ht,hj⟩

/-- Keeps actual wrapped transferFrom/unwrap, permit and every old batch effect;
quote words are read after that item's arbitrary mutable callbacks. -/
theorem actual_wrapped_physical_quote_permit_batch (permit : External) (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (ctx : Context) (wstETH target owner : Address)
    (p : PermitInput) (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target)
      ctx owner amounts) before).outcome = .ok ids) :
    JoinedEffect permit ctx wstETH p (WrappedEffect conversion tokenTransfer otherCalls (quote target) ctx wstETH target owner amounts) ids before
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).world
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).attempts ∧
    ∃ permitted pa ba,
      PermitEffect permit ctx wstETH p before permitted pa ∧ Resumed permitted ∧
      Transcript (WrappedItem conversion tokenTransfer otherCalls ctx wstETH target (resolvedOwner ctx owner)) amounts ids permitted
        (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).world ba ∧
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).attempts = pa ++ ba := by
  have old := actual_wrapped_permit_batch permit conversion tokenTransfer otherCalls (quote target) ctx wstETH target owner p amounts ids before h
  refine ⟨old,?_⟩
  obtain ⟨permitted,pa,ba,hp,⟨hr,ht,hlen⟩,hj⟩ := old
  exact ⟨permitted,pa,ba,hp,hr,transcript_map (wrapped_item conversion tokenTransfer otherCalls ctx wstETH target (resolvedOwner ctx owner)) ht,hj⟩

/-- Root rollback includes permit and every earlier successful item. -/
theorem actual_steth_physical_quote_failure_restores (permit callee : External) (ctx : Context)
    (target owner : Address) (p : PermitInput) (amounts : List Word) (before : World) (fault : Fault)
    (h : (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).outcome = .error fault) :
    (runPermit permit ctx target p (runBatch (stETHStep callee (quote target) ctx target) ctx owner amounts) before).world = before :=
  actual_steth_permit_failure_restores _ _ _ _ _ _ _ _ _ _ h

theorem actual_wrapped_physical_quote_failure_restores (permit : External) (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (ctx : Context) (wstETH target owner : Address)
    (p : PermitInput) (amounts : List Word) (before : World) (fault : Fault)
    (h : (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target)
      ctx owner amounts) before).outcome = .error fault) :
    (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).world = before :=
  actual_wrapped_permit_failure_restores _ _ _ _ _ _ _ _ _ _ _ _ _ h
end LidoSRv3.Audit.Guarantees.PAddress1
