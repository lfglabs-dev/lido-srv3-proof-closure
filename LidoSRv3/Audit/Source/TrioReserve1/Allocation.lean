import LidoSRv3.Audit.Source.TrioReserve1.Live
import LidoSRv3.Audit.Source.TrioReserve1.AllocationSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.Allocation
open Live

def observe (a : Live.Allocation) : AllocationSpec.Allocation :=
  ⟨a.deposits, a.withdrawals, a.unreserved⟩

/-- General sequencing inversion, with no assumption on callee behavior. -/
theorem bind_success (first : Exec α) (next : α → Exec β) (w : World) (b : β)
    (h : (bindExec first next w).outcome = .ok b) :
    ∃ a, (first w).outcome = .ok a ∧ (next a (first w).world).outcome = .ok b := by
  unfold bindExec at h
  cases he : (first w).outcome with
  | error e => simp [he] at h
  | ok a => exact ⟨a, rfl, by simpa [he] using h⟩

/-- Success is tied to the actual locator result, actual queue CALL, and its
decoded bytes. Buffer/reserve are the pre-call saved locals even if external
effects modify them. No preservation or unconditional-success premise. -/
theorem success_corresponds (external : External) (ctx : Context) (w : World)
    (a : Live.Allocation)
    (h : (getBufferedEtherAllocation external ctx w).outcome = .ok a) :
    ∃ queue data demand,
      (withdrawalQueue external ctx w).outcome = .ok queue ∧
      (call external ctx queue 0xd0fb84e8 (word 0)
        (withdrawalQueue external ctx w).world).outcome = .ok data ∧
      (decodeWord data 0
        (call external ctx queue 0xd0fb84e8 (word 0)
          (withdrawalQueue external ctx w).world).world).outcome = .ok demand ∧
      a.total = (w.core.readContractSlot ctx.self.val bufferSlot).val % width ∧
      AllocationSpec.Describes a.total
        (w.core.readContractSlot ctx.self.val reserveSlot).val demand.val (observe a) := by
  simp only [getBufferedEtherAllocation, Live.read, bind, bindExec] at h
  split at h
  · contradiction
  · rename_i queue hqueue
    split at h
    · contradiction
    · rename_i data hdata
      split at h
      · contradiction
      · rename_i demand hdemand
        simp only [pure, pureExec, Except.ok.injEq] at h
        subst a
        exact ⟨queue, data, demand, hqueue, hdata, hdemand, rfl,
          AllocationSpec.exists_allocation _ _ _⟩

/-- The word related by success_corresponds is exactly the first ABI word of
the successful queue reply. Short replies cannot provide a demand witness. -/
theorem decoded_demand (data : Bytes) (w : World) (demand : Word)
    (h : (decodeWord data 0 w).outcome = .ok demand) :
    32 ≤ data.length ∧ demand = word (decode (data.take 32)) := by
  by_cases hsize : 32 ≤ data.length
  · simp [decodeWord, require, hsize, bind, bindExec, pure, pureExec] at h
    exact ⟨hsize, h.symm⟩
  · simp [decodeWord, require, hsize, bind, bindExec, fail] at h

/-- Exact ABI-byte witness from the actual call, not a cached or existential
unrelated demand parameter. Callee-state preservation is deliberately absent. -/
theorem successful_queue_observation (external : External) (ctx : Context) (w : World)
    (a : Live.Allocation)
    (h : (getBufferedEtherAllocation external ctx w).outcome = .ok a) :
    ∃ queue data,
      (withdrawalQueue external ctx w).outcome = .ok queue ∧
      (call external ctx queue 0xd0fb84e8 (word 0)
        (withdrawalQueue external ctx w).world).outcome = .ok data ∧
      32 ≤ data.length ∧
      a.total = (w.core.readContractSlot ctx.self.val bufferSlot).val % width ∧
      AllocationSpec.Describes a.total
        (w.core.readContractSlot ctx.self.val reserveSlot).val
        (word (decode (data.take 32))).val (observe a) := by
  rcases success_corresponds external ctx w a h with
    ⟨queue, data, demand, hqueue, hdata, hdemand, htotal, hspec⟩
  obtain ⟨hsize, hword⟩ := decoded_demand data _ demand hdemand
  subst demand
  exact ⟨queue, data, hqueue, hdata, hsize, htotal, hspec⟩

end LidoSRv3.Audit.Source.TrioReserve1.Allocation
