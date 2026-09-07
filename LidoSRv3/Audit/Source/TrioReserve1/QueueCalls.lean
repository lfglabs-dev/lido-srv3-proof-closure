import LidoSRv3.Audit.Source.TrioReserve1.CallResults
import LidoSRv3.Audit.Source.TrioReserve1.Queue
import LidoSRv3.Audit.Source.TrioReserve1.Allocation

namespace LidoSRv3.Audit.Source.TrioReserve1.QueueCalls
open Live

/-- Exact locator and queue source getters; other selectors remain delegated. -/
def external (keccak : Queue.Keccak) (locator : Address) (c : Locator.Config)
    (other : External) : External :=
  Locator.dispatch locator c (Queue.dispatch keccak c.queue other)

def lookupAttempt (ctx : Context) (locator queue : Address) : Attempt :=
  ⟨⟨ctx.self, locator, word 0, encode 4 0x37d5fe99⟩, true, encode 32 queue.val, []⟩

def bunkerBytes (queue : Address) (w : World) : Bytes :=
  encode 32 (if Queue.isBunkerModeActive queue w then 1 else 0)

theorem bunker_call (keccak : Queue.Keccak) (locator : Address) (c : Locator.Config)
    (other : External) (ctx : Context) (w : World)
    (hd : c.queue ≠ locator) (hc : (w.core.codeSize c.queue.val).val ≠ 0) :
    call (external keccak locator c other) ctx c.queue 0x2b95b781 (word 0) w =
      ⟨.ok (bunkerBytes c.queue w), w,
        [⟨⟨ctx.self, c.queue, word 0, encode 4 0x2b95b781⟩, true, bunkerBytes c.queue w, []⟩]⟩ := by
  have hsel : encode 4 0x2b95b781 ≠ encode 4 0xd0fb84e8 := by decide
  simp [call, external, Locator.dispatch, Queue.dispatch, hd, hc, hsel,
    word, Verity.Core.Uint256.ofNat, CallResults.transfer_zero, bunkerBytes]

/-- Permission is computed from real queue storage and the physical pause
word. Neither getter can mutate the world or call an arbitrary callback. -/
theorem status (keccak : Queue.Keccak) (c : Locator.Config) (other : External)
    (ctx : Context) (w : World)
    (hd : c.queue ≠ Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val)
    (hl : (w.core.codeSize
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val).val).val ≠ 0)
    (hq : (w.core.codeSize c.queue.val).val ≠ 0) :
    let locator := Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val
    canDeposit (external keccak locator c other) ctx w =
      ⟨.ok (if Queue.isBunkerModeActive c.queue w then false
        else decide ((w.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)), w,
        [lookupAttempt ctx locator c.queue,
          ⟨⟨ctx.self, c.queue, word 0, encode 4 0x2b95b781⟩, true, bunkerBytes c.queue w, []⟩]⟩ := by
  dsimp only
  have hlookup := CallResults.queue_lookup ctx w c (Queue.dispatch keccak c.queue other) hl
  have hb := bunker_call keccak _ c other ctx w hd hq
  have hdecode : decodeWord (bunkerBytes c.queue w) 0 w =
      ⟨.ok (word (if Queue.isBunkerModeActive c.queue w then 1 else 0)), w, []⟩ := by
    simpa [bunkerBytes] using ABI.decode_word (if Queue.isBunkerModeActive c.queue w then 1 else 0) [] w
  change withdrawalQueue (external keccak _ c other) ctx w = _ at hlookup
  simp only [canDeposit, bind, bindExec, hlookup, hb, hdecode]
  cases Queue.isBunkerModeActive c.queue w <;>
    simp [pure, pureExec, bindExec, Live.read, word, Verity.Core.Uint256.ofNat,
      Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS, lookupAttempt]

theorem demand_call (keccak : Queue.Keccak) (locator : Address) (c : Locator.Config)
    (other : External) (ctx : Context) (w : World) (amount : Nat)
    (hd : c.queue ≠ locator) (hc : (w.core.codeSize c.queue.val).val ≠ 0)
    (hq : Queue.unfinalizedStETH keccak c.queue w = .ok amount) :
    call (external keccak locator c other) ctx c.queue 0xd0fb84e8 (word 0) w =
      ⟨.ok (encode 32 amount), w,
        [⟨⟨ctx.self, c.queue, word 0, encode 4 0xd0fb84e8⟩, true, encode 32 amount, []⟩]⟩ := by
  simp [call, external, Locator.dispatch, Queue.dispatch, hd, hc, hq,
    word, Verity.Core.Uint256.ofNat, CallResults.transfer_zero]

theorem demand_panic (keccak : Queue.Keccak) (locator : Address) (c : Locator.Config)
    (other : External) (ctx : Context) (w : World) (code : Nat)
    (hd : c.queue ≠ locator) (hc : (w.core.codeSize c.queue.val).val ≠ 0)
    (hq : Queue.unfinalizedStETH keccak c.queue w = .error code) :
    call (external keccak locator c other) ctx c.queue 0xd0fb84e8 (word 0) w =
      ⟨.error (.bubbled (Queue.panicBytes code)), w,
        [⟨⟨ctx.self, c.queue, word 0, encode 4 0xd0fb84e8⟩, false, Queue.panicBytes code, []⟩]⟩ := by
  simp [call, external, Locator.dispatch, Queue.dispatch, hd, hc, hq,
    word, Verity.Core.Uint256.ofNat, CallResults.transfer_zero]

theorem demand_bound (keccak : Queue.Keccak) (queue : Address) (w : World) (amount : Nat)
    (h : Queue.unfinalizedStETH keccak queue w = .ok amount) : amount < width := by
  unfold Queue.unfinalizedStETH at h
  dsimp only at h
  split at h
  · simp only [Except.ok.injEq] at h
    rw [← h]
    exact Nat.lt_of_le_of_lt (Nat.sub_le _ _) (Queue.cumulative_bound keccak queue w _)
  · contradiction

def allocationValues (ctx : Context) (w : World) (demand : Nat) : Live.Allocation :=
  let total := (w.core.readContractSlot ctx.self.val bufferSlot).val % width
  let deposits := min total (w.core.readContractSlot ctx.self.val reserveSlot).val
  let withdrawals := min (total - deposits) demand
  ⟨total, deposits, withdrawals, total - deposits - withdrawals⟩

/-- Actual queue storage flows through the dispatcher, CALL and byte decoder
into the allocation. Both source getters preserve the entire incoming world. -/
theorem allocation_success (keccak : Queue.Keccak) (c : Locator.Config) (other : External)
    (ctx : Context) (w : World) (amount : Nat)
    (hd : c.queue ≠ Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val)
    (hl : (w.core.codeSize
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val).val).val ≠ 0)
    (hc : (w.core.codeSize c.queue.val).val ≠ 0)
    (hq : Queue.unfinalizedStETH keccak c.queue w = .ok amount) :
    let locator := Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val
    getBufferedEtherAllocation (external keccak locator c other) ctx w =
      ⟨.ok (allocationValues ctx w amount), w,
        [lookupAttempt ctx locator c.queue,
          ⟨⟨ctx.self, c.queue, word 0, encode 4 0xd0fb84e8⟩, true, encode 32 amount, []⟩]⟩ := by
  dsimp only
  have hlookup := CallResults.queue_lookup ctx w c (Queue.dispatch keccak c.queue other) hl
  change withdrawalQueue (external keccak _ c other) ctx w = _ at hlookup
  have hcall := demand_call keccak _ c other ctx w amount hd hc hq
  have hdecode : decodeWord (encode 32 amount) 0 w = ⟨.ok (word amount), w, []⟩ := by
    simpa using ABI.decode_word amount [] w
  have hb := demand_bound keccak c.queue w amount hq
  have hw : amount < Verity.Core.UINT256_MODULUS := by
    unfold width at hb
    unfold Verity.Core.UINT256_MODULUS
    omega
  simp only [getBufferedEtherAllocation, Live.read, bind, bindExec, hlookup, hcall, hdecode]
  simp [pure, pureExec, word, Verity.Core.Uint256.ofNat, Verity.Core.Uint256.modulus,
    Nat.mod_eq_of_lt hw, allocationValues, lookupAttempt]

