import LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence

namespace LidoSRv3.Tests.TrioConsolidation.Correspondence

open audit.trio.consolidation
open LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence

private def key (id : Nat) : Pubkey := ⟨id, 48⟩

private def groups : List WitnessGroup :=
  [⟨[key 11, key 12], key 21⟩, ⟨[key 13], key 22⟩]

example : ∃ requests,
    LidoSRv3.Audit.SolidityConsolidation.zipRequests
        (sourceWords groups) (targetWords groups)
        (sourceLengthWords groups) (targetLengthWords groups) = some requests ∧
      requests.length = 3 := by
  obtain ⟨requests, hzip, hlength⟩ := zipRequests_prepared groups
  exact ⟨requests, hzip, by simpa [groups, preparePairs] using hlength⟩

/-- Regression: the independently prepared three-request batch discharges
the guards of the pinned vault entrypoint and reaches its committed exit. -/
example :
    let inputs : LidoSRv3.Audit.SolidityConsolidation.Inputs :=
      { caller := word 31, gateway := word 31, requestTarget := word 41,
        fee := word 2, msgValue := word 6,
        sources := sourceWords groups, targets := targetWords groups,
        sourceLens := sourceLengthWords groups,
        targetLens := targetLengthWords groups }
    ∃ obs requests,
      LidoSRv3.Audit.SolidityConsolidation.sourceRun inputs = .committed obs ∧
      LidoSRv3.Audit.SolidityConsolidation.zipRequests inputs.sources inputs.targets
        inputs.sourceLens inputs.targetLens = some requests ∧
      requests.length = 3 ∧ obs.requestCount = requests.length ∧
      obs.feePaid = word 6 := by
  have hclosed := prepared_vault_guards_close_source_exit groups
    (word 31) (word 41) (word 2) (word 6)
    (by decide) (by decide) (by decide) (by decide)
  simpa [groups, preparePairs] using hclosed

end LidoSRv3.Tests.TrioConsolidation.Correspondence
