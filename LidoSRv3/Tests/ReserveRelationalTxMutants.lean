import LidoSRv3.Audit.Verity.ReserveRelationalTx

/-!
# P-RESERVE-RELATIONAL faithful-plane fail-closed vectors

These vectors keep the composed theorem non-vacuous.  `decodes_concrete_world`
exhibits a contract world that really satisfies the `Decodes` hypothesis, so
`verity_tx_simulates_pinned_source` applies to executed storage and memory
rather than to an empty hypothesis.
-/

namespace LidoSRv3.Tests.ReserveRelationalTxMutants

open Verity
open LidoSRv3.Audit.ReserveRelational
open LidoSRv3.Audit.Verity.ReserveRelationalTx

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def queue : Queue := ⟨9, [⟨11, 30, 20, 12⟩, ⟨14, 50, 35, 25⟩], false⟩
private def report : Report := ⟨[11, 14], false⟩
private def inputs : Inputs := ⟨report, queue, 100⟩
private def lowReserve : State := ⟨5, 7⟩
private def highReserve : State := ⟨90, 7⟩

private def worldFor (i : Inputs) (s : State) : ContractState := stateFor i s defaultState

private def runView (i : Inputs) (s : State) : View :=
  observe ((finalize i.report.batchEnds.length i.report.useDiscount).run (worldFor i s))

/-- Non-vacuity: this concrete storage/memory world decodes to exactly the
abstract inputs and pre-state, so the composed theorem has a real witness. -/
example : Decodes (worldFor inputs lowReserve) inputs lowReserve := by rfl

/-- Happy path: two batches chain their prefinalized ranges, the ETH and share
columns sum, and the finalized upper endpoint is read back from storage. -/
example : runView inputs lowReserve =
    ⟨.committed, [(10, 11), (12, 14)], 80, 37, some (10, word 14), word 87⟩ := by rfl

/-- The composed theorem agrees with the independently stated interpreter on
this world, executed rather than assumed. -/
example : runView inputs lowReserve = sourceView inputs lowReserve := by rfl

/-- Off-by-one prefinalized chaining is rejected: the second range starts at
12, not 11. -/
example : runView inputs lowReserve ≠
    ⟨.committed, [(10, 11), (11, 14)], 80, 37, some (10, word 14), word 87⟩ := by decide

/-- The discount column is a real alternative, not dead storage. -/
example : runView { inputs with report := ⟨[11, 14], true⟩ } lowReserve =
    ⟨.committed, [(10, 11), (12, 14)], 55, 37, some (10, word 14), word 62⟩ := by rfl

/-- Reserve non-interference, executed: two worlds differing only in the
`depositsReserve` slot produce identical observables. -/
example : runView inputs lowReserve = runView inputs highReserve := by rfl

/-- Forbidden reserve-to-range dependency at the transaction plane: a mutant
that lets the reserve slot reach the finalized range is distinguished by the
same two worlds the certified transaction cannot distinguish. -/
private def reserveToRangeMutant (i : Inputs) (s : State) : View :=
  let world := worldFor i s
  let view := observe ((finalize i.report.batchEnds.length i.report.useDiscount).run world)
  { view with finalizedRange :=
      view.finalizedRange.map fun range => ((world.readSlot depositsReserveSlot).val, range.2) }

/-- Forbidden reserve-to-shares dependency at the transaction plane. -/
private def reserveToSharesMutant (i : Inputs) (s : State) : View :=
  let world := worldFor i s
  let view := observe ((finalize i.report.batchEnds.length i.report.useDiscount).run world)
  { view with sharesToBurn := (world.readSlot depositsReserveSlot).val }

example : reserveToRangeMutant inputs lowReserve ≠
    reserveToRangeMutant inputs highReserve := by decide

example : reserveToSharesMutant inputs lowReserve ≠
    reserveToSharesMutant inputs highReserve := by decide

