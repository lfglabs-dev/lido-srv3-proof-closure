import LidoSRv3.Audit.Verity.ReserveRelationalTx

/-!
Kill-lines pinning `Verity.ReserveRelationalTx` transaction-plane
`Status` enum, `Result`/`View` structures, and `observe` revert
projection. These pin the transaction observable surface that binds
the Verity `Contract.run` result to the abstract source view.
-/

namespace LidoSRv3.Tests.VerityReserveRelationalTxViewObserveKillLines

open LidoSRv3.Audit.Verity.ReserveRelationalTx

/-! ## `Status` two-arm enum distinctness. -/

theorem status_committed_ne_reverted :
    Status.committed ≠ Status.reverted := by decide

theorem status_decEq_committed_self :
    (decide (Status.committed = Status.committed)) = true := by decide

theorem status_decEq_reverted_self :
    (decide (Status.reverted = Status.reverted)) = true := by decide

/-! ## `Result` five-field structure. -/

private def r0 : Result :=
  { prefinalizedRanges := [(1, 2)]
    prefinalizedEth := 100
    sharesToBurn := 50
    finalizedLo := 3
    lockedEtherAfter := 1000 }

theorem result_prefinalizedRanges : r0.prefinalizedRanges = [(1, 2)] := rfl
theorem result_prefinalizedEth : r0.prefinalizedEth = 100 := rfl
theorem result_sharesToBurn : r0.sharesToBurn = 50 := rfl
theorem result_finalizedLo : r0.finalizedLo = 3 := rfl
theorem result_lockedEtherAfter : r0.lockedEtherAfter = 1000 := rfl

theorem result_decEq_self :
    (decide (r0 = r0)) = true := by decide

theorem result_decEq_neg :
    (decide (r0 = { r0 with prefinalizedEth := 99 })) = false := by decide

/-! ## `View` six-field structure. -/

theorem view_reverted_zero :
    (⟨.reverted, [], 0, 0, none, (0 : Verity.Uint256)⟩ : View).status = .reverted := rfl

/-! ## `observe` on revert yields the fixed all-zero view. -/

theorem observe_revert_yields_zero_view (reason : String)
    (state : Verity.ContractState) :
    observe (.revert reason state) =
      ⟨.reverted, [], 0, 0, none, (0 : Verity.Uint256)⟩ := rfl

/-! ## `writeRanges` empty base case. -/

theorem writeRanges_empty (index : Nat) (state : Verity.ContractState) :
    writeRanges index [] state = state := rfl

/-! ## `finalize` reverts on empty batch count. -/

theorem finalize_zero_count_reverts (discount : Bool)
    (state : Verity.ContractState) :
    finalize 0 discount false state = .revert "EmptyBatches" state := rfl

end LidoSRv3.Tests.VerityReserveRelationalTxViewObserveKillLines
