import LidoSRv3.Audit.Source.NodeOperatorsRegistry.AllocatedKeys

namespace LidoSRv3.Tests.NodeOperatorsRegistrySummary
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.NodeOperatorsRegistry

private instance [DecidableEq ε] [DecidableEq α] : DecidableEq (Except ε α) :=
  fun a b => match a, b with
  | .ok a, .ok b => decidable_of_iff (a = b) (by simp)
  | .error a, .error b => decidable_of_iff (a = b) (by simp)
  | .ok _, .error _ => isFalse (by intro h; cases h)
  | .error _, .ok _ => isFalse (by intro h; cases h)

/-- Offsets 0/1/3 contain maximum/exited/deposited, respectively. -/
theorem summary_field_order :
    getStakingModuleSummary (word (8 + 2 * 2^64 + 5 * 2^192)) =
      .ok { exited := word 2, deposited := word 5, depositable := word 3 } := by
  decide +kernel

/-- Saturating subtraction would incorrectly return success for this word. -/
theorem depositable_underflow :
    summaryReply (word (4 + 5 * 2^192)) = .reverted mathSubUnderflow := by
  decide +kernel

/-- Independent ABI fixture: selector, offset 32, length 18, ASCII reason,
and fourteen zero padding bytes. -/
theorem safeMath_error_bytes :
    mathSubUnderflow.map Fin.val =
      [8, 195, 121, 160] ++ List.replicate 31 0 ++ [32] ++
      List.replicate 31 0 ++ [18] ++
      [77, 65, 84, 72, 95, 83, 85, 66, 95, 85, 78, 68, 69, 82, 70, 76, 79, 87] ++
      List.replicate 14 0 := by
  decide +kernel

/-- The getter does not validate exited <= deposited. Width alone cannot close
the router's active-count subtraction obligation. -/
theorem getter_does_not_establish_exit_consistency :
    getStakingModuleSummary (word (6 * 2^64)) =
      .ok { exited := word 6, deposited := word 0, depositable := word 0 } ∧
    checkedSub 0 (max 6 0) = .error (.panic (word 0x11)) := by
  decide +kernel

/-- Even a locally consistent NOR summary cannot certify a larger accounting
exit value stored by the router. -/
theorem accounting_exit_still_can_underflow :
    getStakingModuleSummary (word (5 + 2 * 2^64 + 5 * 2^192)) =
      .ok { exited := word 2, deposited := word 5, depositable := word 0 } ∧
    checkedSub 5 (max 2 6) = .error (.panic (word 0x11)) := by
  decide +kernel

def state (operator summary : Word) : State :=
  { operators := fun _ => { signingKeysStats := operator, targetValidatorsStats := word 0 }
    summarySigningKeysStats := summary }

/-- The equal-value path returns before the deposited-count guard. -/
theorem unchanged_invalid_exit_returns :
    (executeUpdateExited (state (word (6 * 2^64)) (word 0)) (word 0) (word 6) false).result =
      .ok () := by
  decide +kernel

/-- Local admission succeeds, but the aggregate exited field overflows after
the operator update. The transaction must discard its event and writes. -/
theorem aggregate_overflow_rolls_back :
    let before := state (word (1 + 2^192)) (word ((2^64-1)*2^64))
    let result := executeUpdateExited before (word 0) (word 1) false
    result.result = .error (LidoSRv3.Audit.Source.Packed64x4.errorString "PACKED_OVERFLOW") ∧
      result.events = [] ∧
      (result.state.operators (word 0)).signingKeysStats = (before.operators (word 0)).signingKeysStats := by
  decide +kernel

def consistentState : State :=
  { operators := fun _ =>
      { signingKeysStats := word (5 + 2 * 2^64 + 5 * 2^192)
        targetValidatorsStats := word (5 * 2^128) }
    summarySigningKeysStats := word (5 + 2 * 2^64 + 5 * 2^192) }

theorem initial_accounting : AccountingInvariant consistentState [word 0] := by
  constructor
  · simp
  · decide +kernel
  · decide +kernel
  · intro id member
    simp only [List.mem_singleton] at member
    subst id
    decide +kernel

/-- Increasing and decreasing exits both update the aggregate exactly. The
target maximum already matches, so the unrelated maximum field is unchanged. -/
theorem exit_update_directions :
    let increased := executeUpdateExited consistentState (word 0) (word 3) false
    let decreased := executeUpdateExited consistentState (word 0) (word 1) true
    increased.result = .ok () ∧ decreased.result = .ok () ∧
      (packedGet increased.state.summarySigningKeysStats 1).val = 3 ∧
      (packedGet decreased.state.summarySigningKeysStats 1).val = 1 ∧
      (packedGet increased.state.summarySigningKeysStats 0).val = 5 ∧
      increased.events = [(word 0, word 3)] ∧ decreased.events = [(word 0, word 1)] := by
  decide +kernel

/-- Omitting the aggregate write while changing the operator is observable
by the invariant, even though each individual count remains in range. -/
theorem missing_aggregate_write_refutes_accounting :
    let broken := saveOperator consistentState (word 0)
      { consistentState.operators (word 0) with
        signingKeysStats := word (5 + 3 * 2^64 + 5 * 2^192) }
    ¬ AccountingInvariant broken [word 0] := by
  dsimp only
  intro invariant
  have impossible :
      (packedGet consistentState.summarySigningKeysStats 1).val ≠
        counterSum (saveOperator consistentState (word 0)
          { consistentState.operators (word 0) with
            signingKeysStats := word (5 + 3 * 2^64 + 5 * 2^192) }) 1 [word 0] := by
    decide +kernel
  exact impossible invariant.exited_sum

/-- Invalid incoming accounting permits the wrap-to-equal early continuation.
Replacing raw addition with checked addition would change this outcome. -/
theorem allocated_wrap_to_equal_continues :
    allocatedKeyPrefix (word (2 * 2^64 + 2^192)) (word (2^256-1)) =
      .ok .unchanged := by
  decide +kernel

/-- With exited <= deposited, the analogous wrap is rejected by INVALID. -/
theorem allocated_wrap_asserts :
    allocatedKeyPrefix (word (2 * 2^64 + 2 * 2^192)) (word (2^256-1)) =
      .error .invalid := by
  decide +kernel

/-- A real increase starts at the old deposited count and loads the delta. -/
theorem allocated_load_delta_fixture :
    allocatedKeyPrefix (word (2 * 2^64 + 5 * 2^192)) (word 7) =
      .ok (.load (word 5) (word 4)) := by
  decide +kernel

end LidoSRv3.Tests.NodeOperatorsRegistrySummary
