import LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded

/-! # Kill-lines for `PAlloc1TargetMultBounded`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines refuting
weakenings of `PinnedStakingModuleTypeBounds`.**

`target_multiplication_under_pinned_type_bounds` (registered in
`LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded`) derives
`shareLimit * totalValidators ≤ MAX_UINT256` from two premises on the
pinned StakingModule struct type widths:

- `shareLimit_uint16 : ∀ m ∈ modules, m.shareLimit ≤ uint16Max`
- `totalValidators_uint64 : totalValidators ≤ uint64Max`

If EITHER premise were dropped, the arithmetic bound could fail.  This
module exhibits concrete counterexamples for both weakened premises,
demonstrating that both bounds are load-bearing. -/

namespace LidoSRv3.Tests.PAlloc1TargetMultKillLines

open LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded

/-- **Kill-line: dropping `shareLimit_uint16` breaks the bound.**

Without the uint16 cap on `shareLimit`, a `shareLimit = 2^200` and
`totalValidators = uint64Max` witness produces
`2^200 * (2^64 - 1) ≥ 2^264 - 2^200 > 2^256 - 1 = MAX_UINT256`.

The kill-line negates a universal quantifier that would replace the
honest premise with only the `totalValidators_uint64` bound. -/
theorem target_multiplication_needs_share_limit_bound :
    ¬ (∀ (shareLimit totalValidators : Nat),
        totalValidators ≤ uint64Max →
        shareLimit * totalValidators ≤ Verity.Core.MAX_UINT256) := by
  intro h
  have hInst := h (2 ^ 200) uint64Max (Nat.le_refl _)
  -- Instantiated conclusion: 2^200 * (2^64 - 1) ≤ MAX_UINT256
  -- which is false by decidable computation
  have hFail : ¬ (2 ^ 200) * uint64Max ≤ Verity.Core.MAX_UINT256 := by
    unfold uint64Max Verity.Core.MAX_UINT256
    decide
  exact hFail hInst

/-- **Kill-line: dropping `totalValidators_uint64` breaks the bound.**

Without the uint64 cap on `totalValidators`, a `shareLimit = uint16Max`
and `totalValidators = 2^200` witness produces `(2^16 - 1) * 2^200 ≥
2^216 - 2^200 > 2^256 - 1 = MAX_UINT256` — well, actually
`uint16Max * 2^200 = 65535 * 2^200 < 2^216 << 2^256`.  A larger
`totalValidators = 2^250` gives `65535 * 2^250 > 2^266 > 2^256`.

The kill-line negates a universal quantifier that would replace the
honest premise with only the `shareLimit_uint16` bound. -/
theorem target_multiplication_needs_total_validators_bound :
    ¬ (∀ (shareLimit totalValidators : Nat),
        shareLimit ≤ uint16Max →
        shareLimit * totalValidators ≤ Verity.Core.MAX_UINT256) := by
  intro h
  have hInst := h uint16Max (2 ^ 250) (Nat.le_refl _)
  -- Instantiated conclusion: (2^16 - 1) * 2^250 ≤ MAX_UINT256
  -- which is false by decidable computation
  have hFail : ¬ uint16Max * (2 ^ 250) ≤ Verity.Core.MAX_UINT256 := by
    unfold uint16Max Verity.Core.MAX_UINT256
    decide
  exact hFail hInst

/-- **Kill-line: dropping BOTH premises breaks the bound trivially.**

Without either type-width cap, the naive multiplication of two arbitrary
Nats obviously escapes MAX_UINT256. -/
theorem target_multiplication_needs_both_premises :
    ¬ (∀ (shareLimit totalValidators : Nat),
        shareLimit * totalValidators ≤ Verity.Core.MAX_UINT256) := by
  intro h
  have hInst := h (2 ^ 300) 1
  simp at hInst
  have hFail : ¬ (2 ^ 300 : Nat) ≤ Verity.Core.MAX_UINT256 := by
    unfold Verity.Core.MAX_UINT256
    decide
  exact hFail hInst

#print axioms target_multiplication_needs_share_limit_bound
#print axioms target_multiplication_needs_total_validators_bound
#print axioms target_multiplication_needs_both_premises

end LidoSRv3.Tests.PAlloc1TargetMultKillLines
