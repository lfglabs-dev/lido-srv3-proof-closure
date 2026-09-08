import LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence
import LidoSRv3.Audit.Verity.ConsolidationTx

/-!
# Grouped consolidation compiler-memory bridge

The existing transaction reads four memory-backed word arrays at fixed bases.
This file proves that `stateFor` physically stores and the compilation-model
`memoryArrayElement` expression reads back the arrays obtained from the
independent grouped gateway specification. The 128-element bound is exactly
the spacing between consecutive 0x1000 bases at 32 bytes per word.
-/

namespace LidoSRv3.Audit.Verity.TrioConsolidation.Memory

namespace CT
abbrev Word := LidoSRv3.Audit.Verity.ConsolidationTx.Word
abbrev readWord := LidoSRv3.Audit.Verity.ConsolidationTx.readWord
abbrev readArray := LidoSRv3.Audit.Verity.ConsolidationTx.readArray
abbrev arrayState := LidoSRv3.Audit.Verity.ConsolidationTx.arrayState
abbrev stateFor := LidoSRv3.Audit.Verity.ConsolidationTx.stateFor
abbrev memoryFor := LidoSRv3.Audit.Verity.ConsolidationTx.memoryFor
abbrev sourcesBase := LidoSRv3.Audit.Verity.ConsolidationTx.sourcesBase
abbrev targetsBase := LidoSRv3.Audit.Verity.ConsolidationTx.targetsBase
abbrev sourceLensBase := LidoSRv3.Audit.Verity.ConsolidationTx.sourceLensBase
abbrev targetLensBase := LidoSRv3.Audit.Verity.ConsolidationTx.targetLensBase
abbrev countSlot := LidoSRv3.Audit.Verity.ConsolidationTx.countSlot
abbrev observe := LidoSRv3.Audit.Verity.ConsolidationTx.observe
abbrev addRequests := LidoSRv3.Audit.Verity.ConsolidationTx.addRequests
abbrev sourceView := LidoSRv3.Audit.Verity.ConsolidationTx.sourceView
abbrev verity_tx_simulates_pinned_source :=
  LidoSRv3.Audit.Verity.ConsolidationTx.verity_tx_simulates_pinned_source
end CT

namespace C
abbrev keyWord :=
  LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.keyWord
abbrev sourceWords :=
  LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.sourceWords
abbrev targetWords :=
  LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.targetWords
abbrev sourceLengthWords :=
  LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.sourceLengthWords
abbrev targetLengthWords :=
  LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.targetLengthWords
abbrev translated_array_lengths :=
  LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.translated_array_lengths
end C

open _root_.Verity

private theorem wordNormalize_eq (n : Nat)
    (h : n < Verity.Core.Uint256.modulus) :
    Compiler.CompilationModel.Denote.wordNormalize n = n := by
  exact Nat.mod_eq_of_lt h

private theorem ofNat_val (w : CT.Word) : Verity.Core.Uint256.ofNat w.val = w :=
  Verity.Core.Uint256.ext (Nat.mod_eq_of_lt w.isLt)

private theorem read_source_word (xs ys sourceLens targetLens : List CT.Word)
    (base : ContractState) (i : Nat) (hi : i < xs.length)
    (hxs : xs.length ≤ 128) :
    CT.readWord (CT.stateFor xs ys sourceLens targetLens base) "sources"
      CT.sourcesBase xs.length i = some xs[i] := by
  have hni : Compiler.CompilationModel.Denote.wordNormalize i = i :=
    wordNormalize_eq i (by
      simp [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]
      omega)
  have haddr : Compiler.CompilationModel.Denote.wordNormalize (4096 + 32 * i) =
      4096 + 32 * i := wordNormalize_eq _ (by
        simp [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]
        omega)
  have hbinding : Compiler.CompilationModel.Denote.dynamicArrayBinding?
      [("sources_data_offset", 4096), ("sources_length", xs.length)]
      "sources" = some (4096, xs.length) := rfl
  simp [LidoSRv3.Audit.Verity.ConsolidationTx.readWord,
    LidoSRv3.Audit.Verity.ConsolidationTx.arrayState,
    Compiler.CompilationModel.Denote.evalExpr,
    hbinding, hni, haddr, ofNat_val,
    LidoSRv3.Audit.Verity.ConsolidationTx.stateFor,
    LidoSRv3.Audit.Verity.ConsolidationTx.memoryFor,
    LidoSRv3.Audit.Verity.ConsolidationTx.sourcesBase, hi]

