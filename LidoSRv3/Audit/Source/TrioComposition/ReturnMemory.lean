import LidoSRv3.Audit.Source.TrioAlloc1.Bytes
import LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory
import LidoSRv3.Audit.Source.TrioAlloc1.CallTree

/-! Successful STATICCALL response allocation precedes ABI decoding in the
pinned optimized IR. The output area copies at most 96 summary bytes or 32 stake
bytes. This models buffer bytes and free-pointer arithmetic, not EVM memory
stores, gas, or a completed parent allocation schedule. -/
namespace LidoSRv3.Audit.Source.TrioComposition.ReturnMemory
open TrioAlloc1

private theorem decodeWord_take (data : Bytes) (width offset : Nat)
    (fits : offset+32 ≤ width) : decodeWord (data.take width) offset = decodeWord data offset := by
  unfold decodeWord
  rw [List.drop_take, List.take_take, Nat.min_eq_left (by omega)]

theorem summary_take (data : Bytes) : decodeSummary (data.take 96) = decodeSummary data := by
  simp only [decodeSummary, List.length_take]
  by_cases short : data.length < 96
  · have clipped : min 96 data.length < 96 := by omega
    simp [short, clipped]
  · have clipped : ¬ min 96 data.length < 96 := by omega
    simp only [short, clipped, ↓reduceIte, decodeWord_take data 96 0 (by omega),
      decodeWord_take data 96 32 (by omega), decodeWord_take data 96 64 (by omega)]

theorem stake_take (data : Bytes) : decodeStake (data.take 32) = decodeStake data := by
  simp only [decodeStake, List.length_take]
  by_cases short : data.length < 32
  · have clipped : min 32 data.length < 32 := by omega
    simp [short, clipped]
  · have clipped : ¬ min 32 data.length < 32 := by omega
    simp only [short, clipped, ↓reduceIte, decodeWord_take data 32 0 (by omega)]

def decodeAllocated (width : Nat) (decoder : Bytes → Except Failure α)
    (pointer : Word) (data : Bytes) : Except Failure (α × Word) := do
  let next ← AllocationMemory.finalize pointer (word (min width data.length))
  let value ← decoder (data.take width)
  pure (value, next)

def summary (pointer : Word) (target : Address) : CallTree.Program (Summary × Word) := do
  let data ← CallTree.call ⟨target, summaryPayload⟩
  CallTree.check (decodeAllocated 96 decodeSummary pointer data)

def stake (pointer : Word) (target : Address) : CallTree.Program (Word × Word) := do
  let data ← CallTree.call ⟨target, stakePayload⟩
  CallTree.check (decodeAllocated 32 decodeStake pointer data)

/-- Allocation panic takes precedence even when the copied bytes are too short. -/
theorem allocation_failure (width : Nat) (decoder : Bytes → Except Failure α)
    (pointer : Word) (data : Bytes) (reason : Failure)
    (failed : AllocationMemory.finalize pointer (word (min width data.length)) = .error reason) :
    decodeAllocated width decoder pointer data = .error reason := by
  simp [decodeAllocated, failed, bind, Except.bind]

theorem allocated_projection (width : Nat) (decoder : Bytes → Except Failure α)
    (pointer next : Word) (data : Bytes)
    (allocated : AllocationMemory.finalize pointer (word (min width data.length)) = .ok next) :
    (decodeAllocated width decoder pointer data).map Prod.fst = decoder (data.take width) := by
  simp only [decodeAllocated, allocated, bind, Except.bind]
  cases decoder (data.take width) <;> rfl

/-- Small live pointers allocate every possible bounded return prefix. The
callee's returned length is not assumed to fit a machine word. -/
theorem bounded_finalize (pointer : Word) (size : Nat) (hp : pointer.val ≤ 2^32) (hs : size ≤ 96) :
    AllocationMemory.finalize pointer (word size) =
      .ok (word (pointer.val + (size+31)/32*32)) := by
  have sizeBound : size < 2^256 := by omega
  have roundedBound : size+31 < 2^256 := by omega
  have rounded : AllocationMemory.roundedSize (word size) = (size+31)/32*32 := by
    simp only [AllocationMemory.roundedSize, word, Nat.mod_eq_of_lt sizeBound,
      Nat.mod_eq_of_lt roundedBound]
  have roundSmall : (size+31)/32*32 ≤ 96 := by omega
  have nextBound : pointer.val+(size+31)/32*32 < 2^256 := by omega
  have noFail : ¬ ((word (pointer.val+(size+31)/32*32)).val > AllocationMemory.limit ∨
      (word (pointer.val+(size+31)/32*32)).val < pointer.val) := by
    simp only [word, Nat.mod_eq_of_lt nextBound]
    unfold AllocationMemory.limit
    omega
  simp only [AllocationMemory.finalize, rounded, noFail, ↓reduceIte]

