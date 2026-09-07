import LidoSRv3.Audit.Source.TrioReserve1.SpendingSpec
import LidoSRv3.Audit.Source.TrioReserve1.Allocation
import LidoSRv3.Audit.Source.TrioReserve1.CallResults

namespace LidoSRv3.Audit.Source.TrioReserve1.Spending
open Live

theorem allocation_bounds (external : External) (ctx : Context) (w : World)
    (a : Live.Allocation)
    (h : (getBufferedEtherAllocation external ctx w).outcome = .ok a) :
    a.total < width ∧ a.deposits + a.unreserved ≤ a.total ∧
      (getDepositableEther a).val = a.deposits + a.unreserved := by
  obtain ⟨queue, data, demand, hq, hd, hw, ht, hs⟩ := Allocation.success_corresponds external ctx w a h
  have htotal : a.total < width := by
    rw [ht]
    exact Nat.mod_lt _ (by decide)
  have hsum := hs.2.2.2.2.2.2
  simp only [Allocation.observe] at hsum
  have hb : a.deposits + a.unreserved ≤ a.total := by omega
  refine ⟨htotal, hb, ?_⟩
  have hword : a.deposits + a.unreserved < Verity.Core.UINT256_MODULUS := by
    unfold width at htotal
    unfold Verity.Core.UINT256_MODULUS
    omega
  exact Nat.mod_eq_of_lt hword

/-- Values read from either half of physical accounting words are bounded,
even when the preceding callee modified them. Their sum with an admitted
amount fits uint256; it need not fit uint128. -/
theorem accounting_add_bound (packed : Word) (amount : Nat) (ha : amount < width) :
    packed.val / width + amount < Verity.Core.UINT256_MODULUS ∧
    packed.val % width + amount < Verity.Core.UINT256_MODULUS := by
  have hp := packed.isLt
  have hm : packed.val % width < width := Nat.mod_lt _ (by decide)
  unfold width at ha hm ⊢
  change packed.val < 2^256 at hp
  unfold Verity.Core.UINT256_MODULUS
  omega

theorem adjusted_next_bound (external : External) (ctx : Context) (w : World)
    (next nonce : Nat)
    (h : (getDepositedNextReportAdjusted external ctx w).outcome = .ok (next, nonce)) :
    next < width := by
  simp only [getDepositedNextReportAdjusted, Live.read, bind, bindExec] at h
  split at h
  · contradiction
  · simp only [pure, pureExec, Except.ok.injEq, Prod.mk.injEq] at h
    obtain ⟨hnext, _⟩ := h
    rw [← hnext]
    split
    · decide
    · exact Nat.mod_lt _ (by decide)

def beforeFrame (ctx : Context) (a : Live.Allocation) (amount : Word) (w : World) : World :=
  let post := (w.core.readContractSlot ctx.self.val bufferSlot).val / width + amount.val
  { w with
    core := w.core.writeContractSlot ctx.self.val bufferSlot (pack (a.total - amount.val) post)
    logs := w.logs ++ [⟨ctx.self, "DepositedPostReportUpdated", [word post]⟩,
      ⟨ctx.self, "Unbuffered", [amount]⟩] }

def afterFrame (ctx : Context) (amount : Word) (next nonce : Nat) (w : World) : World :=
  let written := {w with core := w.core.writeContractSlot ctx.self.val nextSlot (pack (next + amount.val) nonce)}
  let reserve := (written.core.readContractSlot ctx.self.val reserveSlot).val
  if reserve > 0 then
    { written with
      core := written.core.writeContractSlot ctx.self.val reserveSlot (word (reserve - amount.val))
      logs := written.logs ++ [⟨ctx.self, "DepositsReserveSet", [word (reserve - amount.val)]⟩]}
  else written

theorem success_world (external : External) (ctx : Context) (amount : Word)
    (w allocated framed : World) (a : Live.Allocation) (next nonce : Nat)
    (allocationTrace frameTrace : List Attempt)
    (ha : getBufferedEtherAllocation external ctx w = ⟨.ok a, allocated, allocationTrace⟩)
    (hamount : amount.val ≤ a.deposits + a.unreserved)
    (hf : getDepositedNextReportAdjusted external ctx (beforeFrame ctx a amount allocated) =
      ⟨.ok (next, nonce), framed, frameTrace⟩) :
    spendDepositableEther external ctx amount w =
      ⟨.ok (), afterFrame ctx amount next nonce framed, allocationTrace ++ frameTrace⟩ := by
  have hao : (getBufferedEtherAllocation external ctx w).outcome = .ok a := by rw [ha]
  obtain ⟨htotal, hsum, hword⟩ := allocation_bounds external ctx w a hao
  have hsmall : amount.val < width := by omega
  have hsub : amount.val ≤ a.total := by omega
  have hpost := (accounting_add_bound (allocated.core.readContractSlot ctx.self.val bufferSlot)
    amount.val hsmall).1
  have hnext : next < width := adjusted_next_bound external ctx _ next nonce (by rw [hf])
  have haddnext : next + amount.val < Verity.Core.UINT256_MODULUS := by
    unfold width at hnext hsmall
    unfold Verity.Core.UINT256_MODULUS
    omega
  have hreserve : ∀ reserve : Nat,
      (if reserve > amount.val then reserve - amount.val else 0) = reserve - amount.val := by
    intro reserve
    split
    · rfl
    · omega
  simp only [beforeFrame] at hf
  simp [spendDepositableEther, bind, bindExec, ha, hword, hamount, Live.read,
    checkedAdd, checkedSub, require, hpost, hsub, pure, pureExec, write, emit,
    hf, haddnext, setDepositsReserve, hreserve, afterFrame, List.append_assoc]
  by_cases hpos : 0 < ((framed.core.writeContractSlot ctx.self.val nextSlot
    (pack (next + amount.val) nonce)).readContractSlot ctx.self.val reserveSlot).val <;>
    simp [hpos, bindExec, Live.write, Live.emit, pureExec]

