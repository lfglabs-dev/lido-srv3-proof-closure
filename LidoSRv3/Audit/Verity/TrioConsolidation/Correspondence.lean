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

/-- Every request decoded from the independently prepared gateway arrays has
the two 48-byte lengths required by the pinned vault loop. -/
theorem zipRequests_prepared_valid
    (groups : List audit.trio.consolidation.WitnessGroup)
    (requests : List LidoSRv3.Audit.SolidityConsolidation.Request)
    (hzip : LidoSRv3.Audit.SolidityConsolidation.zipRequests
      (sourceWords groups) (targetWords groups)
      (sourceLengthWords groups) (targetLengthWords groups) = some requests)
    (hvalid : ∀ pair ∈ audit.trio.consolidation.preparePairs groups,
      pair.1.length = audit.trio.consolidation.pubkeyLength ∧
      pair.2.length = audit.trio.consolidation.pubkeyLength) :
    requests.all LidoSRv3.Audit.SolidityConsolidation.validRequest = true := by
  have hl := translated_array_lengths groups
  unfold LidoSRv3.Audit.SolidityConsolidation.zipRequests at hzip
  simp only [hl.1, hl.2.1, hl.2.2, true_and, ↓reduceIte,
    Option.some.injEq] at hzip
  subst requests
  rw [List.all_eq_true]
  intro request hrequest
  simp only [List.mem_map] at hrequest
  obtain ⟨pair, hpair, rfl⟩ := hrequest
  rcases pair with ⟨⟨source, target⟩, sourceLen, targetLen⟩
  have hsourceLen : sourceLen =
      LidoSRv3.Audit.SolidityConsolidation.publicKeyBytes := by
    have hmem := (List.of_mem_zip (List.of_mem_zip hpair).2).1
    simp only [sourceLengthWords, List.mem_map] at hmem
    obtain ⟨key, hkey, rfl⟩ := hmem
    rw [← audit.trio.consolidation.preparePairs_sources] at hkey
    simp only [List.mem_map] at hkey
    obtain ⟨preparedPair, hpreparedPair, hkey⟩ := hkey
    have hlength := (hvalid preparedPair hpreparedPair).1
    subst key
    unfold lengthWord
    rw [hlength]
    rfl
  have htargetLen : targetLen =
      LidoSRv3.Audit.SolidityConsolidation.publicKeyBytes := by
    have hmem := (List.of_mem_zip (List.of_mem_zip hpair).2).2
    simp only [targetLengthWords, List.mem_map] at hmem
    obtain ⟨key, hkey, rfl⟩ := hmem
    rw [← audit.trio.consolidation.preparePairs_targets] at hkey
    simp only [List.mem_map] at hkey
    obtain ⟨preparedPair, hpreparedPair, hkey⟩ := hkey
    have hlength := (hvalid preparedPair hpreparedPair).2
    subst key
    unfold lengthWord
    rw [hlength]
    rfl
  simp [LidoSRv3.Audit.SolidityConsolidation.validRequest,
    hsourceLen, htargetLen]

/-- Closed gateway-to-vault success correspondence for the real pinned
functions. If the independent `_prepareConsolidationPairs` output passes the
guards of `_addConsolidationRequests`, then the pinned-source interpreter of
`WithdrawalVault.addConsolidationRequests` reaches its committed exit with
the same flattened request count and exact fee. -/
theorem prepared_vault_guards_close_source_exit
    (groups : List audit.trio.consolidation.WitnessGroup)
    (caller requestTarget fee msgValue : LidoSRv3.Audit.SolidityConsolidation.Word)
    (hnonempty : audit.trio.consolidation.preparedSources groups ≠ [])
    (hvalid : ∀ pair ∈ audit.trio.consolidation.preparePairs groups,
      pair.1.length = audit.trio.consolidation.pubkeyLength ∧
      pair.2.length = audit.trio.consolidation.pubkeyLength)
    (hfit : (audit.trio.consolidation.preparedSources groups).length * fee.val < 2 ^ 256)
    (hvalue : msgValue.val =
      (audit.trio.consolidation.preparedSources groups).length * fee.val) :
    let inputs : LidoSRv3.Audit.SolidityConsolidation.Inputs :=
      { caller := caller, gateway := caller, requestTarget := requestTarget,
        fee := fee, msgValue := msgValue,
        sources := sourceWords groups, targets := targetWords groups,
        sourceLens := sourceLengthWords groups,
        targetLens := targetLengthWords groups }
    ∃ obs requests,
      LidoSRv3.Audit.SolidityConsolidation.sourceRun inputs = .committed obs ∧
      LidoSRv3.Audit.SolidityConsolidation.zipRequests inputs.sources inputs.targets
        inputs.sourceLens inputs.targetLens = some requests ∧
      requests.length = (audit.trio.consolidation.preparePairs groups).length ∧
      obs.requestCount = requests.length ∧ obs.feePaid = msgValue := by
  dsimp
  obtain ⟨requests, hzip, hlength⟩ := zipRequests_prepared groups
  have hrequestsValid := zipRequests_prepared_valid groups requests hzip hvalid
  have hsourcesLength : (sourceWords groups).length =
      (audit.trio.consolidation.preparedSources groups).length := by
    simp [sourceWords]
  have hsourcesNonempty : (sourceWords groups).length ≠ 0 := by
    intro hzero
    apply hnonempty
    exact List.length_eq_zero_iff.mp (hsourcesLength ▸ hzero)
  have hpairsLength : (audit.trio.consolidation.preparePairs groups).length =
      (audit.trio.consolidation.preparedSources groups).length := by
    simpa using congrArg List.length
      (audit.trio.consolidation.preparePairs_sources groups)
  have hbound : requests.length * fee.val ≤ Verity.Core.MAX_UINT256 := by
    rw [hlength, hpairsLength]
    exact Nat.le_pred_of_lt hfit
  have hfee : msgValue.val = requests.length * fee.val := by
    rw [hlength, hpairsLength]
    exact hvalue
  let obs := LidoSRv3.Audit.SolidityConsolidation.commitObservables
    requestTarget fee msgValue requests
  refine ⟨obs, requests, ?_, hzip, hlength, rfl, rfl⟩
  simp [LidoSRv3.Audit.SolidityConsolidation.sourceRun, hsourcesNonempty,
    hzip, hrequestsValid, hbound, hfee, obs]

end LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence
