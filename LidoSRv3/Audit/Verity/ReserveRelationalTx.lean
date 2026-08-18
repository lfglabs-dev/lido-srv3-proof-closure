import LidoSRv3.Audit.Source.ReserveRelationalCorrespondence
import Verity.Core
import Verity.Core.Model.Denote
import Verity.Stdlib.Math

/-!
# P-RESERVE-RELATIONAL faithful finalization transaction

Executable Verity transaction for the guarantee-relevant slice of
`Accounting._calculateWithdrawals`, `WithdrawalQueue.prefinalize`, and
`WithdrawalQueue._finalize` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`
(`Accounting.sol:250-261`, `WithdrawalQueueBase.sol:288-328`, and
`WithdrawalQueueBase.sol:330-359`).

The requested batch ends arrive as a denoted `uint256[]` memory array, exactly
as `prefinalize(uint256[] _batches, uint256 _maxShareRate)` receives them.  The
queue's per-request economics live in `mapUint` storage channels and the
queue/buffer scalars live in word slots.  `depositsReserve` occupies its own
slot that the transaction never reads; `decode_writeSlot_reserve` and
`verity_reserve_slot_is_not_read` turn that into a checked frame property
rather than a code-reading claim.

Finalization persists the new `lockedEtherAmount` and the new last finalized
request id, and journals each prefinalized batch's upper endpoint.  Reverts roll
back to the pre-call snapshot through `Contract.run`, including reverts injected
after those writes.

The abstract plane is unbounded `Nat`, but `lockedEtherAmount += prefinalized`
is a Solidity 0.8 checked addition, so `finalize` reverts rather than storing a
wrapped word when the accumulator would exceed `MAX_UINT256`
(`verity_tx_reverts_on_locked_overflow`).  The correspondence to the unbounded
planes therefore carries an explicit no-overflow side condition; the relational
guarantee itself does not, because two worlds differing only in
`depositsReserve` decode to the same locked ETH and so overflow alike.
-/

namespace LidoSRv3.Audit.Verity.ReserveRelationalTx

open _root_.Verity
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open LidoSRv3.Audit.ReserveRelational

abbrev Word := Verity.Core.Uint256

def batchEndsBase : Nat := 0x1000
def lastFinalizedSlot : Nat := 60
def pausedSlot : Nat := 61
def bufferSlot : Nat := 62
def lockedEtherSlot : Nat := 63
def depositsReserveSlot : Nat := 64
def batchExistsSlot : Nat := 65
def batchNominalSlot : Nat := 66
def batchDiscountedSlot : Nat := 67
def batchSharesSlot : Nat := 68
def prefinalizedHiSlot : Nat := 69

private def oracle : DenoteOracle where
  mappingSlot := fun _ _ => 0
  keccakMemorySlice := fun _ _ _ => 0

def arrayState (state : ContractState) (length : Nat) : DenoteState :=
  { world := state
    bindings := [("batches_data_offset", batchEndsBase), ("batches_length", length)] }

def readBatchEnd (state : ContractState) (length index : Nat) : Option Nat :=
  evalExpr oracle [] (arrayState state length)
    (.memoryArrayElement "batches" (.literal index))

def readBatchEnds (state : ContractState) (length : Nat) : Option (List Nat) :=
  (List.range length).mapM (readBatchEnd state length)

/-- Queue economics for one request id.  A zero existence marker is the
storage encoding of "no such finalization batch". -/
def readBatch (state : ContractState) (id : Nat) : Option Batch :=
  if (state.readMapUint batchExistsSlot (Verity.Core.Uint256.ofNat id)).val = 0 then none
  else some
    { endRequestId := id
      nominalEth := (state.readMapUint batchNominalSlot (Verity.Core.Uint256.ofNat id)).val
      discountedEth := (state.readMapUint batchDiscountedSlot (Verity.Core.Uint256.ofNat id)).val
      shares := (state.readMapUint batchSharesSlot (Verity.Core.Uint256.ofNat id)).val }

def readSelection (state : ContractState) (ids : List Nat) : Option (List Batch) :=
  ids.mapM (readBatch state)

structure Decoded where
  ids : List Nat
  selected : List Batch
  lastFinalized : Nat
  paused : Bool
  buffer : Nat
  locked : Nat
  deriving DecidableEq, Repr

def decode (state : ContractState) (count : Nat) : Option Decoded := do
  let ids ← readBatchEnds state count
  let selected ← readSelection state ids
  pure
    { ids := ids
      selected := selected
      lastFinalized := (state.readSlot lastFinalizedSlot).val
      paused := (state.readSlot pausedSlot).val != 0
      buffer := (state.readSlot bufferSlot).val
      locked := (state.readSlot lockedEtherSlot).val }

/-- Calldata-shaped `uint256[] _batches` laid out in memory at `batchEndsBase`. -/
def memoryFor (ends : List Nat) : Nat → Word := fun offset =>
  if batchEndsBase ≤ offset ∧ offset < batchEndsBase + 32 * ends.length ∧
      (offset - batchEndsBase) % 32 = 0 then
    Verity.Core.Uint256.ofNat (ends.getD ((offset - batchEndsBase) / 32) 0)
  else 0

/-- Journal one finalization batch into its four `mapUint` channels.  The
existence marker is what makes an absent request id undecodable. -/
def writeBatches : List Batch → ContractState → ContractState
  | [], state => state
  | batch :: rest, state =>
      let key := Verity.Core.Uint256.ofNat batch.endRequestId
      writeBatches rest
        ((((state.writeMapUint batchExistsSlot key (Verity.Core.Uint256.ofNat 1)).writeMapUint
            batchNominalSlot key (Verity.Core.Uint256.ofNat batch.nominalEth)).writeMapUint
            batchDiscountedSlot key (Verity.Core.Uint256.ofNat batch.discountedEth)).writeMapUint
            batchSharesSlot key (Verity.Core.Uint256.ofNat batch.shares))

/-- Contract world encoding an abstract input/pre-state pair. -/
def stateFor (inputs : Inputs) (before : State) (base : ContractState) : ContractState :=
  let stored := writeBatches inputs.queue.batches base
  let stored := stored.writeSlot lastFinalizedSlot
    (Verity.Core.Uint256.ofNat inputs.queue.lastFinalizedRequestId)
  let stored := stored.writeSlot pausedSlot
    (Verity.Core.Uint256.ofNat (if inputs.queue.paused then 1 else 0))
  let stored := stored.writeSlot bufferSlot (Verity.Core.Uint256.ofNat inputs.buffer)
  let stored := stored.writeSlot lockedEtherSlot (Verity.Core.Uint256.ofNat before.lockedEth)
  let stored := stored.writeSlot depositsReserveSlot
    (Verity.Core.Uint256.ofNat before.depositsReserve)
  { stored with memory := memoryFor inputs.report.batchEnds }

/-- Transaction-side finalization.  Deliberately a second definition: the
correspondence theorem, not a shared name, ties it to `sourceRun`. -/
def txRun (decoded : Decoded) (discount : Bool) :
    Option (List (Nat × Nat) × Nat × Nat × (Nat × Nat) × Nat) :=
  if decoded.paused then none
  else match decoded.ids.getLast? with
    | none => none
    | some last =>
        let eth := sourceSum discount decoded.selected
        if eth ≤ decoded.buffer then
          some (sourceRanges decoded.lastFinalized decoded.selected, eth,
            sourceShareSum decoded.selected,
            (decoded.lastFinalized + 1, last), decoded.locked + eth)
        else none

def writeRanges : Nat → List (Nat × Nat) → ContractState → ContractState
  | _, [], state => state
  | index, range :: rest, state =>
      writeRanges (index + 1) rest
        (state.writeMapUint prefinalizedHiSlot (Verity.Core.Uint256.ofNat index)
          (Verity.Core.Uint256.ofNat range.2))

structure Result where
  prefinalizedRanges : List (Nat × Nat)
  prefinalizedEth : Nat
  sharesToBurn : Nat
  finalizedLo : Nat
  lockedEtherAfter : Nat
  deriving DecidableEq, Repr

/-- Executable transaction.  Empty batches, undecodable queue storage, an
oversubscribed buffer, and a locked-ETH accumulator that would exceed
`MAX_UINT256` all revert to the pre-call snapshot.  The last of those is the
Solidity 0.8 checked `lockedEtherAmount += prefinalized`: no wrapped word is
ever stored.  `failAfterWrites` is a test hook placed after the batch journal
and the two finalization writes; it proves rollback even after intermediate
effects. -/
def finalize (count : Nat) (discount : Bool) (failAfterWrites : Bool := false) :
    Contract Result := fun snapshot =>
  if count == 0 then .revert "EmptyBatches" snapshot else
  match decode snapshot count with
  | none => .revert "BATCH_DECODE" snapshot
  | some decoded =>
      match txRun decoded discount with
      | none => .revert "TOO_MUCH_ETH_TO_FINALIZE" snapshot
      | some (ranges, eth, shares, range, locked) =>
          if Verity.Core.MAX_UINT256 < locked then .revert "LOCKED_ETH_OVERFLOW" snapshot
          else
          let dirty := writeRanges 0 ranges snapshot
          let dirty :=
            (dirty.writeSlot lockedEtherSlot (Verity.Core.Uint256.ofNat locked)).writeSlot
              lastFinalizedSlot (Verity.Core.Uint256.ofNat range.2)
          if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
          else .success ⟨ranges, eth, shares, range.1, locked⟩ dirty

inductive Status where | committed | reverted deriving DecidableEq, Repr

structure View where
  status : Status
  prefinalizedRanges : List (Nat × Nat)
  prefinalizedEth : Nat
  sharesToBurn : Nat
  finalizedRange : Option (Nat × Word)
  lockedEtherAfter : Word
  deriving DecidableEq, Repr

/-- Outcome observables only.  The finalized upper endpoint and the locked ETH
are read back from storage; a revert exposes neither (PR #91). -/
def observe : ContractResult Result → View
  | .success result state =>
      ⟨.committed, result.prefinalizedRanges, result.prefinalizedEth, result.sharesToBurn,
        some (result.finalizedLo, state.readSlot lastFinalizedSlot),
        state.readSlot lockedEtherSlot⟩
  | .revert _ _ => ⟨.reverted, [], 0, 0, none, 0⟩

def sourceView (inputs : Inputs) (before : State) : View :=
  match sourceRun inputs before with
  | .reverted _ => ⟨.reverted, [], 0, 0, none, 0⟩
  | .committed _ observables =>
      ⟨.committed, observables.prefinalizedRanges, observables.prefinalizedEth,
        observables.sharesToBurn,
        observables.finalizedRange.map fun range =>
          (range.1, Verity.Core.Uint256.ofNat range.2),
        Verity.Core.Uint256.ofNat observables.lockedEtherAfter⟩

/-- The contract world encodes exactly these abstract inputs and pre-state, and
its queue storage is undecodable exactly when the pinned-source selection
fails. -/
def Decodes (state : ContractState) (inputs : Inputs) (before : State) : Prop :=
  decode state inputs.report.batchEnds.length =
    (sourceSelect inputs.report inputs.queue).map fun selected =>
      { ids := inputs.report.batchEnds
        selected := selected
        lastFinalized := inputs.queue.lastFinalizedRequestId
        paused := inputs.queue.paused
        buffer := inputs.buffer
        locked := before.lockedEth : Decoded }

theorem lockedEtherSlot_ne_lastFinalizedSlot : lockedEtherSlot ≠ lastFinalizedSlot := by decide

/-- The locked ETH accumulator stays inside one word.  This is exactly the
condition under which the Solidity 0.8 checked `lockedEtherAmount +=
prefinalized` does not revert, so it is the honest side condition for relating
the checked executable plane to the unbounded `Nat` planes. -/
def NoLockedOverflow (inputs : Inputs) (before : State) : Prop :=
  ∀ after observables, sourceRun inputs before = .committed after observables →
    observables.lockedEtherAfter ≤ Verity.Core.MAX_UINT256

/-- Composed faithful-plane theorem: the executable storage/memory transaction
has the same five finalization observables as the independently stated
pinned-source interpreter, which in turn agrees with the abstract model.  The
unbounded planes cannot express the checked accumulator, so the correspondence
holds exactly where that accumulator does not overflow; the overflow case is
`verity_tx_reverts_on_locked_overflow`. -/
theorem verity_tx_simulates_pinned_source
    (inputs : Inputs) (before : State) (state : ContractState)
    (h : Decodes state inputs before) (hNoWrap : NoLockedOverflow inputs before) :
    observe ((finalize inputs.report.batchEnds.length inputs.report.useDiscount).run state) =
      sourceView inputs before := by
  unfold Decodes at h
  unfold NoLockedOverflow at hNoWrap
  rcases hEnds : inputs.report.batchEnds with _ | ⟨first, rest⟩
  · unfold Contract.run finalize sourceView sourceRun sourcePrefinalize
    simp [hEnds, observe]
  · rw [hEnds] at h
    have hCount : ((first :: rest).length == 0) = false := by simp
    rw [hEnds] at hNoWrap
    unfold Contract.run finalize sourceView sourceRun sourcePrefinalize
    unfold sourceRun sourcePrefinalize at hNoWrap
    rw [h, hEnds]
    rw [hEnds] at hNoWrap
    cases hSel : sourceSelect inputs.report inputs.queue with
    | none => simp [observe]
    | some selected =>
        cases hPaused : inputs.queue.paused with
        | true => simp [observe, txRun]
        | false =>
            cases hGet : (first :: rest).getLast? with
            | none => simp at hGet
            | some last =>
                by_cases hFits : sourceSum inputs.report.useDiscount selected ≤ inputs.buffer
                · have hBound :
                      before.lockedEth + sourceSum inputs.report.useDiscount selected ≤
                        Verity.Core.MAX_UINT256 := by
                    refine hNoWrap _ _ ?_
                    simp [hSel, hPaused, hGet, hFits]
                  simp [observe, txRun, hGet, hFits, Nat.not_lt.mpr hBound, lastFinalizedSlot,
                    lockedEtherSlot, ContractState.readSlot_writeSlot_same,
                    ContractState.readSlot_writeSlot_other]
                · simp [observe, txRun, hGet, hFits]

private theorem memory_writeSlot (state : ContractState) (slot : Nat) (value : Word) :
    (state.writeSlot slot value).memory = state.memory := rfl

private theorem readBatchEnd_writeSlot (state : ContractState) (slot : Nat) (value : Word)
    (length index : Nat) :
    readBatchEnd (state.writeSlot slot value) length index = readBatchEnd state length index := by
  simp [readBatchEnd, arrayState, evalExpr, memory_writeSlot]

private theorem readBatchEnds_writeSlot (state : ContractState) (slot : Nat) (value : Word)
    (length : Nat) :
    readBatchEnds (state.writeSlot slot value) length = readBatchEnds state length := by
  have hFun : readBatchEnd (state.writeSlot slot value) length = readBatchEnd state length :=
    funext fun index => readBatchEnd_writeSlot state slot value length index
  simp [readBatchEnds, hFun]

private theorem readBatch_writeSlot (state : ContractState) (slot : Nat) (value : Word)
    (id : Nat) :
    readBatch (state.writeSlot slot value) id = readBatch state id := by
  simp [readBatch, ContractState.readMapUint]

private theorem readSelection_writeSlot (state : ContractState) (slot : Nat) (value : Word)
    (ids : List Nat) :
    readSelection (state.writeSlot slot value) ids = readSelection state ids := by
  have hFun : readBatch (state.writeSlot slot value) = readBatch state :=
    funext fun id => readBatch_writeSlot state slot value id
  simp [readSelection, hFun]

/-- The reserve slot is outside the transaction's read frame. -/
theorem decode_writeSlot_reserve (state : ContractState) (count : Nat) (value : Word) :
    decode (state.writeSlot depositsReserveSlot value) count = decode state count := by
  have hLast : lastFinalizedSlot ≠ depositsReserveSlot := by decide
  have hPaused : pausedSlot ≠ depositsReserveSlot := by decide
  have hBuffer : bufferSlot ≠ depositsReserveSlot := by decide
  have hLocked : lockedEtherSlot ≠ depositsReserveSlot := by decide
  simp [decode, readBatchEnds_writeSlot, readSelection_writeSlot,
    ContractState.readSlot_writeSlot_other, hLast, hPaused, hBuffer, hLocked]

/-- Writing the reserve slot leaves every finalization observable unchanged:
`depositsReserve` cannot reach the prefinalized or finalized ranges. -/
theorem verity_reserve_slot_is_not_read
    (count : Nat) (discount inject : Bool) (state : ContractState) (value : Word) :
    observe ((finalize count discount inject).run (state.writeSlot depositsReserveSlot value)) =
      observe ((finalize count discount inject).run state) := by
  unfold Contract.run finalize
  rw [decode_writeSlot_reserve]
  cases hCount : count == 0 with
  | true => simp [observe]
  | false =>
      cases hDecode : decode state count with
      | none => simp [observe]
      | some decoded =>
          cases hRun : txRun decoded discount with
          | none => simp [hRun, observe]
          | some quint =>
              obtain ⟨ranges, eth, shares, range, locked⟩ := quint
              by_cases hOv : Verity.Core.MAX_UINT256 < locked
              · simp [hRun, hOv, observe]
              · cases inject <;>
                  simp [hRun, hOv, observe, lastFinalizedSlot, lockedEtherSlot,
                    ContractState.readSlot_writeSlot_same,
                    ContractState.readSlot_writeSlot_other]

/-- Solidity 0.8 checked `lockedEtherAmount += prefinalized`.  Where the
unbounded planes would commit an accumulator wider than one word, the
transaction reverts on the exact pre-call snapshot: no wrapped word is ever
written, and the injected-failure hook cannot change that. -/
theorem verity_tx_reverts_on_locked_overflow
    (count : Nat) (discount inject : Bool) (state : ContractState) (decoded : Decoded)
    (ranges : List (Nat × Nat)) (eth shares : Nat) (range : Nat × Nat) (locked : Nat)
    (hCount : (count == 0) = false)
    (hDecode : decode state count = some decoded)
    (hRun : txRun decoded discount = some (ranges, eth, shares, range, locked))
    (hWrap : Verity.Core.MAX_UINT256 < locked) :
    (finalize count discount inject).run state = .revert "LOCKED_ETH_OVERFLOW" state := by
  unfold Contract.run finalize
  simp [hCount, hDecode, hRun, hWrap]

/-- Two contract worlds whose decodings differ only in `depositsReserve`
produce identical finalization observables.  Proved directly from the decoding:
`differOnlyInReserve` pins the locked ETH, so both worlds decode identically and
the checked accumulator overflows in both or neither.  The relational guarantee
therefore carries no no-overflow side condition. -/
theorem verity_reserve_does_not_change_finalization
    (inputs : Inputs) (left right : State) (stateLeft stateRight : ContractState)
    (hLeft : Decodes stateLeft inputs left) (hRight : Decodes stateRight inputs right)
    (h : differOnlyInReserve left right) :
    observe ((finalize inputs.report.batchEnds.length inputs.report.useDiscount).run
        stateLeft) =
      observe ((finalize inputs.report.batchEnds.length inputs.report.useDiscount).run
        stateRight) := by
  have hDecode : decode stateLeft inputs.report.batchEnds.length =
      decode stateRight inputs.report.batchEnds.length := by
    unfold Decodes at hLeft hRight
    unfold differOnlyInReserve at h
    rw [hLeft, hRight, h]
  unfold Contract.run finalize
  rw [hDecode]
  cases hCount : inputs.report.batchEnds.length == 0 with
  | true => simp [observe]
  | false =>
      cases hDec : decode stateRight inputs.report.batchEnds.length with
      | none => simp [observe]
      | some decoded =>
          cases hRun : txRun decoded inputs.report.useDiscount with
          | none => simp [observe]
          | some quint =>
              obtain ⟨ranges, eth, shares, range, locked⟩ := quint
              by_cases hOv : Verity.Core.MAX_UINT256 < locked
              · simp [hOv, observe]
              · simp [hOv, observe, lastFinalizedSlot, lockedEtherSlot,
                  ContractState.readSlot_writeSlot_same,
                  ContractState.readSlot_writeSlot_other]

/-- Any failure, including the failure injected after the batch journal and the
finalization writes, returns the exact pre-transaction snapshot. -/
theorem revert_restores_snapshot
    (count : Nat) (discount inject : Bool) (state rollback : ContractState) (reason : String)
    (h : (finalize count discount inject).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.ReserveRelationalTx