def observations (ctx : Context) (amount : Word) (a : Live.Allocation) (demand nonce : Nat)
    (w allocated framed : World) : SpendingSpec.Observations :=
  let saved := ((beforeFrame ctx a amount allocated).core.readContractSlot ctx.self.val nextSlot).val
  let next := if nonce = saved / width then saved % width else 0
  let written := framed.core.writeContractSlot ctx.self.val nextSlot (pack (next + amount.val) nonce)
  ⟨a.total, (w.core.readContractSlot ctx.self.val reserveSlot).val, demand, Allocation.observe a,
    amount.val, (allocated.core.readContractSlot ctx.self.val bufferSlot).val / width,
    saved % width, saved / width, nonce, (written.readContractSlot ctx.self.val reserveSlot).val⟩

/-- Source success with independent arithmetic, actual queue-byte witnesses,
and the actual current-frame execution. All callee world effects are retained.
The beforeFrame/afterFrame worlds specify the physical projections and events. -/
theorem success_corresponds (external : External) (ctx : Context) (amount : Word)
    (w allocated framed : World) (a : Live.Allocation) (nonce time : Nat)
    (allocationTrace frameTrace : List Attempt)
    (ha : getBufferedEtherAllocation external ctx w = ⟨.ok a, allocated, allocationTrace⟩)
    (hamount : amount.val ≤ a.deposits + a.unreserved)
    (hf : getCurrentFrame external ctx (beforeFrame ctx a amount allocated) =
      ⟨.ok (nonce, time), framed, frameTrace⟩) :
    ∃ queue data,
      (withdrawalQueue external ctx w).outcome = .ok queue ∧
      (call external ctx queue 0xd0fb84e8 (word 0)
        (withdrawalQueue external ctx w).world).outcome = .ok data ∧
      32 ≤ data.length ∧
      let o := observations ctx amount a (word (decode (data.take 32))).val nonce w allocated framed
      SpendingSpec.Describes o (SpendingSpec.accounting o) ∧
      spendDepositableEther external ctx amount w =
        ⟨.ok (), afterFrame ctx amount (if o.frameNonce = o.savedNonce then o.next else 0)
          nonce framed, allocationTrace ++ frameTrace⟩ := by
  obtain ⟨queue, data, hq, hd, hlen, ht, hspec⟩ :=
    Allocation.successful_queue_observation external ctx w a (by rw [ha])
  refine ⟨queue, data, hq, hd, hlen, ?_⟩
  dsimp only
  constructor
  · apply SpendingSpec.accounting_corresponds
    exact ⟨hspec, hamount⟩
  · have hadjust := CallResults.adjusted_frame external ctx _ framed nonce time frameTrace hf
    have hresult := success_world external ctx amount w allocated framed a _ nonce
      allocationTrace frameTrace ha hamount hadjust
    simpa [observations] using hresult

theorem allocation_failure (external : External) (ctx : Context) (amount : Word)
    (w : World) (fault : Fault)
    (ha : (getBufferedEtherAllocation external ctx w).outcome = .error fault) :
    run (spendDepositableEther external ctx amount) w =
      ⟨.error fault, w, (getBufferedEtherAllocation external ctx w).attempts⟩ := by
  simp [run, spendDepositableEther, bind, bindExec, ha]

theorem insufficient (external : External) (ctx : Context) (amount : Word)
    (w allocated : World) (a : Live.Allocation) (trace : List Attempt)
    (ha : getBufferedEtherAllocation external ctx w = ⟨.ok a, allocated, trace⟩)
    (hamount : a.deposits + a.unreserved < amount.val) :
    run (spendDepositableEther external ctx amount) w =
      ⟨.error (.reason "NOT_ENOUGH_ETHER"), w, trace⟩ := by
  have hw := (allocation_bounds external ctx w a (by rw [ha])).2.2
  simp [run, spendDepositableEther, bind, bindExec, ha, hw, require, Nat.not_le.mpr hamount, fail]

theorem frame_failure (external : External) (ctx : Context) (amount : Word)
    (w allocated failed : World) (a : Live.Allocation) (fault : Fault)
    (allocationTrace frameTrace : List Attempt)
    (ha : getBufferedEtherAllocation external ctx w = ⟨.ok a, allocated, allocationTrace⟩)
    (hamount : amount.val ≤ a.deposits + a.unreserved)
    (hf : getCurrentFrame external ctx (beforeFrame ctx a amount allocated) =
      ⟨.error fault, failed, frameTrace⟩) :
    run (spendDepositableEther external ctx amount) w =
      ⟨.error fault, w, allocationTrace ++ frameTrace⟩ := by
  obtain ⟨htotal, hsum, hword⟩ := allocation_bounds external ctx w a (by rw [ha])
  have hsmall : amount.val < width := by omega
  have hsub : amount.val ≤ a.total := by omega
  have hpost := (accounting_add_bound (allocated.core.readContractSlot ctx.self.val bufferSlot)
    amount.val hsmall).1
  have hadjust : getDepositedNextReportAdjusted external ctx (beforeFrame ctx a amount allocated) =
      ⟨.error fault, failed, frameTrace⟩ := by
    simp [getDepositedNextReportAdjusted, Live.read, bind, bindExec, hf]
  simp only [beforeFrame] at hadjust
  simp [run, spendDepositableEther, bind, bindExec, ha, hword, hamount, Live.read,
    checkedAdd, checkedSub, require, hpost, hsub, pure, pureExec, write, emit,
    hadjust, List.append_assoc]

end LidoSRv3.Audit.Source.TrioReserve1.Spending
