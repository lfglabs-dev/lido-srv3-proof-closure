import audit.trio.consolidation.Spec
import LidoSRv3.Audit.Source.ConsolidationCorrespondence

/-!
# Independent consolidation spec correspondence

This module is the explicit boundary between the trio lane's byte-length and
content-identity model and the pre-existing Verity transaction's four parallel
word arrays. It does not identify the two interpreters by definition.
-/

namespace LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence

def keyWord (key : audit.trio.consolidation.Pubkey) :
    LidoSRv3.Audit.SolidityConsolidation.Word :=
  Verity.Core.Uint256.ofNat key.identity

def lengthWord (key : audit.trio.consolidation.Pubkey) :
    LidoSRv3.Audit.SolidityConsolidation.Word :=
  Verity.Core.Uint256.ofNat key.length

def sourceWords (groups : List audit.trio.consolidation.WitnessGroup) :
    List LidoSRv3.Audit.SolidityConsolidation.Word :=
  (audit.trio.consolidation.preparedSources groups).map keyWord

def targetWords (groups : List audit.trio.consolidation.WitnessGroup) :
    List LidoSRv3.Audit.SolidityConsolidation.Word :=
  (audit.trio.consolidation.preparedTargets groups).map keyWord

def sourceLengthWords (groups : List audit.trio.consolidation.WitnessGroup) :
    List LidoSRv3.Audit.SolidityConsolidation.Word :=
  (audit.trio.consolidation.preparedSources groups).map lengthWord

def targetLengthWords (groups : List audit.trio.consolidation.WitnessGroup) :
    List LidoSRv3.Audit.SolidityConsolidation.Word :=
  (audit.trio.consolidation.preparedTargets groups).map lengthWord

theorem translated_array_lengths (groups : List audit.trio.consolidation.WitnessGroup) :
    (sourceWords groups).length = (targetWords groups).length ∧
    (sourceLengthWords groups).length = (sourceWords groups).length ∧
    (targetLengthWords groups).length = (targetWords groups).length := by
  simp [sourceWords, targetWords, sourceLengthWords, targetLengthWords,
    audit.trio.consolidation.prepared_lengths_eq]

/-- The arrays produced from the independent gateway flattening are accepted
by the existing transaction model's parallel-array zipper, with one request
per independently prepared pair. This closes the structural decode
correspondence; it does not claim compiler-memory correspondence. -/
theorem zipRequests_prepared (groups : List audit.trio.consolidation.WitnessGroup) :
    ∃ requests,
      LidoSRv3.Audit.SolidityConsolidation.zipRequests (sourceWords groups) (targetWords groups)
          (sourceLengthWords groups) (targetLengthWords groups) = some requests ∧
        requests.length = (audit.trio.consolidation.preparePairs groups).length := by
  have hl := translated_array_lengths groups
  unfold LidoSRv3.Audit.SolidityConsolidation.zipRequests
  simp only [hl.1, hl.2.1, hl.2.2, true_and, ↓reduceIte, Option.some.injEq]
  refine ⟨_, rfl, ?_⟩
  have hs := congrArg List.length
    (audit.trio.consolidation.preparePairs_sources groups)
  have hsource : (sourceWords groups).length =
      (audit.trio.consolidation.preparePairs groups).length := by
    rw [show (sourceWords groups).length =
      (audit.trio.consolidation.preparedSources groups).length by
        simp [sourceWords]]
    simpa using hs.symm
  simpa [List.length_zip, hl.1, hl.2.1, hl.2.2] using hsource

end LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence
