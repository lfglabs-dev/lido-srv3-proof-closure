import LidoSRv3.Audit.Source.SszWrapperIndex

/-! `fls` of GIndex.sol:96-109 (Solady LibBit) at core pin
17005714f151e5502c559932319a3f2f74ac2436, transcribed from `fun_fls` in the
inspected solc 0.8.25/viaIR/200/Cancun SszRootCallHarness runtime
(audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul:536-545).
The word operations are evaluated on natural numbers below 2^256; every
intermediate value stays below 2^256, so no wrap is dropped by the
transcription. The result is proved equal to the typed `SszWrapperIndex.fls`
(log2 with the zero sentinel 256) that `sourceConcat` already consumes. -/
namespace LidoSRv3.Audit.Source.SszSoladyFls

/-- Solady's selector constant and byte table, GIndex.sol:106-107. -/
def magic : Nat := 0x8421084210842108cc6318c6db6d54be
def table : Nat := 0x0706060506020504060203020504030106050205030304010505030400000000

/-- EVM `lt(a, b)` as a word. -/
def ltWord (a b : Nat) : Nat := if a < b then 1 else 0

/-- EVM `byte(i, w)`: the i-th most significant byte, zero beyond index 31. -/
def byteWord (i w : Nat) : Nat := if i < 32 then (w >>> ((31 - i) * 8)) &&& 0xff else 0

/-- IR 539: `or(shl(8, iszero(x)), shl(7, lt(0xff..ff, x)))` with the 128-bit mask. -/
def round1 (x : Nat) : Nat :=
  ((if x = 0 then 1 else 0) <<< 8) ||| (ltWord (2 ^ 128 - 1) x <<< 7)

/-- IR 540-543: `or(r, shl(k, lt(2^m - 1, shr(r, x))))`. -/
def refine (m k : Nat) (x r : Nat) : Nat := r ||| (ltWord (2 ^ m - 1) (x >>> r) <<< k)

/-- IR 544: `or(r, byte(and(0x1f, shr(shr(r, x), MAGIC)), TABLE))`. -/
def finish (x r : Nat) : Nat := r ||| byteWord (0x1f &&& (magic >>> (x >>> r))) table

/-- Literal `fun_fls`. -/
def sourceFls (x : Nat) : Nat :=
  let r := round1 x
  let r := refine 64 6 x r
  let r := refine 32 5 x r
  let r := refine 16 4 x r
  let r := refine 8 3 x r
  finish x r

/-- A shifted comparison against `2^m - 1` reads the log2 of the operand. -/
theorem lt_shift_iff (x r m : Nat) (hx : x ≠ 0) :
    (2 ^ m - 1 < x >>> r) ↔ m + r ≤ x.log2 := by
  rw [Nat.shiftRight_eq_div_pow, Nat.le_log2 hx, Nat.pow_add,
    ← Nat.le_div_iff_mul_le (Nat.two_pow_pos r)]
  have hp := Nat.two_pow_pos m
  omega

/-- Disjoint bits: OR is addition when the low `i` bits of `a` are clear. -/
theorem or_eq_add (a b i : Nat) (ha : a % 2 ^ i = 0) (hb : b < 2 ^ i) : a ||| b = a + b := by
  have hq : a = (a / 2 ^ i) <<< i := by
    rw [Nat.shiftLeft_eq, Nat.div_mul_cancel (Nat.dvd_of_mod_eq_zero ha)]
  rw [hq, ← Nat.shiftLeft_add_eq_or_of_lt hb]

theorem round1_eq (x : Nat) (hx : x ≠ 0) : round1 x = if 128 ≤ x.log2 then 128 else 0 := by
  have h := lt_shift_iff x 0 128 hx
  rw [Nat.shiftRight_zero, Nat.add_zero] at h
  unfold round1 ltWord
  rw [if_neg hx]
  by_cases hc : 128 ≤ x.log2
  · rw [if_pos hc, if_pos (h.mpr hc)]
    decide
  · rw [if_neg hc, if_neg (fun hlt => hc (h.mp hlt))]
    decide

theorem refine_eq (x r m k : Nat) (hx : x ≠ 0) (hm : m = 2 ^ k) (hr : r % (2 * m) = 0) :
    refine m k x r = r + if m + r ≤ x.log2 then m else 0 := by
  unfold refine ltWord
  by_cases hc : m + r ≤ x.log2
  · rw [if_pos ((lt_shift_iff x r m hx).mpr hc), if_pos hc, Nat.one_shiftLeft, ← hm]
    have hpow : 2 ^ (k + 1) = 2 * m := by rw [Nat.pow_succ, hm]; omega
    exact or_eq_add r m (k + 1) (by rw [hpow]; exact hr) (by rw [hpow]; have := Nat.two_pow_pos k; omega)
  · rw [if_neg (fun hlt => hc ((lt_shift_iff x r m hx).mp hlt)), if_neg hc, Nat.zero_shiftLeft,
      Nat.or_zero, Nat.add_zero]

