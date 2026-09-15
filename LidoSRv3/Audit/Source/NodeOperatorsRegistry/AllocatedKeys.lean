import LidoSRv3.Audit.Source.NodeOperatorsRegistry.ExitedInvariant
import LidoSRv3.Audit.Source.SigningKeys

/-!
Arithmetic prefix and state continuations of
[`_loadAllocatedSigningKeys`](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/nos/NodeOperatorsRegistry.sol#L833-L849).
The active count is the element already read from the Solidity memory array.
Addition wraps, equality continues before the assertion, and assertion failure
is Solidity 0.4.24 INVALID, not an Error(string) or a Solidity 0.8 Panic.
The prefix stops before SigningKeys memory writes. Separate continuations model
the deposited setter, maximum update and final aggregate addition. The row composition threads the SigningKeys memory block between these slices.
Array access, buffer allocation, full loop and whole-call rollback remain
required.
-/
namespace LidoSRv3.Audit.Source.NodeOperatorsRegistry
open TrioAlloc1

inductive AllocationAssertionFailure where
  | invalid
  deriving DecidableEq

inductive AllocatedKeyAction where
  | unchanged
  | load (start count : Word)
  deriving DecidableEq

def allocatedDepositedAfter (signing active : Word) : Word :=
  word ((packedGet signing 1).val + active.val)

def allocatedKeyPrefix (signing active : Word) :
    Except AllocationAssertionFailure AllocatedKeyAction :=
  let before := packedGet signing 3
  let after := allocatedDepositedAfter signing active
  if after = before then .ok .unchanged
  else if after.val > before.val then
    .ok (.load before (word (after.val - before.val)))
  else .error .invalid

theorem allocatedKeyPrefix_nondecreasing (signing active : Word)
    (action : AllocatedKeyAction)
    (success : allocatedKeyPrefix signing active = .ok action) :
    (packedGet signing 3).val ≤ (allocatedDepositedAfter signing active).val := by
  dsimp only [allocatedKeyPrefix] at success
  split at success
  · rename_i equal
    rw [equal]
  · split at success
    · omega
    · cases success

/-- The source assertion detects wrapping only when the incoming local
accounting invariant holds. The equal-value branch needs that invariant too. -/
theorem allocatedKeyPrefix_no_overflow (signing active : Word)
    (action : AllocatedKeyAction)
    (consistent : (packedGet signing 1).val ≤ (packedGet signing 3).val)
    (success : allocatedKeyPrefix signing active = .ok action) :
    (packedGet signing 1).val + active.val < 2^256 := by
  have monotone := allocatedKeyPrefix_nondecreasing signing active action success
  have activeBound := active.isLt
  have exitedBound := (packedGet signing 1).isLt
  simp only [allocatedDepositedAfter, word] at monotone
  omega

/-- A loaded row's exact delta is derived from the actual wrapping prefix,
not from a checked-add replacement or an assumed post-allocation count. -/
theorem allocatedKeyPrefix_load_delta (signing active start count : Word)
    (consistent : (packedGet signing 1).val ≤ (packedGet signing 3).val)
    (success : allocatedKeyPrefix signing active = .ok (.load start count)) :
    start = packedGet signing 3 ∧ 0 < count.val ∧
      count.val + start.val = (packedGet signing 1).val + active.val := by
  have noOverflow := allocatedKeyPrefix_no_overflow signing active (.load start count)
    consistent success
  dsimp only [allocatedKeyPrefix] at success
  split at success
  · cases success
  · split at success
    · simp only [Except.ok.injEq, AllocatedKeyAction.load.injEq] at success
      rcases success with ⟨rfl, rfl⟩
      have afterBound := (allocatedDepositedAfter signing active).isLt
      simp only [allocatedDepositedAfter, word, Nat.mod_eq_of_lt noOverflow] at *
      exact ⟨True.intro, by omega, by omega⟩
    · cases success


/-- State continuation after SigningKeys returns, at
[NOR lines 853–858](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/nos/NodeOperatorsRegistry.sol#L853-L858).
The loaded-count addition wraps before the event and packed write. Events here
are committed observations: a later failure discards this row's event too.
The caller must connect `depositedAfter` and `keysCount` to the prefix and
thread the preceding memory execution; this helper does not assume that link. -/
def commitAllocatedRow (s : State) (id depositedAfter loaded keysCount : Word) :
    Except Bytes (State × Word × List (Word × Word)) := do
  let loaded := word (loaded.val + keysCount.val)
  let operator := s.operators id
  let signing ← Packed64x4.set operator.signingKeysStats 3 depositedAfter
  let s := saveOperator s id { operator with signingKeysStats := signing }
  let s ← updateSummaryMaxValidatorsCount s id
  pure (s, loaded, [(id, depositedAfter)])

/-- The committed deposited count is derived from the actual packed setter
and survives the maximum-update continuation. No desired post-state is supplied. -/
theorem commitAllocatedRow_deposited (s after : State)
    (id depositedAfter loaded keysCount next : Word) (events : List (Word × Word))
    (success : commitAllocatedRow s id depositedAfter loaded keysCount =
      .ok (after, next, events)) :
    (packedGet (after.operators id).signingKeysStats 3).val = depositedAfter.val := by
  cases written : Packed64x4.set (s.operators id).signingKeysStats 3 depositedAfter with
  | error reason =>
    simp [commitAllocatedRow, written, bind, Except.bind] at success
  | ok signing =>
    let middle := saveOperator s id { s.operators id with signingKeysStats := signing }
    cases updated : updateSummaryMaxValidatorsCount middle id with
    | error reason =>
      simp [commitAllocatedRow, written, middle, updated, bind, Except.bind] at success
    | ok finalState =>
      have frame := (updateMaximum_frame middle finalState id updated).1 id
      have counter := (Packed64x4.set_success _ _ _ _ written).1
      simp only [commitAllocatedRow, written, bind, Except.bind] at success
      change (do
        let final ← updateSummaryMaxValidatorsCount middle id
        pure (final, word (loaded.val + keysCount.val), [(id, depositedAfter)])) =
          .ok (after, next, events) at success
      rw [updated] at success
      simp only [bind, Except.bind, pure, Except.pure, Except.ok.injEq,
        Prod.mk.injEq] at success
      rcases success with ⟨rfl, _⟩
      rw [frame]
      simpa [middle, saveOperator] using counter

/-- Keep the source's final INVALID distinct from the aggregate setter's
Error(string). Neither error carries a state to commit. -/
inductive AllocatedLoadFailure where
  | invalid
  | revert (reason : Bytes)
  deriving DecidableEq

/-- Final loaded-count assertion precedes the aggregate deposited addition:
[NOR lines 861–865](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/nos/NodeOperatorsRegistry.sol#L861-L865).
Full-loader rollback must restore the state before all rows, not merely this
continuation's input state. -/
def finishAllocatedKeys (s : State) (loaded requested : Word) :
    Except AllocatedLoadFailure State :=
  if loaded ≠ requested then .error .invalid
  else match Packed64x4.add s.summarySigningKeysStats 3 loaded with
    | .error reason => .error (.revert reason)
    | .ok summary => .ok { s with summarySigningKeysStats := summary }

theorem finishAllocatedKeys_mismatch (s : State) (loaded requested : Word)
    (different : loaded ≠ requested) :
    finishAllocatedKeys s loaded requested = .error .invalid := by
  simp [finishAllocatedKeys, different]


/-- Successful finalization derives both the exact requested count and the
aggregate increase from the checked packed addition. Other operator state is
unchanged by this final step. -/
theorem finishAllocatedKeys_effect (s after : State) (loaded requested : Word)
    (success : finishAllocatedKeys s loaded requested = .ok after) :
    loaded = requested ∧ after.operators = s.operators ∧
      (packedGet after.summarySigningKeysStats 3).val =
        (packedGet s.summarySigningKeysStats 3).val + requested.val := by
  unfold finishAllocatedKeys at success
  split at success
  · cases success
  · rename_i equal
    have counts : loaded = requested := by simpa using equal
    cases added : Packed64x4.add s.summarySigningKeysStats 3 loaded with
    | error reason => simp [added] at success
    | ok summary =>
      simp only [added, Except.ok.injEq] at success
      subst after
      have effect := (Packed64x4.add_success _ _ _ _ added).1
      exact ⟨counts, rfl, by simpa only [counts] using effect⟩


/-- One row from its already-read operator id and active-count array element.
The source prefix determines the start/count; the actual SigningKeys memory
model runs before the loaded-count, event and packed-state continuation.
Storage/hash inputs still require physical account binding. Only SigningKeys
memory effects are threaded here: packed-struct loading, event ABI encoding
and maximum-update helper memory are not instantiated. This is not the full
row machine state. Array reads and buffer allocation also remain external. -/
def loadAllocatedRow (s : State) (machine : EvmYul.MachineState)
    (storage : SigningKeys.Storage) (keyOffset : SigningKeys.KeyOffset)
    (position : EvmYul.UInt256) (id active loaded : Word)
    (pubkeys signatures : EvmYul.UInt256) :
    Except AllocatedLoadFailure
      (State × EvmYul.MachineState × Word × List (Word × Word)) :=
  let signing := (s.operators id).signingKeysStats
  match allocatedKeyPrefix signing active with
  | .error .invalid => .error .invalid
  | .ok .unchanged => .ok (s, machine, loaded, [])
  | .ok (.load start count) =>
    let machine := SigningKeys.loadKeysSigs machine storage keyOffset position
      (EvmYul.UInt256.ofNat id.val) (EvmYul.UInt256.ofNat start.val)
      (EvmYul.UInt256.ofNat count.val) pubkeys signatures
      (EvmYul.UInt256.ofNat loaded.val)
    match commitAllocatedRow s id (allocatedDepositedAfter signing active) loaded count with
    | .error reason => .error (.revert reason)
    | .ok (after, next, events) => .ok (after, machine, next, events)

/-- The prefix's equality branch bypasses both the key-slot producer and the
packed-state continuation, preserving memory even for an inconsistent input. -/
theorem loadAllocatedRow_unchanged (s : State) (machine : EvmYul.MachineState)
    (storage : SigningKeys.Storage) (keyOffset : SigningKeys.KeyOffset)
    (position : EvmYul.UInt256) (id active loaded : Word)
    (pubkeys signatures : EvmYul.UInt256)
    (unchanged : allocatedKeyPrefix (s.operators id).signingKeysStats active = .ok .unchanged) :
    loadAllocatedRow s machine storage keyOffset position id active loaded pubkeys signatures =
      .ok (s, machine, loaded, []) := by
  simp only [loadAllocatedRow, unchanged]

end LidoSRv3.Audit.Source.NodeOperatorsRegistry
