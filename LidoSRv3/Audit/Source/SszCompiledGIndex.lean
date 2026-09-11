import LidoSRv3.Audit.Source.SszSoladyFls

/-! Compiled generalized-index prefix of `_verifyValidator` line 54 at core pin
17005714f151e5502c559932319a3f2f74ac2436: `_getValidatorGI` (lines 97-100, with
`GIndex.shr`/`pack`, GIndex.sol:22-29,52-61) and `concat(GI_STATE_ROOT, ·)`
(GIndex.sol:76-89), transcribed from the inspected SszRootCallHarness runtime IR
(audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul:168-233 and the
helpers `checked_add_uint256`, `fun_pack`, `fun_fls`). Immutables are the
constructor's `pack` words. Every word operation is evaluated on naturals below
2^256 with the wrap of `add` retained through `checked_add_uint256`'s guard.
The successful compiled value is proved to be the packed word of the existing
typed `sourceWrapper` result, so the proof loop's `shr(8, ·)` reads that index. -/
namespace LidoSRv3.Audit.Source.SszCompiledGIndex
open SszWrapperIndex SszSoladyFls

inductive Error where
  | panic11 | panic12 | indexOutOfRange
  deriving DecidableEq, Repr

def word : Nat := 2 ^ 256
def mask64 : Nat := 2 ^ 64 - 1
def maxUint248 : Nat := 2 ^ 248 - 1

/-- IR 496-506 `checked_add_uint256`: wrapping sum, then `gt(x, sum)` panics 0x11. -/
def checkedAdd (x y : Nat) : Except Error Nat :=
  let sum := (x + y) % word
  if x > sum then .error .panic11 else .ok sum

/-- IR 547-562 `fun_pack` (GIndex.sol:22-29): uint248 guard, `or(shl(8, gI), and(p, 0xff))`. -/
def pack (gI p : Nat) : Except Error Nat :=
  if gI > maxUint248 then .error .indexOutOfRange
  else .ok (((gI <<< 8) % word) ||| (p &&& 0xff))

/-- IR 168-203: fork selection by `lt(and(slot, mask), and(PIVOT, mask))`, then the
inlined `shr`: `index`, `pow`, `width = shl(pow, 1)` with its zero guard (panic 0x12),
`mod`, checked `(i % w) + n`, range guard, checked `i + n`, `pack`. -/
def validatorGi (previous current pivot slot n : Nat) : Except Error Nat := do
  let base := if slot &&& mask64 < pivot &&& mask64 then previous else current
  let i := base >>> 8
  let p := base &&& 0xff
  let w := (1 <<< p) % word
  if w = 0 then throw .panic12
  let shifted ← checkedAdd (i % w) n
  if ¬ shifted < w then throw .indexOutOfRange
  let next ← checkedAdd i n
  pack next p

/-- IR 205-233: `concat(GI_STATE_ROOT, var)` with both `fls` calls, the checked
`lhsMSbIndex + 1 + rhsMSbIndex`, the 248 guard and the final `pack`. -/
def concat (stateRoot var : Nat) : Except Error Nat := do
  let l := stateRoot >>> 8
  let r := var >>> 8
  let fl := sourceFls l
  let fr := sourceFls r
  let sum ← checkedAdd fl 1
  let depth ← checkedAdd sum fr
  if depth > 248 then throw .indexOutOfRange
  pack (((l <<< fr) % word) ||| (r ^^^ ((1 <<< fr) % word))) (var &&& 0xff)

/-- The four immutable words read by the runtime (`loadimmutable` 982/991/994/996). -/
structure Words where
  stateRoot : Nat
  previous : Nat
  current : Nat
  pivot : Nat

def wrapper (w : Words) (slot n : Nat) : Except Error Nat := do
  let var ← validatorGi w.previous w.current w.pivot slot n
  concat w.stateRoot var

/-- The constructor's `pack` output for a typed packed index: `(gI << 8) | p`. -/
def packWord (g : PackedIndex) : Nat := g.index.val * 256 + g.power.val

/-- Immutable words of a typed configuration (IR 9-17 at construction). -/
def cfgWords (cfg : Configuration) : Words :=
  ⟨packWord stateRootIndex, packWord cfg.previous, packWord cfg.current, cfg.pivotSlot.val⟩

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error e => cases h
  | ok x => exact ⟨x, rfl, h⟩

theorem checkedAdd_success (x y s : Nat) (hx : x < word) (hy : y < word)
    (h : checkedAdd x y = .ok s) : s = x + y ∧ x + y < word := by
  unfold checkedAdd at h
  dsimp only at h
  split at h
  · cases h
  · rename_i hle
    cases h
    unfold word at *
    omega

theorem pack_success (gI p raw : Nat) (hp : p < 256) (h : pack gI p = .ok raw) :
    gI < 2 ^ 248 ∧ raw = gI * 256 + p := by
  unfold pack at h
  split at h
  · cases h
  · rename_i hfit
    cases h
    unfold maxUint248 at hfit
    have hg : gI < 2 ^ 248 := by omega
    have hshift : (gI <<< 8) % word = gI * 256 := by
      rw [Nat.shiftLeft_eq]
      show gI * 256 % word = gI * 256
      apply Nat.mod_eq_of_lt
      unfold word
      omega
    have hand : p &&& 0xff = p := by
      show p &&& (2 ^ 8 - 1) = p
      rw [Nat.and_two_pow_sub_one_eq_mod]
      exact Nat.mod_eq_of_lt hp
    refine ⟨hg, ?_⟩
    rw [hshift, hand]
    exact or_eq_add (gI * 256) p 8 (by show gI * 256 % 256 = 0; omega) hp

theorem packWord_lt (g : PackedIndex) : packWord g < 2 ^ 256 := by
  unfold packWord
  have hi := g.index.isLt
  have hp := g.power.isLt
  unfold indexModulus at hi
  omega

theorem packWord_index (g : PackedIndex) : packWord g >>> 8 = g.index.val := by
  rw [Nat.shiftRight_eq_div_pow]
  show (g.index.val * 256 + g.power.val) / 256 = g.index.val
  have := g.power.isLt
  omega

theorem packWord_power (g : PackedIndex) : packWord g &&& 0xff = g.power.val := by
  show packWord g &&& (2 ^ 8 - 1) = g.power.val
  rw [Nat.and_two_pow_sub_one_eq_mod]
  show (g.index.val * 256 + g.power.val) % 256 = g.power.val
  have := g.power.isLt
  omega

theorem mask64_small (v : Nat) (hv : v < 2 ^ 64) : v &&& mask64 = v := by
  show v &&& (2 ^ 64 - 1) = v
  rw [Nat.and_two_pow_sub_one_eq_mod]
  exact Nat.mod_eq_of_lt hv

theorem width_pow (p : Nat) (hp : p < 256) : (1 <<< p) % word = 2 ^ p := by
  rw [Nat.one_shiftLeft]
  apply Nat.mod_eq_of_lt
  unfold word
  exact Nat.pow_lt_pow_right (by decide) hp

/-- Compiled `_getValidatorGI` success is the typed checked neighbor of the
selected fork base, and its word is that neighbor's `pack`. -/
theorem validatorGi_success (cfg : Configuration) (slot : Fin (2 ^ 64))
    (n : Fin wordModulus) (var : Nat)
    (h : validatorGi (packWord cfg.previous) (packWord cfg.current) cfg.pivotSlot.val
      slot.val n.val = .ok var) :
    ∃ out, sourceNeighbor (selected cfg slot) n = .ok out ∧ var = packWord out := by
  have hbase : (if slot.val &&& mask64 < cfg.pivotSlot.val &&& mask64
      then packWord cfg.previous else packWord cfg.current) = packWord (selected cfg slot) := by
    rw [mask64_small _ slot.isLt, mask64_small _ cfg.pivotSlot.isLt]
    by_cases hc : slot.val < cfg.pivotSlot.val <;> simp [selected, hc]
  unfold validatorGi at h
  rw [hbase] at h
  dsimp only at h
  generalize hg : selected cfg slot = g at h ⊢
  rw [packWord_index, packWord_power, width_pow _ g.power.isLt] at h
  have hw0 : ¬ (2 ^ g.power.val = 0) := Nat.ne_of_gt (Nat.two_pow_pos _)
  rw [if_neg hw0] at h
  simp only [pure_bind] at h
  have hi : g.index.val < word := by
    have := g.index.isLt
    unfold indexModulus at this
    unfold word
    omega
  have hn : n.val < word := n.isLt
  have hmod : g.index.val % 2 ^ g.power.val < word :=
    lt_of_le_of_lt (Nat.mod_le _ _) hi
  obtain ⟨shifted, hshifted, h⟩ := bind_success h
  obtain ⟨hs, hsw⟩ := checkedAdd_success _ _ _ hmod hn hshifted
  subst hs
  split at h
  · cases h
  · rename_i hlt
    obtain ⟨next, hnext, h⟩ := bind_success h
    obtain ⟨hnx, hnw⟩ := checkedAdd_success _ _ _ hi hn hnext
    subst hnx
    obtain ⟨hfit, hraw⟩ := pack_success _ _ _ g.power.isLt h
    have hfit' : g.index.val + n.val < indexModulus := by unfold indexModulus; exact hfit
    refine ⟨⟨⟨g.index.val + n.val, hfit'⟩, g.power⟩, ?_, ?_⟩
    · unfold sourceNeighbor
      dsimp only
      unfold word at hsw hnw
      unfold wordModulus
      have c1 : ¬ (g.index.val % 2 ^ g.power.val + n.val ≥ 2 ^ 256) := by omega
      have c2 : ¬ (g.index.val % 2 ^ g.power.val + n.val ≥ 2 ^ g.power.val) := by omega
      have c3 : ¬ (g.index.val + n.val ≥ 2 ^ 256) := by omega
      rw [if_neg c1, if_neg c2, if_neg c3, dif_pos hfit']
      try rfl
    · rw [hraw]
      rfl

/-- Compiled `concat(GI_STATE_ROOT, ·)` success is the typed `sourceConcat` of the
header state-root index with the packed operand, and yields its `pack`. -/
theorem concat_success (right : PackedIndex) (raw : Nat)
    (h : concat (packWord stateRootIndex) (packWord right) = .ok raw) :
    ∃ out, sourceConcat stateRootIndex right = .ok out ∧ raw = packWord out := by
  unfold concat at h
  dsimp only at h
  rw [packWord_index, packWord_index, packWord_power,
    sourceFls_eq _ (lt_trans stateRootIndex.index.isLt (by decide)),
    sourceFls_eq _ (lt_trans right.index.isLt (by decide))] at h
  have hl : fls stateRootIndex.index.val < word := by
    unfold word
    exact lt_of_le_of_lt (fls_le _ (lt_trans stateRootIndex.index.isLt (by decide))) (by decide)
  have hr : fls right.index.val < word := by
    unfold word
    exact lt_of_le_of_lt (fls_le _ (lt_trans right.index.isLt (by decide))) (by decide)
  obtain ⟨sum, hsum, h⟩ := bind_success h
  obtain ⟨hs, hsw⟩ := checkedAdd_success _ _ _ hl (by unfold word; decide) hsum
  subst hs
  obtain ⟨depth, hdepth, h⟩ := bind_success h
  obtain ⟨hd, hdw⟩ := checkedAdd_success _ _ _ hsw hr hdepth
  subst hd
  split at h
  · cases h
  · rename_i hguard
    simp only [pure_bind] at h
    obtain ⟨hfit, hraw⟩ := pack_success _ _ _ right.power.isLt h
    have hfit' : (((stateRootIndex.index.val <<< fls right.index.val) % word) |||
        (right.index.val ^^^ ((1 <<< fls right.index.val) % word))) < indexModulus := by
      unfold indexModulus
      exact hfit
    refine ⟨⟨⟨_, hfit'⟩, right.power⟩, ?_, ?_⟩
    · unfold sourceConcat
      dsimp only
      unfold wordModulus
      unfold word at hfit'
      rw [if_neg hguard, dif_pos hfit']
      first | rfl | (unfold word; rfl)
    · rw [hraw]
      rfl

/-- The compiled wrapper on the constructor words is the typed wrapper. -/
theorem wrapper_success (cfg : Configuration) (slot : Fin (2 ^ 64)) (n : Fin wordModulus)
    (raw : Nat) (h : wrapper (cfgWords cfg) slot.val n.val = .ok raw) :
    ∃ gi, sourceWrapper cfg slot n = .ok gi ∧ raw = packWord gi := by
  unfold wrapper at h
  obtain ⟨var, hvar, h⟩ := bind_success h
  obtain ⟨out, hout, hv⟩ := validatorGi_success cfg slot n var hvar
  subst hv
  obtain ⟨gi, hgi, hraw⟩ := concat_success out raw h
  refine ⟨gi, ?_, hraw⟩
  unfold sourceWrapper
  rw [hout]
  exact hgi

/-- The proof loop's `shr(8, ·)` of the packed word is the typed index. -/
theorem packWord_div (g : PackedIndex) : packWord g / 256 = g.index.val := by
  unfold packWord
  have := g.power.isLt
  omega

/-- Pinned constructor words (IR 10-17): `pack(11 + 8, 3) = 2819`, `pack(150 << 40, 40)`. -/
theorem pinned_words (pivot : Fin (2 ^ 64)) :
    cfgWords (pinnedConfiguration pivot) = ⟨2819, 0x96000000000028, 0x96000000000028, pivot.val⟩ := by
  show Words.mk (packWord stateRootIndex) (packWord pinnedBase) (packWord pinnedBase) pivot.val = _
  rw [show packWord stateRootIndex = 2819 from by decide,
    show packWord pinnedBase = 0x96000000000028 from by decide]

#print axioms wrapper_success
#print axioms pinned_words
end LidoSRv3.Audit.Source.SszCompiledGIndex