/-- The five rounds clear the three low bits of log2. -/
theorem rounds_eq (x : Nat) (hx : x ≠ 0) (hL : x.log2 < 256) :
    refine 8 3 x (refine 16 4 x (refine 32 5 x (refine 64 6 x (round1 x)))) = x.log2 / 8 * 8 := by
  have e1 := round1_eq x hx
  generalize round1 x = r1 at e1 ⊢
  have m1 : r1 % 128 = 0 := by split at e1 <;> omega
  have e2 := refine_eq x r1 64 6 hx rfl m1
  generalize refine 64 6 x r1 = r2 at e2 ⊢
  have m2 : r2 % 64 = 0 := by split at e1 <;> split at e2 <;> omega
  have e3 := refine_eq x r2 32 5 hx rfl m2
  generalize refine 32 5 x r2 = r3 at e3 ⊢
  have m3 : r3 % 32 = 0 := by split at e1 <;> split at e2 <;> split at e3 <;> omega
  have e4 := refine_eq x r3 16 4 hx rfl m3
  generalize refine 16 4 x r3 = r4 at e4 ⊢
  have m4 : r4 % 16 = 0 := by split at e1 <;> split at e2 <;> split at e3 <;> split at e4 <;> omega
  have e5 := refine_eq x r4 8 3 hx rfl m4
  generalize refine 8 3 x r4 = r5 at e5 ⊢
  split at e1 <;> split at e2 <;> split at e3 <;> split at e4 <;> split at e5 <;> omega

/-- The byte table is the log2 of every nonzero byte value. Finite kernel check. -/
theorem table_lookup : ∀ y, y < 256 → y ≠ 0 →
    byteWord (0x1f &&& (magic >>> y)) table = y.log2 := by
  decide +kernel

theorem sourceFls_zero : sourceFls 0 = 256 := by decide +kernel

/-- Literal Solady `fls` equals the typed most-significant-bit index with the
zero sentinel, on the whole 256-bit input range. -/
theorem sourceFls_eq (x : Nat) (hx : x < 2 ^ 256) : sourceFls x = SszWrapperIndex.fls x := by
  unfold SszWrapperIndex.fls
  by_cases hz : x = 0
  · subst hz
    rw [if_pos rfl]
    exact sourceFls_zero
  · rw [if_neg hz]
    have hL : x.log2 < 256 := (Nat.log2_lt hz).mpr hx
    show finish x (refine 8 3 x (refine 16 4 x (refine 32 5 x (refine 64 6 x (round1 x))))) = x.log2
    rw [rounds_eq x hz hL]
    have hr5 : x.log2 / 8 * 8 ≤ x.log2 := Nat.div_mul_le_self x.log2 8
    have hlo : 2 ^ x.log2 ≤ x := Nat.log2_self_le hz
    have hhi : x < 2 ^ (x.log2 + 1) := Nat.lt_log2_self
    have hylo : 2 ^ (x.log2 - x.log2 / 8 * 8) ≤ x >>> (x.log2 / 8 * 8) := by
      rw [Nat.shiftRight_eq_div_pow, Nat.le_div_iff_mul_le (Nat.two_pow_pos _), ← Nat.pow_add,
        Nat.sub_add_cancel hr5]
      exact hlo
    have hyhi : x >>> (x.log2 / 8 * 8) < 2 ^ (x.log2 - x.log2 / 8 * 8 + 1) := by
      rw [Nat.shiftRight_eq_div_pow, Nat.div_lt_iff_lt_mul (Nat.two_pow_pos _), ← Nat.pow_add]
      have hsum : x.log2 - x.log2 / 8 * 8 + 1 + x.log2 / 8 * 8 = x.log2 + 1 := by omega
      rw [hsum]
      exact hhi
    have hy0 : x >>> (x.log2 / 8 * 8) ≠ 0 := by
      have := Nat.two_pow_pos (x.log2 - x.log2 / 8 * 8)
      omega
    have hylog : (x >>> (x.log2 / 8 * 8)).log2 = x.log2 - x.log2 / 8 * 8 :=
      (Nat.log2_eq_iff hy0).mpr ⟨hylo, hyhi⟩
    have hy256 : x >>> (x.log2 / 8 * 8) < 256 := by
      have h8 : x.log2 - x.log2 / 8 * 8 + 1 ≤ 8 := by omega
      exact lt_of_lt_of_le hyhi (Nat.pow_le_pow_right (by decide) h8)
    unfold finish
    rw [table_lookup _ hy256 hy0, hylog]
    rw [or_eq_add (x.log2 / 8 * 8) (x.log2 - x.log2 / 8 * 8) 3
      (by show x.log2 / 8 * 8 % 8 = 0; omega) (by show x.log2 - x.log2 / 8 * 8 < 8; omega)]
    omega

/-- Typed `fls` is bounded by its sentinel on word inputs. -/
theorem fls_le (x : Nat) (hx : x < 2 ^ 256) : SszWrapperIndex.fls x ≤ 256 := by
  unfold SszWrapperIndex.fls
  split
  · exact Nat.le_refl _
  · rename_i hz
    exact Nat.le_of_lt ((Nat.log2_lt hz).mpr hx)

#print axioms sourceFls_eq
#print axioms table_lookup
end LidoSRv3.Audit.Source.SszSoladyFls
