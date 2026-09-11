import LidoSRv3.Audit.Source.AddressStETHConversionCalls
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressPermitRequestCalls
open LidoSRv3.Audit.Source.AddressStETHConversionCalls
open LidoSRv3.Audit.Source.AddressStETHQuoteCalls (quote WrappedItem transcript_map)
open LidoSRv3.Audit.Source.AddressRequestCalls (resolvedOwner)

/-- Verbatim shape of the complete accepted physical-forward-quote public effect,
specialized only by the newly executed conversion implementation. -/
def PhysicalQuotePermitEffect (permit tokenTransfer otherCalls : External) (ctx : Context)
    (wstETH target owner : Address) (p : PermitInput) (amounts : List Word) (ids : List Nat)
    (before after : World) (attempts : List Attempt) : Prop :=
  JoinedEffect permit ctx wstETH p (WrappedEffect conversion tokenTransfer otherCalls (quote target) ctx wstETH target owner amounts)
    ids before after attempts ∧
  ∃ permitted pa ba, PermitEffect permit ctx wstETH p before permitted pa ∧ Resumed permitted ∧
    Transcript (WrappedItem conversion tokenTransfer otherCalls ctx wstETH target (resolvedOwner ctx owner)) amounts ids permitted after ba ∧
    attempts = pa ++ ba

/-- Actual slot7-selected reverse output is consumed by the old complete permit,
burn/transfer, forward physical quote and enqueue chain, on each actual world.
No nonzero divisor, rate equality, target equality or callback frame premise. -/
theorem actual_wrapped_physical_conversion_permit_batch (permit tokenTransfer otherCalls : External)
    (ctx : Context) (wstETH target owner : Address) (p : PermitInput) (amounts : List Word)
    (ids : List Nat) (before : World)
    (h : (runPermit permit ctx wstETH p
      (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).outcome = .ok ids) :
    PhysicalQuotePermitEffect permit tokenTransfer otherCalls ctx wstETH target owner p amounts ids before
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).world
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).attempts ∧
    ∃ permitted pa ba, PermitEffect permit ctx wstETH p before permitted pa ∧ Resumed permitted ∧
      Transcript (Item tokenTransfer otherCalls ctx wstETH target (resolvedOwner ctx owner)) amounts ids permitted
        (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).world ba ∧
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).attempts = pa ++ ba := by
  have old := actual_wrapped_physical_quote_permit_batch permit conversion tokenTransfer otherCalls ctx wstETH target owner p amounts ids before h
  refine ⟨old,?_⟩
  obtain ⟨permitted,pa,ba,hp,hr,ht,hj⟩ := old.2
  exact ⟨permitted,pa,ba,hp,hr,transcript_map (item_effect tokenTransfer otherCalls ctx wstETH target (resolvedOwner ctx owner)) ht,hj⟩

theorem actual_wrapped_physical_conversion_failure_restores (permit tokenTransfer otherCalls : External)
    (ctx : Context) (wstETH target owner : Address) (p : PermitInput) (amounts : List Word)
    (before : World) (fault : Fault)
    (h : (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target)
      ctx owner amounts) before).outcome = .error fault) :
    (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls (quote target) ctx wstETH target)
      ctx owner amounts) before).world = before :=
  actual_wrapped_physical_quote_failure_restores permit conversion tokenTransfer otherCalls ctx wstETH target owner p amounts before fault h
end LidoSRv3.Audit.Guarantees.PAddress1