private theorem read_target_word (xs ys sourceLens targetLens : List CT.Word)
    (base : ContractState) (i : Nat) (hi : i < ys.length)
    (hxs : xs.length ≤ 128) (hys : ys.length ≤ 128) :
    CT.readWord (CT.stateFor xs ys sourceLens targetLens base) "targets"
      CT.targetsBase ys.length i = some ys[i] := by
  have hni : Compiler.CompilationModel.Denote.wordNormalize i = i :=
    wordNormalize_eq i (by
      simp [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]
      omega)
  have haddr : Compiler.CompilationModel.Denote.wordNormalize (8192 + 32 * i) =
      8192 + 32 * i := wordNormalize_eq _ (by
        simp [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]
        omega)
  have hbinding : Compiler.CompilationModel.Denote.dynamicArrayBinding?
      [("targets_data_offset", 8192), ("targets_length", ys.length)]
      "targets" = some (8192, ys.length) := rfl
  have hnotSource : ¬ (4096 ≤ 8192 + 32 * i ∧
      8192 + 32 * i < 4096 + 32 * xs.length ∧
      (8192 + 32 * i - 4096) % 32 = 0) := by omega
  simp [LidoSRv3.Audit.Verity.ConsolidationTx.readWord,
    LidoSRv3.Audit.Verity.ConsolidationTx.arrayState,
    Compiler.CompilationModel.Denote.evalExpr,
    hbinding, hni, haddr, ofNat_val,
    LidoSRv3.Audit.Verity.ConsolidationTx.stateFor,
    LidoSRv3.Audit.Verity.ConsolidationTx.memoryFor,
    LidoSRv3.Audit.Verity.ConsolidationTx.sourcesBase,
    LidoSRv3.Audit.Verity.ConsolidationTx.targetsBase, hi, hnotSource]

private theorem read_source_length_word
    (xs ys sourceLens targetLens : List CT.Word) (base : ContractState)
    (i : Nat) (hi : i < sourceLens.length) (hxs : xs.length ≤ 128)
    (hys : ys.length ≤ 128) (hsourceLens : sourceLens.length ≤ 128) :
    CT.readWord (CT.stateFor xs ys sourceLens targetLens base) "sourceLens"
      CT.sourceLensBase sourceLens.length i = some sourceLens[i] := by
  have hni : Compiler.CompilationModel.Denote.wordNormalize i = i :=
    wordNormalize_eq i (by
      simp [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]
      omega)
  have haddr : Compiler.CompilationModel.Denote.wordNormalize (12288 + 32 * i) =
      12288 + 32 * i := wordNormalize_eq _ (by
        simp [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]
        omega)
  have hbinding : Compiler.CompilationModel.Denote.dynamicArrayBinding?
      [("sourceLens_data_offset", 12288),
       ("sourceLens_length", sourceLens.length)]
      "sourceLens" = some (12288, sourceLens.length) := rfl
  have hnotSource : ¬ (4096 ≤ 12288 + 32 * i ∧
      12288 + 32 * i < 4096 + 32 * xs.length ∧
      (12288 + 32 * i - 4096) % 32 = 0) := by omega
  have hnotTarget : ¬ (8192 ≤ 12288 + 32 * i ∧
      12288 + 32 * i < 8192 + 32 * ys.length ∧
      (12288 + 32 * i - 8192) % 32 = 0) := by omega
  simp [LidoSRv3.Audit.Verity.ConsolidationTx.readWord,
    LidoSRv3.Audit.Verity.ConsolidationTx.arrayState,
    Compiler.CompilationModel.Denote.evalExpr,
    hbinding, hni, haddr, ofNat_val,
    LidoSRv3.Audit.Verity.ConsolidationTx.stateFor,
    LidoSRv3.Audit.Verity.ConsolidationTx.memoryFor,
    LidoSRv3.Audit.Verity.ConsolidationTx.sourcesBase,
    LidoSRv3.Audit.Verity.ConsolidationTx.targetsBase,
    LidoSRv3.Audit.Verity.ConsolidationTx.sourceLensBase, hi, hnotSource,
    hnotTarget] <;>
    (try simp [List.getD, List.getElem?_eq_getElem hi]) <;> omega

