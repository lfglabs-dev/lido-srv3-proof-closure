import audit.trio.consolidation.Bus

namespace LidoSRv3.Tests.TrioConsolidation.Bus

open audit.trio.consolidation

private def key (id : Nat) : Pubkey := ⟨id, 48⟩

private def publisherBatch : List PublisherGroup :=
  [⟨[key 11, key 12], key 21⟩]

private def witnessBatch : List WitnessGroup :=
  [⟨[key 11, key 12], key 21⟩]

private def oracle : HashOracle := ⟨fun groups => groups.length + 40⟩

private def queued : BusState :=
  emptyBusState.writePending 41 ⟨7, 100⟩

example : addConsolidationRequests oracle true 7 100 4 2 publisherBatch
    emptyBusState = .committed queued ⟨7, publisherBatch, 41⟩ := by
  rfl

example : addConsolidationRequests oracle false 7 100 4 2 publisherBatch
    emptyBusState = .reverted .accessDenied emptyBusState := by
  rfl

example : executeConsolidation oracle true 9 109 10 (word 6) witnessBatch queued =
    .reverted (.executionDelayNotPassed 109 110) queued := by
  rfl

/-- The delete preceding the gateway call is rolled back if that call reverts. -/
example : executeConsolidation oracle false 9 110 10 (word 6) witnessBatch queued =
    .reverted .gatewayReverted queued := by
  rfl

example : ∃ after call event,
    executeConsolidation oracle true 9 110 10 (word 6) witnessBatch queued =
      .committed after call event ∧
    after.pending 41 = none ∧
    call = ⟨witnessBatch, 9, word 6⟩ ∧
    event = ⟨41, word 6⟩ := by
  refine ⟨queued.deletePending 41, ⟨witnessBatch, 9, word 6⟩,
    ⟨41, word 6⟩, rfl, ?_⟩
  simp [BusState.deletePending]

/-- Exercise the new source property for the caller-supplied `gatewayAccepts`
premise (replaced/anchored from pin 17005714). On the committed path the
forwarded GatewayCall value equals the supplied msgValue (full transfer). -/
example : executeConsolidation oracle true 9 110 10 (word 6) witnessBatch queued =
    .committed (queued.deletePending 41) ⟨witnessBatch, 9, word 6⟩ ⟨41, word 6⟩ := by
  rfl

example (h : executeConsolidation oracle true 9 110 10 (word 6) witnessBatch queued =
           .committed (queued.deletePending 41) ⟨witnessBatch, 9, word 6⟩ ⟨41, word 6⟩) :
    (executeConsolidation_committed_forwards_msgValue
      oracle true 9 110 10 (word 6) witnessBatch queued (queued.deletePending 41)
      ⟨witnessBatch, 9, word 6⟩ ⟨41, word 6⟩ h) = rfl := by
  rfl

end LidoSRv3.Tests.TrioConsolidation.Bus
