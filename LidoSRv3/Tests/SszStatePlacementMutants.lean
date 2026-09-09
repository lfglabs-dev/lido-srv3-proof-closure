import LidoSRv3.Audit.Source.SszStatePlacement

namespace LidoSRv3.Tests.SszStatePlacementMutants
open LidoSRv3.Audit.Source SszPerfectTree SszStatePlacement SszWrapperIndex
open SszValidatorLeaf SszVerifierEntry SszProofFold

set_option maxRecDepth 8192
set_option maxHeartbeats 4000000

/-- Noncommutative regression hash; no cryptographic claim. -/
def mix (a b : Nat) := 131 * a + 17 * b + 7
def numbered (i : Nat) : Tree Nat := .leaf (i + 1)

/-- Exhaustive small symbolic-spine positions, tested by actual reduction. -/
example : ∀ d : Fin 6, ∀ i : Fin (2 ^ d.val),
    (subtreeAt (perfectTree d.val numbered) (addressPath d.val i.val)).map (treeDigest mix) =
      some (i.val + 1) := by decide
example : ∀ d : Fin 6, ∀ i : Fin (2 ^ d.val),
    treeIndex (addressPath d.val i.val) = 2 ^ d.val + i.val := by decide
example : ∀ d : Fin 6, treeDigest mix (perfectTree d.val numbered) =
    orderedMerkle mix 0 d.val ((List.range (2 ^ d.val)).map (fun i => i + 1)) := by decide
example : treeDigest mix (perfectTree 2 numbered) = 30495 := by decide
example : orderedMerkle mix 0 2 [1, 2, 3, 0] = 29339 := by decide
example : orderedMerkle mix 0 2 [1, 2, 3, 0] ≠ orderedMerkle mix 0 2 [1, 2, 3, 255] := by decide
example : orderedMerkle mix 0 2 [1, 2, 3, 0] ≠ orderedMerkle mix 0 2 [0, 3, 2, 1] := by decide
example : chunks 2 (fun i => ([1, 2, 3] : List Nat)[i]?.getD 0) = [1, 2, 3, 0] := by decide
example : chunks 2 (fun i => ([] : List Nat)[i]?.getD 0) = [0, 0, 0, 0] := by decide
example : treeDigest mix (perfectTree 2 (fun _ => .leaf 0)) ≠ 0 := by decide
example : addressPath 2 1 = [false, true] ∧ addressPath 2 2 = [true, false] := by decide

/-- Depth40 stays symbolic, including both capacity edges. -/
example (values : Nat → Tree Nat) :
    subtreeAt (perfectTree 40 values) (addressPath 40 0) = some (values 0) :=
  perfect_subtree 40 0 values (by decide)
example (values : Nat → Tree Nat) :
    subtreeAt (perfectTree 40 values) (addressPath 40 (2 ^ 40 - 1)) = some (values (2 ^ 40 - 1)) :=
  perfect_subtree 40 _ values (by decide)
example : treeIndex (statePath (2 ^ 40 - 1)) = 151 * 2 ^ 40 - 1 := by
  have h := state_path_index (2 ^ 40 - 1) (by decide)
  omega

/-- Independent immutable schema facts and wrong-container/field/edge mutants. -/
example : (fields .electra).length = 37 ∧ (fields .fulu).length = 38 := by decide
example : (fields .electra)[11]? = some .validators ∧ (fields .fulu)[11]? = some .validators := by decide
example : (fields .electra)[36]? = some .pendingConsolidations ∧
    (fields .fulu)[37]? = some .proposerLookahead := by decide
example : (fields .electra)[10]? = some .eth1DepositIndex ∧
    (fields .electra)[12]? = some .balances := by decide
example : addressPath 6 11 ++ [false] = [false, false, true, false, true, true, false] := by decide
example : treeIndex (addressPath 5 11 ++ [false]) = 86 ∧
    treeIndex (addressPath 6 11 ++ [false]) = 150 := by decide
example : treeIndex (addressPath 6 11 ++ [true]) = 151 := by decide
example : treeIndex (addressPath 6 10 ++ [false]) ≠ 150 ∧
    treeIndex (addressPath 6 12 ++ [false]) ≠ 150 := by decide

