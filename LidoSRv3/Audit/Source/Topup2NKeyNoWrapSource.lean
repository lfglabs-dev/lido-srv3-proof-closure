import LidoSRv3.Audit.Source.Topup2Uint64BoundsSource
import LidoSRv3.Audit.Source.Topup2SumNoWrapSource

/-! # P-TOPUP-2 N-key aggregate no-wrap composition source model

**General rule (Thomas 2026-09-13, chantier 4bis composition):
under the pinned gateway-form premise (each per-key limit ≤
allocationCap, N ≤ maxValidatorsPerTopUp ≤ uint64Max), the aggregate
sum of N per-key limits is ≤ N * allocationCap ≤ aggregateCap
which is strictly less than uint256Modulus by Topup2SumNoWrapSource.

This composition gives the final "sum is exact, no wrap" theorem
combining the per-allocation cap and the aggregate cap.**

**Status:** first real derivation of the chantier-4bis final
conclusion. -/

namespace LidoSRv3.Audit.Source.Topup2NKeyNoWrapSource

open LidoSRv3.Audit.Source.Topup2Uint64BoundsSource
open LidoSRv3.Audit.Source.Topup2SumNoWrapSource
open LidoSRv3.Audit.Source.SolidityUint256WrapSource

/-- Helper: sum of a list bounded elementwise by C is ≤ (length) * C. -/
theorem sum_le_length_mul
    {C : Nat} {L : List Nat}
    (hPerKey : ∀ x ∈ L, x ≤ C) :
    L.sum ≤ L.length * C := by
  induction L with
  | nil => simp
  | cons head tail ih =>
    have hHead : head ≤ C :=
      hPerKey head (List.mem_cons_self)
    have hTailBound : ∀ x ∈ tail, x ≤ C := fun x hx =>
      hPerKey x (List.mem_cons_of_mem head hx)
    have hTailSum : tail.sum ≤ tail.length * C := ih hTailBound
    have hHeadSum : (head :: tail).sum = head + tail.sum := List.sum_cons
    have hHeadLen : (head :: tail).length = tail.length + 1 := List.length_cons
    have hExpand : (tail.length + 1) * C = tail.length * C + C := by
      rw [Nat.add_mul, Nat.one_mul]
    rw [hHeadSum, hHeadLen, hExpand]
    have := Nat.add_le_add hHead hTailSum
    omega

/-- Aggregate sum bound: for any N per-key limits each ≤
allocationCap, and N ≤ uint64Max, the sum is ≤ N * allocationCap ≤
aggregateCap. -/
theorem nkey_sum_le_aggregateCap
    {N : Nat} {perKey : List Nat}
    (hN : perKey.length = N)
    (hNBounded : N ≤ uint64Max)
    (hPerKey : ∀ x ∈ perKey, x ≤ allocationCap) :
    perKey.sum ≤ aggregateCap := by
  have hSumLe : perKey.sum ≤ perKey.length * allocationCap :=
    sum_le_length_mul hPerKey
  have hAggEq : aggregateCap = uint64Max * allocationCap := by
    unfold aggregateCap allocationCap
    rw [Nat.mul_assoc]
  have hAgg : perKey.length * allocationCap ≤ aggregateCap := by
    rw [hN, hAggEq]
    exact Nat.mul_le_mul_right allocationCap hNBounded
  omega

/-- Final chantier-4bis conclusion: under gateway-form limits, the
aggregate sum is strictly less than uint256Modulus, so no wrap
occurs. Real derivation. -/
theorem nkey_sum_lt_uint256Modulus
    {N : Nat} {perKey : List Nat}
    (hN : perKey.length = N)
    (hNBounded : N ≤ uint64Max)
    (hPerKey : ∀ x ∈ perKey, x ≤ allocationCap) :
    perKey.sum < uint256Modulus := by
  have h1 : perKey.sum ≤ aggregateCap :=
    nkey_sum_le_aggregateCap hN hNBounded hPerKey
  have h2 : aggregateCap < uint256Modulus :=
    aggregateCap_lt_uint256Modulus
  omega

end LidoSRv3.Audit.Source.Topup2NKeyNoWrapSource