theorem bounded_summary_projection (pointer : Word) (data : Bytes) (hp : pointer.val ≤ 2^32) :
    (decodeAllocated 96 decodeSummary pointer data).map Prod.fst = decodeSummary data := by
  rw [allocated_projection 96 decodeSummary pointer _ data
    (bounded_finalize pointer _ hp (Nat.min_le_left ..)), summary_take]

theorem bounded_stake_projection (pointer : Word) (data : Bytes) (hp : pointer.val ≤ 2^32) :
    (decodeAllocated 32 decodeStake pointer data).map Prod.fst = decodeStake data := by
  rw [allocated_projection 32 decodeStake pointer _ data
    (bounded_finalize pointer _ hp (by have := Nat.min_le_left 32 data.length; omega)), stake_take]

/-- Erasure preserves both decoding failures and the actual attempted-call
transcript; allocation safety is derived from the pointer bound for every reply. -/
theorem summary_correspondence (pointer : Word) (target : Address) (oracle : StaticOracle)
    (before : Transcript) (hp : pointer.val ≤ 2^32) :
    let actual := CallTree.evaluate oracle (summary pointer target) before
    (actual.1.map Prod.fst, actual.2) =
      (do
        let data ← staticCall oracle ⟨target,summaryPayload⟩
        liftChecked (decodeSummary data)) before := by
  simp only [summary, CallTree.evaluate_monad_bind, CallTree.evaluate_call, CallTree.evaluate_check]
  simp only [bind, bindExec, staticCall, liftChecked]
  cases response : oracle before ⟨target,summaryPayload⟩ with
  | returned data => exact Prod.ext (bounded_summary_projection pointer data hp) rfl
  | reverted data => rfl
  | exceptional => rfl

theorem stake_correspondence (pointer : Word) (target : Address) (oracle : StaticOracle)
    (before : Transcript) (hp : pointer.val ≤ 2^32) :
    let actual := CallTree.evaluate oracle (stake pointer target) before
    (actual.1.map Prod.fst, actual.2) =
      (do
        let data ← staticCall oracle ⟨target,stakePayload⟩
        liftChecked (decodeStake data)) before := by
  simp only [stake, CallTree.evaluate_monad_bind, CallTree.evaluate_call, CallTree.evaluate_check]
  simp only [bind, bindExec, staticCall, liftChecked]
  cases response : oracle before ⟨target,stakePayload⟩ with
  | returned data => exact Prod.ext (bounded_stake_projection pointer data hp) rfl
  | reverted data => rfl
  | exceptional => rfl

/-- A returned reply whose allocation fails retains exactly its attempted call. -/
theorem summary_allocation_failure (pointer : Word) (target : Address) (oracle : StaticOracle)
    (before : Transcript) (data : Bytes) (reason : Failure)
    (response : oracle before ⟨target,summaryPayload⟩ = .returned data)
    (failed : AllocationMemory.finalize pointer (word (min 96 data.length)) = .error reason) :
    CallTree.evaluate oracle (summary pointer target) before =
      (.error reason, before ++ [⟨⟨target,summaryPayload⟩,.returned data⟩]) := by
  simp only [summary, CallTree.evaluate_monad_bind, CallTree.evaluate_call, CallTree.evaluate_check]
  simp only [bind, bindExec, staticCall, response, liftChecked]
  rw [allocation_failure _ _ _ _ _ failed]

#print axioms summary_correspondence
#print axioms stake_correspondence
#print axioms summary_allocation_failure

#print axioms summary_take
#print axioms allocation_failure
#print axioms bounded_summary_projection
#print axioms bounded_stake_projection
end LidoSRv3.Audit.Source.TrioComposition.ReturnMemory
