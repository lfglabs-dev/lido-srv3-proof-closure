import LidoSRv3.Audit.Source.TrioReserve1.FinalizeSpec
import LidoSRv3.Audit.Source.TrioReserve1.QueueFinalize
import LidoSRv3.Audit.Source.TrioReserve1.VaultRules

namespace LidoSRv3.Audit.Source.TrioReserve1.FinalizeRules
open Live

def finalized (ctx : Context) (w : World) := (w.core.readContractSlot ctx.self.val Queue.finalizedSlot).val
def index (ctx : Context) (w : World) := (w.core.readContractSlot ctx.self.val QueueFinalize.checkpointIndexSlot).val

def checkpointed (keccak : Queue.Keccak) (ctx : Context) (rate : Word) (w : World) : World :=
  let next := index ctx w + 1
  let slot := QueueFinalize.checkpointSlot keccak next
  let core := w.core.writeContractSlot ctx.self.val slot (word (finalized ctx w + 1))
  let core := core.writeContractSlot ctx.self.val (word (slot + 1)).val rate
  {w with core := core.writeContractSlot ctx.self.val QueueFinalize.checkpointIndexSlot (word next)}

def observations (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word) (w : World) : FinalizeSpec.Observations :=
  let oldRow := w.core.readContractSlot ctx.self.val (Queue.requestSlot keccak (finalized ctx w))
  let newRow := w.core.readContractSlot ctx.self.val (Queue.requestSlot keccak last.val)
  {limit := Verity.Core.UINT256_MODULUS
   last := last.val
   tail := (w.core.readContractSlot ctx.self.val Queue.lastSlot).val
   finalized := finalized ctx w
   oldStETH := oldRow.val % width
   newStETH := newRow.val % width
   oldShares := oldRow.val / width
   newShares := newRow.val / width
   amount := amount.val
   checkpoint := index ctx w
   lockedAfterCheckpoint := ((checkpointed keccak ctx rate w).core.readContractSlot ctx.self.val QueueFinalize.lockedSlot).val}

def written (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word) (w : World) : World :=
  let checkpoint := checkpointed keccak ctx rate w
  let locked := (checkpoint.core.readContractSlot ctx.self.val QueueFinalize.lockedSlot).val
  let core := checkpoint.core.writeContractSlot ctx.self.val QueueFinalize.lockedSlot (word (locked + amount.val))
  {checkpoint with core := core.writeContractSlot ctx.self.val Queue.finalizedSlot last}

def committed (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word) (w : World) : World :=
  let o := observations keccak ctx last amount rate w
  let after := written keccak ctx last amount rate w
  {after with logs := after.logs ++ [⟨ctx.self, "WithdrawalsFinalized",
    [word (o.finalized + 1), last, amount, word (o.newShares - o.oldShares), after.core.blockTimestamp]⟩]}

def result (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word) (w : World) : Option FinalizeSpec.Failure → Result Unit
  | none => ⟨.ok (), committed keccak ctx last amount rate w, []⟩
  | some .upper_id | some .finalized_id => ⟨.error (.bubbled (encode 4 0xc969e0f2 ++ encode 32 last.val)), w, []⟩
  | some .amount =>
    let o := observations keccak ctx last amount rate w
    ⟨.error (.bubbled (encode 4 0x252dfe81 ++ encode 32 amount.val ++ encode 32 (o.newStETH - o.oldStETH))), w, []⟩
  | some .locked => ⟨.error (.bubbled (Queue.panicBytes 0x11)), checkpointed keccak ctx rate w, []⟩
  | some .shares => ⟨.error (.bubbled (Queue.panicBytes 0x11)), written keccak ctx last amount rate w, []⟩
  | some .steth | some .first_id | some .checkpoint => ⟨.error (.bubbled (Queue.panicBytes 0x11)), w, []⟩

def Describes (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word) (w : World) (observed : Result Unit) : Prop :=
  ∃ outcome, FinalizeSpec.Computes (observations keccak ctx last amount rate w) outcome ∧
    observed = result keccak ctx last amount rate w outcome

private theorem add_ok (a b : Nat) (h : a + b < Verity.Core.UINT256_MODULUS) :
    QueueFinalize.add a b = pureExec (a + b) := by
  funext w
  simp [QueueFinalize.add, require, h, bind, bindExec, pure, pureExec]
private theorem add_error (a b : Nat) (h : ¬ a + b < Verity.Core.UINT256_MODULUS) :
    QueueFinalize.add a b = fail (.bubbled (Queue.panicBytes 0x11)) := by
  funext w
  simp [QueueFinalize.add, require, h, bind, bindExec, fail]
private theorem sub_ok (a b : Nat) (h : b ≤ a) : QueueFinalize.sub a b = pureExec (a - b) := by
  funext w
  simp [QueueFinalize.sub, require, h, bind, bindExec, pure, pureExec]
private theorem sub_error (a b : Nat) (h : ¬ b ≤ a) :
    QueueFinalize.sub a b = fail (.bubbled (Queue.panicBytes 0x11)) := by
  funext w
  simp [QueueFinalize.sub, require, h, bind, bindExec, fail]

