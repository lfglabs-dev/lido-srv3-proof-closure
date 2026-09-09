import LidoSRv3.Audit.Source.SszWrapperIndex

namespace LidoSRv3.Tests.SszWrapperIndexMutants
open LidoSRv3.Audit.Source.SszWrapperIndex

def word (n : Nat) : Fin wordModulus := ⟨n % wordModulus, Nat.mod_lt _ (by decide)⟩
def slot (n : Nat) : Fin (2 ^ 64) := ⟨n % 2 ^ 64, Nat.mod_lt _ (by decide)⟩
def idx (n p : Nat) : PackedIndex :=
  ⟨⟨n % indexModulus, Nat.mod_lt _ (by decide)⟩,
    ⟨p % 256, Nat.mod_lt _ (by decide)⟩⟩
def cfg : Configuration := pinnedConfiguration (slot 100)

example : sourceWrapper cfg (slot 100) (word 0) = .ok (idx (1430 * 2 ^ 40) 40) := by decide
example : sourceWrapper cfg (slot 0) (word (2 ^ 40 - 1)) =
    .ok (idx (1431 * 2 ^ 40 - 1) 40) := by decide
example : sourceWrapper cfg (slot 100) (word (2 ^ 40)) = .error .indexOutOfRange := by decide
example : sourceWrapper cfg (slot 100) (word (2 ^ 256 - 1)) = .error .indexOutOfRange := by decide

/-- Dropping the header prefix preserves the state-relative index but supplies
exactly the wrong index to verification against a header root. -/
example : sourceNeighbor pinnedBase (word 0) = .ok pinnedBase ∧
    sourceWrapper cfg (slot 100) (word 0) ≠ .ok pinnedBase := by decide
example : sourceConcat (idx 10 3) pinnedBase ≠ sourceConcat stateRootIndex pinnedBase ∧
    sourceConcat (idx 12 3) pinnedBase ≠ sourceConcat stateRootIndex pinnedBase := by decide
example : sourceWrapper cfg (slot 100) (word 1) ≠ sourceWrapper cfg (slot 100) (word 0) := by decide

/-- Distinct synthetic layouts kill fork-direction and pivot-boundary mutants.
They are NOT the two equal layouts in the pinned deployment config file. -/
def syntheticFork : Configuration := ⟨pinnedBase, idx (151 * 2 ^ 40) 40, slot 100⟩
example : sourceWrapper syntheticFork (slot 99) (word 0) = .ok (idx (1430 * 2 ^ 40) 40) := by decide
example : sourceWrapper syntheticFork (slot 100) (word 0) = .ok (idx (1431 * 2 ^ 40) 40) := by decide
example : selected syntheticFork (slot 100) ≠ syntheticFork.previous := by decide

def wrongPivotSelect (c : Configuration) (s : Fin (2 ^ 64)) : PackedIndex :=
  if s.val ≤ c.pivotSlot.val then c.previous else c.current
example : wrongPivotSelect syntheticFork (slot 100) ≠ selected syntheticFork (slot 100) := by decide

/-- Generic zero/depth/packing boundaries distinguish source guards. -/
example : sourceConcat (idx 0 0) (idx 1 0) = .error .indexOutOfRange := by decide
example : sourceConcat (idx 1 0) (idx 0 0) = .error .indexOutOfRange := by decide
example : sourceConcat (idx (2 ^ 247) 0) (idx 1 0) = .ok (idx (2 ^ 247) 0) := by decide
example : sourceConcat (idx (2 ^ 247) 0) (idx 2 0) = .error .indexOutOfRange := by decide
example : sourceNeighbor (idx 1 255) (word (2 ^ 256 - 1)) = .error .arithmeticPanic := by decide
example : sourceNeighbor (idx (2 ^ 248 - 1) 255) (word 1) = .error .indexOutOfRange := by decide

/-- Source slot indexing checks the middle header sibling, not either neighbor. -/
example : sourceSlotSibling ([] : List Nat) = .error .arithmeticPanic := by decide
example : sourceSlotSibling [11] = .error .arithmeticPanic := by decide
example : sourceSlotSibling [11, 22, 33] = .ok 22 := by decide
example : ([11, 22, 33] : List Nat)[3 - 1]? ≠ some 22 ∧
    ([11, 22, 33] : List Nat)[3 - 3]? ≠ some 22 := by decide
example : treeBranch (fun a b : Nat => a * 100 + b)
    (headerTree 1 2 3 5 0 (.leaf 4)) [false, true, true] = some [3, 102, 50000] := by decide

/-- A deterministic test pair distinguishes the two numeric chunk positions;
it is not presented as SHA256 or as an injectivity premise. -/
def testPair (a b : BitVec 256) : BitVec 256 := a ^^^ (b >>> (128 : Nat))
def correctSlotPair : BitVec 256 :=
  testPair (LidoSRv3.Audit.Source.SszLittleEndianCorrespondence.uint64Chunk 1)
    (LidoSRv3.Audit.Source.SszLittleEndianCorrespondence.uint64Chunk 2)
example : sourceVerifySlotArithmetic testPair [3, correctSlotPair, 5] 1 2 = .ok () := by decide
example : sourceVerifySlotArithmetic testPair [3, correctSlotPair, 5] 1 3 = .error .invalidSlot := by decide
/-- Treating numeric fields as big-endian words changes the expected pair. -/
example : sourceVerifySlotArithmetic testPair [3, testPair 1 2, 5] 1 2 = .error .invalidSlot := by decide

end LidoSRv3.Tests.SszWrapperIndexMutants

#print axioms LidoSRv3.Audit.Source.SszWrapperIndex.concat_of_depth
#print axioms LidoSRv3.Audit.Source.SszWrapperIndex.wrapper_success
#print axioms LidoSRv3.Audit.Source.SszWrapperIndex.pinned_wrapper_accepts_iff
#print axioms LidoSRv3.Audit.Source.SszWrapperIndex.pinned_header_steps
#print axioms LidoSRv3.Audit.Source.SszWrapperIndex.slot_sibling_of_header_branch

#print axioms LidoSRv3.Audit.Source.SszWrapperIndex.encoded_slot_accepts_header_branch
