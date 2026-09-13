import LidoSRv3.Audit.Source.WithdrawalQueueMappingSource

/-! # Kill-lines for `WithdrawalQueueMappingSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the WQ storage projection semantics.**

`WithdrawalQueueMappingSource` names three source-level reads over
`WithdrawalQueueStorage`:
- `readRequest wqs requestId`.
- `readCheckpoint wqs hint`.
- `unfinalizedStETHFromStorage wqs = wqs.unfinalizedStETH`.

These kill-lines pin each projection and demonstrate that a mutant
returning a different field would fail. -/

namespace LidoSRv3.Tests.WithdrawalQueueMappingKillLines

open LidoSRv3.Audit.Source.WithdrawalQueueMappingSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource

private def witnessRequestMap : MappingStorage :=
  { slotAt := fun n => if n = 5 then 42 else 0 }

private def witnessCheckpointMap : MappingStorage :=
  { slotAt := fun n => if n = 7 then 99 else 0 }

private def witnessWQ : WithdrawalQueueStorage :=
  { unfinalizedStETH := 200
    requestMapping := witnessRequestMap
    checkpointMapping := witnessCheckpointMap }

/-- **Kill-line: `readRequest` reads from the request mapping at
the requestId key.** -/
theorem readRequest_at_witness :
    readRequest witnessWQ 5 = 42 := rfl

/-- **Kill-line: `readCheckpoint` reads from the checkpoint mapping
at the hint key.** -/
theorem readCheckpoint_at_witness :
    readCheckpoint witnessWQ 7 = 99 := rfl

/-- **Kill-line: `unfinalizedStETHFromStorage` recovers the field
exactly.** -/
theorem unfinalizedStETHFromStorage_at_witness :
    unfinalizedStETHFromStorage witnessWQ = 200 := rfl

/-- **Kill-line: `readRequest` and `readCheckpoint` are on distinct
mappings (a mutant that swapped them would fail).** -/
theorem readRequest_readCheckpoint_distinct :
    readRequest witnessWQ 5 ≠ readCheckpoint witnessWQ 5 := by
  unfold readRequest readCheckpoint witnessWQ witnessRequestMap
    witnessCheckpointMap
  decide

/-- **Kill-line: unfinalizedStETHFromStorage = wqs.unfinalizedStETH
universally (rfl).** -/
theorem unfinalizedStETHFromStorage_rfl (wqs : WithdrawalQueueStorage) :
    unfinalizedStETHFromStorage wqs = wqs.unfinalizedStETH :=
  unfinalizedStETHFromStorage_eq wqs

#print axioms readRequest_at_witness
#print axioms readCheckpoint_at_witness
#print axioms unfinalizedStETHFromStorage_at_witness
#print axioms readRequest_readCheckpoint_distinct
#print axioms unfinalizedStETHFromStorage_rfl

end LidoSRv3.Tests.WithdrawalQueueMappingKillLines
