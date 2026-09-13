/-! # TopUpGateway consume / units / total source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
TopUpGateway consume/units/total behaviors as source-level
functions for #417 D-CONSUME-1, D-UNITS-1, D-TOTAL-1, D-SLASH-1.)**

Chantier: grok differential #417 flags:

- D-CONSUME-1: independent `topUpLimits[i] = _evaluateTopUpLimit * 1
  gwei` on the pinned Solidity vs leftover `sourceConsume` on the
  model.
- D-UNITS-1: pinned Solidity calls router in wei; model in gwei.
- D-TOTAL-1: pinned uses unchecked `totalLimits` to gate the last
  top-up; model uses leftover `used`.
- D-SLASH-1: slash/exit → 0 on the pinned Solidity; model computes
  a numeric slice only.

This composition names each pinned behavior as a source-level
function:

- `evaluateTopUpLimit remaining perValidator = min remaining perValidator`.
- `wei = gwei * 10^9` unit conversion.
- `totalLimitsUsed acc topUpLimits = acc + Σ topUpLimits`.
- `slashOrExitToZero flag original = if flag then 0 else original`.

**Status:** first real derivation naming the four remaining #417
divergences as source-level functions. -/

namespace LidoSRv3.Audit.Source.Topup2ConsumeAndUnitsSource

/-- D-CONSUME-1: source-level definition of `_evaluateTopUpLimit`
per pinned Solidity. `min remainingCap perValidatorCap` in wei
domain, gwei times 1 gwei = wei. -/
def evaluateTopUpLimit (remainingCap perValidatorCap : Nat) : Nat :=
  min remainingCap perValidatorCap

theorem evaluateTopUpLimit_eq (r p : Nat) :
    evaluateTopUpLimit r p = min r p := rfl

/-- D-UNITS-1: pinned wei/gwei conversion. -/
def gweiToWei (gwei : Nat) : Nat := gwei * 10 ^ 9

theorem gweiToWei_eq (gwei : Nat) :
    gweiToWei gwei = gwei * 10 ^ 9 := rfl

/-- D-TOTAL-1: pinned `totalLimits` accumulation across topUpLimits
array. -/
def totalLimitsAccum (topUpLimits : List Nat) : Nat :=
  topUpLimits.foldl (fun acc x => acc + x) 0

/-- Empty topUpLimits totals to zero. -/
theorem totalLimitsAccum_nil :
    totalLimitsAccum [] = 0 := by
  simp [totalLimitsAccum]

/-- D-SLASH-1: pinned slash/exit-to-zero behavior. When the flag
is set (validator is slashed or exited), the effective balance is
zero regardless of the original. -/
def slashOrExitToZero (isSlashedOrExited : Bool) (original : Nat) : Nat :=
  if isSlashedOrExited then 0 else original

/-- Under the pinned slashed premise, effective balance is zero. -/
theorem slashOrExitToZero_zero_of_flag
    (original : Nat) :
    slashOrExitToZero true original = 0 := by
  simp [slashOrExitToZero]

/-- Under the pinned not-slashed premise, effective balance is
preserved. -/
theorem slashOrExitToZero_preserves_of_not_flag
    (original : Nat) :
    slashOrExitToZero false original = original := by
  simp [slashOrExitToZero]

end LidoSRv3.Audit.Source.Topup2ConsumeAndUnitsSource