theorem of_spec (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before : World) (outcome : Option FinalizeSpec.Failure)
    (h : FinalizeSpec.Computes (observations keccak ctx last amount rate before) outcome) :
    QueueFinalize.finalize keccak ctx last amount rate before = result keccak ctx last amount rate before outcome := by
  let o := observations keccak ctx last amount rate before
  change FinalizeSpec.Computes o outcome at h
  by_cases h0 : o.last ≤ o.tail
  ·
    by_cases h1 : o.finalized < o.last
    ·
      by_cases h2 : o.oldStETH ≤ o.newStETH
      ·
        by_cases h3 : o.amount ≤ o.newStETH - o.oldStETH
        ·
          by_cases h4 : o.finalized + 1 < o.limit
          ·
            by_cases h5 : o.checkpoint + 1 < o.limit
            ·
              by_cases h6 : o.lockedAfterCheckpoint + o.amount < o.limit
              ·
                by_cases h7 : o.oldShares ≤ o.newShares
                ·
                  have ho : outcome = none := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0, h1, h2, h3, h4, h5, h6, h7] using h
                  subst outcome
                  simp only [o, observations, finalized, index, checkpointed] at h0 h1 h2 h3 h4 h5 h6 h7
                  simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, committed, written, observations, checkpointed, finalized, index, h0, h1, sub_ok _ _ h2, h3, add_ok _ _ h4, add_ok _ _ h5, add_ok _ _ h6, sub_ok _ _ h7]
                ·
                  have ho : outcome = some .shares := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0, h1, h2, h3, h4, h5, h6, h7] using h
                  subst outcome
                  simp only [o, observations, finalized, index, checkpointed] at h0 h1 h2 h3 h4 h5 h6 h7
                  simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, written, observations, checkpointed, finalized, index, h0, h1, sub_ok _ _ h2, h3, add_ok _ _ h4, add_ok _ _ h5, add_ok _ _ h6, sub_error _ _ h7]
              ·
                have ho : outcome = some .locked := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0, h1, h2, h3, h4, h5, h6] using h
                subst outcome
                simp only [o, observations, finalized, index, checkpointed] at h0 h1 h2 h3 h4 h5 h6
                simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, written, observations, checkpointed, finalized, index, h0, h1, sub_ok _ _ h2, h3, add_ok _ _ h4, add_ok _ _ h5, add_error _ _ h6]
            ·
              have ho : outcome = some .checkpoint := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0, h1, h2, h3, h4, h5] using h
              subst outcome
              simp only [o, observations, finalized, index, checkpointed] at h0 h1 h2 h3 h4 h5
              simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, written, observations, checkpointed, finalized, index, h0, h1, sub_ok _ _ h2, h3, add_ok _ _ h4, add_error _ _ h5]
          ·
            have ho : outcome = some .first_id := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0, h1, h2, h3, h4] using h
            subst outcome
            simp only [o, observations, finalized, index, checkpointed] at h0 h1 h2 h3 h4
            simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, written, observations, checkpointed, finalized, index, h0, h1, sub_ok _ _ h2, h3, add_error _ _ h4]
        ·
          have ho : outcome = some .amount := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0, h1, h2, h3] using h
          subst outcome
          simp only [o, observations, finalized, index, checkpointed] at h0 h1 h2 h3
          simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, written, observations, checkpointed, finalized, index, h0, h1, sub_ok _ _ h2, h3]
      ·
        have ho : outcome = some .steth := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0, h1, h2] using h
        subst outcome
        simp only [o, observations, finalized, index, checkpointed] at h0 h1 h2
        simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, written, observations, checkpointed, finalized, index, h0, h1, sub_error _ _ h2]
    ·
      have ho : outcome = some .finalized_id := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0, h1] using h
      subst outcome
      simp only [o, observations, finalized, index, checkpointed] at h0 h1
      simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, written, observations, checkpointed, finalized, index, h0, h1]
  ·
    have ho : outcome = some .upper_id := by simpa [FinalizeSpec.Computes, FinalizeSpec.Checks, h0] using h
    subst outcome
    simp only [o, observations, finalized, index, checkpointed] at h0
    simp [QueueFinalize.finalize, Live.read, bind, bindExec, require, pure, pureExec, fail, write, emit, result, written, observations, checkpointed, finalized, index, h0]

/-- Every source execution is described by the independent ordered guard relation. -/
theorem complete (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before : World) :
    Describes keccak ctx last amount rate before
      (QueueFinalize.finalize keccak ctx last amount rate before) := by
  obtain ⟨outcome, h⟩ := FinalizeSpec.total (observations keccak ctx last amount rate before)
  exact ⟨outcome, h, of_spec keccak ctx last amount rate before outcome h⟩

theorem corresponds (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before : World) (observed : Result Unit) :
    Describes keccak ctx last amount rate before observed ↔
      QueueFinalize.finalize keccak ctx last amount rate before = observed := by
  constructor
  · rintro ⟨outcome, h, rfl⟩
    exact of_spec keccak ctx last amount rate before outcome h
  · intro h
    rw [← h]
    exact complete keccak ctx last amount rate before

/-- Independent commit/revert rules restore the original world on late failure. -/
theorem root_corresponds (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    VaultSpec.Root (fun w o a t => Describes keccak ctx last amount rate w ⟨o, a, t⟩)
      before outcome after trace ↔
      run (QueueFinalize.finalize keccak ctx last amount rate) before = ⟨outcome, after, trace⟩ :=
  VaultRules.root_corresponds _ _
    (fun w a o t => corresponds keccak ctx last amount rate w ⟨o, a, t⟩)
    before after outcome trace

end LidoSRv3.Audit.Source.TrioReserve1.FinalizeRules
