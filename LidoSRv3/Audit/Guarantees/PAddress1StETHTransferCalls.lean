import LidoSRv3.Audit.Source.AddressStETHTransferCalls
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressPermitRequestCalls
open LidoSRv3.Audit.Source.AddressStETHTransferCalls
open LidoSRv3.Audit.Source.AddressStETHConversionCalls (conversion)
open LidoSRv3.Audit.Source.AddressStETHQuoteCalls (quote transcript_map)
open LidoSRv3.Audit.Source.AddressRequestCalls (resolvedOwner)

/-- Entire107e public conjunction on exactly the actual output World/journal,
only specializing its remaining tokenTransfer interpreter. -/
def PhysicalConversionPermitEffect (permit otherCalls : External) (ctx : Context)
    (wstETH target owner : Address) (p : PermitInput) (amounts : List Word) (ids : List Nat)
    (before after : World) (attempts : List Attempt) : Prop :=
  PhysicalQuotePermitEffect permit callee otherCalls ctx wstETH target owner p amounts ids before after attempts ∧
    ∃ permitted pa ba, PermitEffect permit ctx wstETH p before permitted pa ∧ Resumed permitted ∧
      Transcript (LidoSRv3.Audit.Source.AddressStETHConversionCalls.Item callee otherCalls ctx wstETH target (resolvedOwner ctx owner))
        amounts ids permitted after ba ∧ attempts = pa ++ ba

/-- The actual fresh postburn target receives a canonical transfer of the same
captured conversion amount and executes full-Lido physical shares movement.
The entire old permit/conversion/burn/quote/batch conclusion remains available. -/
theorem actual_wrapped_physical_steth_transfer_permit_batch (permit otherCalls : External)
    (ctx : Context) (wstETH target owner : Address) (p : PermitInput) (amounts : List Word)
    (ids : List Nat) (before : World)
    (h : (runPermit permit ctx wstETH p
      (runBatch (wrappedStep conversion callee otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).outcome = .ok ids) :
    PhysicalConversionPermitEffect permit otherCalls ctx wstETH target owner p amounts ids before
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion callee otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).world
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion callee otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).attempts ∧
    ∃ permitted pa ba, PermitEffect permit ctx wstETH p before permitted pa ∧ Resumed permitted ∧
      Transcript (Item otherCalls ctx wstETH target (resolvedOwner ctx owner)) amounts ids permitted
        (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion callee otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).world ba ∧
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion callee otherCalls (quote target) ctx wstETH target) ctx owner amounts) before).attempts = pa ++ ba := by
  have old := actual_wrapped_physical_conversion_permit_batch permit callee otherCalls ctx wstETH target owner p amounts ids before h
  refine ⟨old,?_⟩
  obtain ⟨permitted,pa,ba,hp,hr,ht,hj⟩ := old.2
  exact ⟨permitted,pa,ba,hp,hr,transcript_map (item_effect otherCalls ctx wstETH target (resolvedOwner ctx owner)) ht,hj⟩

theorem actual_wrapped_physical_steth_transfer_failure_restores (permit otherCalls : External)
    (ctx : Context) (wstETH target owner : Address) (p : PermitInput) (amounts : List Word)
    (before : World) (fault : Fault)
    (h : (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion callee otherCalls (quote target) ctx wstETH target)
      ctx owner amounts) before).outcome = .error fault) :
    (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion callee otherCalls (quote target) ctx wstETH target)
      ctx owner amounts) before).world = before :=
  actual_wrapped_physical_conversion_failure_restores permit callee otherCalls ctx wstETH target owner p amounts before fault h

#print axioms actual_wrapped_physical_steth_transfer_permit_batch
#print axioms actual_wrapped_physical_steth_transfer_failure_restores
end LidoSRv3.Audit.Guarantees.PAddress1