/-- Forbidden report omission: finalizing the whole queue instead of the
reported batch ends is observably different. -/
example : runView { inputs with report := ⟨[11], false⟩ } lowReserve ≠
    runView { inputs with report := ⟨[11, 14], false⟩ } lowReserve := by decide

/-- Forbidden queue omission: an unknown batch end is not silently skipped,
it fails closed. -/
example : runView { inputs with report := ⟨[11, 13], false⟩ } lowReserve =
    ⟨.reverted, [], 0, 0, none, word 0⟩ := by rfl

/-- Forbidden buffer omission: a lock larger than the available buffer must
revert rather than commit. -/
example : runView { inputs with buffer := 40 } lowReserve =
    ⟨.reverted, [], 0, 0, none, word 0⟩ := by rfl

example : runView { inputs with buffer := 40 } lowReserve ≠
    runView { inputs with buffer := 1000 } lowReserve := by decide

/-- A paused queue and an empty report both fail closed. -/
example : runView { inputs with queue := { queue with paused := true } } lowReserve =
    ⟨.reverted, [], 0, 0, none, word 0⟩ := by rfl

example : runView { inputs with report := ⟨[], false⟩ } lowReserve =
    ⟨.reverted, [], 0, 0, none, word 0⟩ := by rfl

/-- Two-batch chaining across calls: finalizing `[11]` advances the stored
last finalized request id and locked ETH, and the next call's prefinalized
range starts from the new cursor. -/
example : runView { inputs with report := ⟨[11], false⟩ } lowReserve =
    ⟨.committed, [(10, 11)], 30, 12, some (10, word 11), word 37⟩ := by rfl

example : runView ⟨⟨[14], false⟩, { queue with lastFinalizedRequestId := 11 }, 100⟩ ⟨5, 37⟩ =
    ⟨.committed, [(12, 14)], 50, 25, some (12, word 14), word 87⟩ := by rfl

/-- Failure injected after the batch journal and both finalization writes is
rolled back by `Contract.run`, not merely hidden by the observation. -/
example :
    (finalize 2 false true).run (worldFor inputs lowReserve) =
      .revert "INJECTED_AFTER_WRITES" (worldFor inputs lowReserve) := by rfl

/-! ## Checked locked-ETH accumulator

`lockedEtherAmount += prefinalized` is a Solidity 0.8 checked addition.  These
vectors pin that the transaction reverts on overflow instead of committing a
wrapped word, and that the boundary is inclusive. -/

private def wrapState : State := ⟨5, Verity.Core.MAX_UINT256⟩

/-- An accumulator that would leave one word fails closed. -/
example : runView inputs wrapState = ⟨.reverted, [], 0, 0, none, word 0⟩ := by rfl

/-- The revert is the checked-arithmetic one and restores the exact snapshot;
nothing is written. -/
example :
    (finalize 2 false false).run (worldFor inputs wrapState) =
      .revert "LOCKED_ETH_OVERFLOW" (worldFor inputs wrapState) := by rfl

/-- The rejection is a real wrap, not an unreachable guard: an unchecked
accumulator would have committed 79 on this world. -/
example : (word (Verity.Core.MAX_UINT256 + 80)).val = 79 := by decide

/-- A wrapping mutant that stores the truncated word instead of reverting is
observably different from the certified transaction. -/
example : runView inputs wrapState ≠
    ⟨.committed, [(10, 11), (12, 14)], 80, 37, some (10, word 14), word 79⟩ := by decide

/-- The bound is inclusive: landing exactly on `MAX_UINT256` still commits. -/
example : runView inputs ⟨5, Verity.Core.MAX_UINT256 - 80⟩ =
    ⟨.committed, [(10, 11), (12, 14)], 80, 37, some (10, word 14),
      word Verity.Core.MAX_UINT256⟩ := by rfl

end LidoSRv3.Tests.ReserveRelationalTxMutants