theorem allocation_panic (keccak : Queue.Keccak) (c : Locator.Config) (other : External)
    (ctx : Context) (w : World) (code : Nat)
    (hd : c.queue ≠ Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val)
    (hl : (w.core.codeSize
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val).val).val ≠ 0)
    (hc : (w.core.codeSize c.queue.val).val ≠ 0)
    (hq : Queue.unfinalizedStETH keccak c.queue w = .error code) :
    let locator := Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val
    getBufferedEtherAllocation (external keccak locator c other) ctx w =
      ⟨.error (.bubbled (Queue.panicBytes code)), w,
        [lookupAttempt ctx locator c.queue,
          ⟨⟨ctx.self, c.queue, word 0, encode 4 0xd0fb84e8⟩, false, Queue.panicBytes code, []⟩]⟩ := by
  dsimp only
  have hlookup := CallResults.queue_lookup ctx w c (Queue.dispatch keccak c.queue other) hl
  change withdrawalQueue (external keccak _ c other) ctx w = _ at hlookup
  have hcall := demand_panic keccak _ c other ctx w code hd hc hq
  simp [getBufferedEtherAllocation, Live.read, bind, bindExec, hlookup, hcall, lookupAttempt]

/-- The demand and allocation share the same related physical queue state.
No cached-demand equality or monotone-row assumption is supplied. -/
theorem live_allocation_spec (keccak : Queue.Keccak) (queue : Address)
    (ctx : Context) (w : World) (amount : Nat) (s : QueueSpec.State)
    (hrel : Queue.StateRel keccak queue w s)
    (hq : Queue.unfinalizedStETH keccak queue w = .ok amount) :
    AllocationSpec.LiveDescribes s (allocationValues ctx w amount).total
      (w.core.readContractSlot ctx.self.val reserveSlot).val amount
      (Allocation.observe (allocationValues ctx w amount)) := by
  have hqueue := Queue.unfinalized_corresponds keccak queue w s hrel
  simp only [hq, Queue.observe] at hqueue
  exact ⟨hqueue, AllocationSpec.exists_allocation _ _ _⟩

end LidoSRv3.Audit.Source.TrioReserve1.QueueCalls