/-- uint256 length serialization, not ABI big-endian and not an input root. -/
example : digestBytes (lengthChunk 0) = List.replicate 32 0 := by decide
example : digestBytes (lengthChunk 1) = 1 :: List.replicate 31 0 := by decide
example : digestBytes (lengthChunk 258) = [2, 1] ++ List.replicate 30 0 := by decide
example : digestBytes (lengthChunk (2 ^ 40)) = List.replicate 5 0 ++ [1] ++ List.replicate 26 0 := by decide
example : digestBytes (lengthChunk 258) ≠ timestampPayload 258 := by decide
example : lengthChunk 1 ≠ lengthChunk 2 := by decide

def witness : Witness := ⟨List.replicate 48 7, 3, true, 4, 5, 6, 7⟩
def value : ValidatorValue := ⟨witness, 9, by decide⟩
def singleton : List ValidatorValue := [value]
def singletonBound : singleton.length ≤ capacity := by decide

def toySha (bytes : List Byte) : Digest := BitVec.ofNat 256
  (1 + 2 * (bytes[31]?.getD 0).toNat + 3 * (bytes[63]?.getD 0).toNat +
    5 * (bytes[0]?.getD 0).toNat + 7 * (bytes[32]?.getD 0).toNat)
def smallData : Digest := treeDigest (pair toySha) (perfectTree 2 (validatorElement toySha singleton))

/-- Real small semantic validator + zero padding + length; mutations alter this
concrete toy digest. These are witnesses, not universal hash inequalities. -/
example : pair toySha smallData (lengthChunk singleton.length) ≠ smallData := by decide
example : pair toySha smallData (lengthChunk singleton.length) ≠
    pair toySha (lengthChunk singleton.length) smallData := by decide
example : pair toySha smallData (lengthChunk singleton.length) ≠
    pair toySha smallData 1 := by decide

/-- Capacity admission is not list membership. No giant tree is normalized. -/
example : 1 < capacity ∧ ¬1 < singleton.length := by decide
example : ¬0 < ([] : List ValidatorValue).length := by decide
example (sha : Sha) :
    subtreeAt (registryTree sha singleton) (false :: addressPath 40 1) = some (.leaf 0) :=
  registry_padding_subtree sha singleton 1 (by decide) (by decide)
example (sha : Sha) :
    subtreeAt (registryTree sha singleton) (false :: addressPath 40 0) =
      some (validatorTree sha witness 9) :=
  registry_member_subtree sha singleton singletonBound ⟨0, by decide⟩
example (sha : Sha) (other : OtherFieldRoots) :
    subtreeAt (stateTree sha .fulu singleton other) (statePath 0) =
      some (validatorTree sha witness 9) :=
  state_member_subtree sha .fulu singleton other singletonBound ⟨0, by decide⟩
example (sha : Sha) : ∃ dataProof,
    treeBranch (pair sha) (registryData sha singleton) (addressPath 40 0) = some dataProof ∧
    dataProof.length = 40 ∧
    treeBranch (pair sha) (registryTree sha singleton) (false :: addressPath 40 0) =
      some (dataProof ++ [lengthChunk 1]) :=
  registry_length_sibling sha singleton singletonBound ⟨0, by decide⟩
example (pivot slot : Fin (2 ^ 64)) : ∃ out,
    sourceWrapper (pinnedConfiguration pivot) slot (memberOffset singleton singletonBound ⟨0, by decide⟩) = .ok out :=
  member_wrapper_accepts singleton singletonBound ⟨0, by decide⟩ pivot slot

/-- The actual configured guard also admits the first padded index. This does
not assert full-entry admission or a universal hash inequality. -/
example (pivot slot : Fin (2 ^ 64)) : ∃ out,
    sourceWrapper (pinnedConfiguration pivot) slot
      ⟨singleton.length, by decide⟩ = .ok out := by
  apply (pinned_wrapper_accepts_iff _ _ _).mpr
  decide

#print axioms perfect_digest_ordered
#print axioms chunks_padding
#print axioms perfect_subtree
#print axioms registry_chunks
#print axioms length_encoding_no_wrap
#print axioms state_root_ordered_fields
#print axioms state_member_subtree
#print axioms registry_length_sibling
#print axioms canonical_validator_entry

end LidoSRv3.Tests.SszStatePlacementMutants
