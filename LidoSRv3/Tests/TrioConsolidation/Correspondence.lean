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

end LidoSRv3.Tests.TrioConsolidation.Correspondence