private theorem read_target_length_word
    (xs ys sourceLens targetLens : List CT.Word) (base : ContractState)
    (i : Nat) (hi : i < targetLens.length) (hxs : xs.length ≤ 128)
    (hys : ys.length ≤ 128) (hsourceLens : sourceLens.length ≤ 128)
    (htargetLens : targetLens.length ≤ 128) :
    CT.readWord (CT.stateFor xs ys sourceLens targetLens base) "targetLens"
      CT.targetLensBase targetLens.length i = some targetLens[i] := by
  have hni : Compiler.CompilationModel.Denote.wordNormalize i = i :=
    wordNormalize_eq i (by
      simp [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]
      omega)
  have haddr : Compiler.CompilationModel.Denote.wordNormalize (16384 + 32 * i) =
      16384 + 32 * i := wordNormalize_eq _ (by
        simp [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]
        omega)
  have hbinding : Compiler.CompilationModel.Denote.dynamicArrayBinding?
      [("targetLens_data_offset", 16384),
       ("targetLens_length", targetLens.length)]
      "targetLens" = some (16384, targetLens.length) := rfl
  have hnotSource : ¬ (4096 ≤ 16384 + 32 * i ∧
      16384 + 32 * i < 4096 + 32 * xs.length ∧
      (16384 + 32 * i - 4096) % 32 = 0) := by omega
  have hnotTarget : ¬ (8192 ≤ 16384 + 32 * i ∧
      16384 + 32 * i < 8192 + 32 * ys.length ∧
      (16384 + 32 * i - 8192) % 32 = 0) := by omega
  have hnotSourceLens : ¬ (12288 ≤ 16384 + 32 * i ∧
      16384 + 32 * i < 12288 + 32 * sourceLens.length ∧
      (16384 + 32 * i - 12288) % 32 = 0) := by omega
  simp [LidoSRv3.Audit.Verity.ConsolidationTx.readWord,
    LidoSRv3.Audit.Verity.ConsolidationTx.arrayState,
    Compiler.CompilationModel.Denote.evalExpr,
    hbinding, hni, haddr, ofNat_val,
    LidoSRv3.Audit.Verity.ConsolidationTx.stateFor,
    LidoSRv3.Audit.Verity.ConsolidationTx.memoryFor,
    LidoSRv3.Audit.Verity.ConsolidationTx.sourcesBase,
    LidoSRv3.Audit.Verity.ConsolidationTx.targetsBase,
    LidoSRv3.Audit.Verity.ConsolidationTx.sourceLensBase,
    LidoSRv3.Audit.Verity.ConsolidationTx.targetLensBase, hi, hnotSource,
    hnotTarget, hnotSourceLens] <;>
    (try simp [List.getD, List.getElem?_eq_getElem hi]) <;> omega

private theorem map_range_getD {α : Type} [Inhabited α] (xs : List α) :
    (List.range xs.length).map (fun i => xs.getD i default) = xs := by
  apply List.ext_getElem
  · simp
  · intro n hleft hright
    have hrange : n < (List.range xs.length).length := by simpa using hright
    simp [List.getD, List.getElem_range hrange,
      List.getElem?_eq_getElem hright]

private theorem readArray_of_pointwise (state : ContractState) (name : String)
    (base : Nat) (xs : List CT.Word)
    (hread : ∀ i, i < xs.length →
      CT.readWord state name base xs.length i = some (xs.getD i 0)) :
    CT.readArray state name base xs.length = some xs := by
  change (List.range xs.length).mapM
    (CT.readWord state name base xs.length) = some xs
  have hmap : ∀ indices : List Nat,
      (∀ i ∈ indices, i < xs.length) →
      indices.mapM (CT.readWord state name base xs.length) =
        some (indices.map fun i => xs.getD i 0) := by
    intro indices hindices
    induction indices with
    | nil => rfl
    | cons i rest ih =>
        have hi := hindices i (by simp)
        have hrest : ∀ j ∈ rest, j < xs.length := by
          intro j hj
          exact hindices j (by simp [hj])
        simp [hread i hi, ih hrest]
  rw [hmap (List.range xs.length) (by simp)]
  exact congrArg some (map_range_getD xs)

def stateForGroups (groups : List audit.trio.consolidation.WitnessGroup)
    (base : ContractState) : ContractState :=
  CT.stateFor (C.sourceWords groups) (C.targetWords groups)
    (C.sourceLengthWords groups) (C.targetLengthWords groups) base

