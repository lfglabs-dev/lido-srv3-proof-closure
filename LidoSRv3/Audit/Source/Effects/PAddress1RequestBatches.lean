import LidoSRv3.Audit.Source.AddressRequestBatches
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressRequestCalls (resolvedOwner)
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)

/-- Physical entry pause admission and the full existing per-item stETH effect
on each successive world. Typed-array iteration scope; no memory allocator/ABI
or gas equivalence claim. No per-item success or environment frame hypothesis. -/
theorem actual_steth_request_batch (callee : External) (quote : StaticExternal)
    (ctx : Context) (stETH owner : Address) (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts before).outcome = .ok ids) :
    Resumed before ∧ Transcript (stETHEffect callee quote ctx stETH (resolvedOwner ctx owner))
      amounts ids before (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts before).world
      (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts before).attempts ∧
      ids.length = amounts.length := by
  obtain ⟨hp, ht⟩ := stETH_batch_success callee quote ctx stETH owner amounts ids before h
  exact ⟨hp, ht, transcript_length ht⟩

/-- The entire actual transferFrom/unwrap/queue effect is preserved for every
ordered item, including its same returned amount, physical enqueue and journal. -/
theorem actual_wrapped_request_batch (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (quote : StaticExternal) (ctx : Context) (wstETH stETH owner : Address)
    (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH)
      ctx owner amounts before).outcome = .ok ids) :
    Resumed before ∧ Transcript (wrappedEffect conversion tokenTransfer otherCalls quote ctx wstETH stETH
      (resolvedOwner ctx owner)) amounts ids before
      (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH) ctx owner amounts before).world
      (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH) ctx owner amounts before).attempts ∧
      ids.length = amounts.length := by
  obtain ⟨hp,ht⟩ := wrapped_batch_success conversion tokenTransfer otherCalls quote ctx wstETH stETH owner amounts ids before h
  exact ⟨hp,ht,transcript_length ht⟩

theorem actual_steth_batch_failure_restores (callee : External) (quote : StaticExternal)
    (ctx : Context) (stETH owner : Address) (amounts : List Word) (before : World) (fault : Fault)
    (h : (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts before).outcome = .error fault) :
    (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts before).world = before :=
  batch_failure_restores _ _ _ _ _ _ h

theorem actual_wrapped_batch_failure_restores (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (quote : StaticExternal) (ctx : Context) (wstETH stETH owner : Address)
    (amounts : List Word) (before : World) (fault : Fault)
    (h : (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH)
      ctx owner amounts before).outcome = .error fault) :
    (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH)
      ctx owner amounts before).world = before := batch_failure_restores _ _ _ _ _ _ h
end LidoSRv3.Audit.Guarantees.PAddress1
