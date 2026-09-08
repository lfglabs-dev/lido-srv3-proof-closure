import LidoSRv3.Audit.Verity.TrioConsolidation.Memory

namespace LidoSRv3.Tests.TrioConsolidation.Memory

namespace M
abbrev stateForGroups := LidoSRv3.Audit.Verity.TrioConsolidation.Memory.stateForGroups
abbrev decode_stateForGroups :=
  LidoSRv3.Audit.Verity.TrioConsolidation.Memory.decode_stateForGroups
end M
namespace C
abbrev sourceWords := LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.sourceWords
abbrev targetLengthWords :=
  LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.targetLengthWords
end C
namespace CT
abbrev readArray := LidoSRv3.Audit.Verity.ConsolidationTx.readArray
abbrev sourcesBase := LidoSRv3.Audit.Verity.ConsolidationTx.sourcesBase
abbrev targetLensBase := LidoSRv3.Audit.Verity.ConsolidationTx.targetLensBase
end CT

open audit.trio.consolidation
open Verity

private def key (id : Nat) : Pubkey := ⟨id, 48⟩
private def groups : List WitnessGroup :=
  [⟨[key 11, key 12], key 21⟩, ⟨[key 13], key 22⟩]

example :
    CT.readArray (M.stateForGroups groups defaultState) "sources" CT.sourcesBase
      (C.sourceWords groups).length = some (C.sourceWords groups) :=
  (M.decode_stateForGroups groups defaultState (by decide)).1

example :
    CT.readArray (M.stateForGroups groups defaultState) "targetLens"
      CT.targetLensBase (C.targetLengthWords groups).length =
        some (C.targetLengthWords groups) :=
  (M.decode_stateForGroups groups defaultState (by decide)).2.2.2

end LidoSRv3.Tests.TrioConsolidation.Memory