/-- All four concrete compilation-model memory reads are discharged from one
bound on the flattened request count. -/
theorem decode_stateForGroups
    (groups : List audit.trio.consolidation.WitnessGroup)
    (base : ContractState)
    (hbound : (audit.trio.consolidation.preparedSources groups).length ≤ 128) :
    CT.readArray (stateForGroups groups base) "sources" CT.sourcesBase
        (C.sourceWords groups).length = some (C.sourceWords groups) ∧
    CT.readArray (stateForGroups groups base) "targets" CT.targetsBase
        (C.targetWords groups).length = some (C.targetWords groups) ∧
    CT.readArray (stateForGroups groups base) "sourceLens" CT.sourceLensBase
        (C.sourceLengthWords groups).length = some (C.sourceLengthWords groups) ∧
    CT.readArray (stateForGroups groups base) "targetLens" CT.targetLensBase
        (C.targetLengthWords groups).length = some (C.targetLengthWords groups) := by
  have hl := C.translated_array_lengths groups
  have hs : (C.sourceWords groups).length ≤ 128 := by
    change ((audit.trio.consolidation.preparedSources groups).map C.keyWord).length ≤ 128
    simpa using hbound
  have ht : (C.targetWords groups).length ≤ 128 := hl.1 ▸ hs
  have hsl : (C.sourceLengthWords groups).length ≤ 128 := hl.2.1 ▸ hs
  have htl : (C.targetLengthWords groups).length ≤ 128 := hl.2.2 ▸ ht
  refine ⟨readArray_of_pointwise _ _ _ _ fun i hi => ?_,
    readArray_of_pointwise _ _ _ _ fun i hi => ?_,
    readArray_of_pointwise _ _ _ _ fun i hi => ?_,
    readArray_of_pointwise _ _ _ _ fun i hi => ?_⟩
  · simpa [stateForGroups, List.getD, List.getElem?_eq_getElem hi] using
      read_source_word _ _ _ _ base i hi hs
  · simpa [stateForGroups, List.getD, List.getElem?_eq_getElem hi] using
      read_target_word _ _ _ _ base i hi hs ht
  · simpa [stateForGroups, List.getD, List.getElem?_eq_getElem hi] using
      read_source_length_word _ _ _ _ base i hi hs ht hsl
  · simpa [stateForGroups, List.getD, List.getElem?_eq_getElem hi] using
      read_target_length_word _ _ _ _ base i hi hs ht hsl htl

def inputsForGroups (groups : List audit.trio.consolidation.WitnessGroup)
    (caller gateway requestTarget fee msgValue : CT.Word) :
    LidoSRv3.Audit.SolidityConsolidation.Inputs :=
  { caller := caller
    gateway := gateway
    requestTarget := requestTarget
    fee := fee
    msgValue := msgValue
    sources := C.sourceWords groups
    targets := C.targetWords groups
    sourceLens := C.sourceLengthWords groups
    targetLens := C.targetLengthWords groups }

/-- The existing executed Verity transaction simulates its pinned-source view
for independently grouped gateway input, with all four decode premises derived
from the concrete memory constructor. -/
theorem grouped_tx_simulates
    (groups : List audit.trio.consolidation.WitnessGroup)
    (caller gateway requestTarget fee msgValue : CT.Word)
    (base : ContractState)
    (hMemory : (audit.trio.consolidation.preparedSources groups).length ≤ 128)
    (hCount : (base.readSlot CT.countSlot).val + (C.sourceWords groups).length <
      Verity.Core.Uint256.modulus)
    (hEntry : base.selfBalance.val + msgValue.val < Verity.Core.Uint256.modulus) :
    let inputs := inputsForGroups groups caller gateway requestTarget fee msgValue
    let state := stateForGroups groups base
    CT.observe state ((CT.addRequests inputs).run state) =
      CT.sourceView inputs (state.readSlot CT.countSlot).val := by
  dsimp only
  have hdecode := decode_stateForGroups groups base hMemory
  apply CT.verity_tx_simulates_pinned_source
  · change (base.readSlot CT.countSlot).val + (C.sourceWords groups).length <
      Verity.Core.Uint256.modulus
    exact hCount
  · change base.selfBalance.val + msgValue.val < Verity.Core.Uint256.modulus
    exact hEntry
  · exact hdecode.1
  · exact hdecode.2.1
  · exact hdecode.2.2.1
  · exact hdecode.2.2.2

end LidoSRv3.Audit.Verity.TrioConsolidation.Memory
