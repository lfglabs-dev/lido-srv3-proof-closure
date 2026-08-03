import Verity.Stdlib.Math

/-!
# Canonical P-ALLOC-1 model

This is the minimal audit model of
`SRLib._getModulesAllocationAndCapacity` at Lido core commit
`af095e48bbc1c3841c2c9936219c8461af01056b`. Economic values are Verity
`Uint256` words. Every Solidity-checked `+`, `-`, and `*`, and every checked
division, is represented by the corresponding Verity `safe*` operation.
`Nat` is used only for list recursion and for the proved mathematical view.
-/

namespace LidoSRv3.Audit.AllocCapacity

open Verity
open Verity.Stdlib.Math

/-- `SRUtils.TOTAL_BASIS_POINTS` (`SRUtils.sol`, line 17). -/
def totalBasisPoints : Uint256 := 10000

/-- Values cached/read for one router-ordered module in source lines 509--529. -/
structure Module where
  moduleId : Uint256
  shareLimit : Uint256
  isActive : Bool
  isType2 : Bool
  depositableCount : Uint256
  depositedCount : Uint256
  summaryExitedCount : Uint256
  accountingExitedCount : Uint256
  totalModuleStake : Uint256
  deriving DecidableEq, Repr

structure Config where
  maxEBType1 : Uint256
  maxEBType2 : Uint256
  deriving DecidableEq, Repr

/-- Audit row retaining both returned columns and the proof-relevant values. -/
structure Row where
  moduleId : Uint256
  currentAllocation : Uint256
  capacity : Uint256
  targetValidators : Uint256
  activeCount : Uint256
  deriving DecidableEq, Repr

def wordMax (a b : Uint256) : Uint256 := if a ≤ b then b else a
def wordMin (a b : Uint256) : Uint256 := if a ≤ b then a else b

/-- Lines 521--522: Solidity checked subtraction after `Math.max`. -/
def activeCount? (m : Module) : Option Uint256 :=
  safeSub m.depositedCount (wordMax m.summaryExitedCount m.accountingExitedCount)

/-- OpenZeppelin `Math.ceilDiv`: division-by-zero reverts; its internal
`unchecked` formula is represented by Verity's pinned `ceilDiv`. -/
def ceilDiv? (a b : Uint256) : Option Uint256 :=
  if b = 0 then none else some (ceilDiv a b)

/-- Lines 527--531. -/
def allocationEntry? (cfg : Config) (m : Module) : Option (Uint256 × Uint256) := do
  let active ← activeCount? m
  let allocation ← if m.isType2 then ceilDiv? m.totalModuleStake cfg.maxEBType1 else some active
  pure (allocation, active)

/-- Lines 506--532, in router order. -/
def firstLoop (cfg : Config) : List Module → Uint256 → Option (List (Uint256 × Uint256) × Uint256)
  | [], total => some ([], total)
  | m :: ms, total => do
      let entry ← allocationEntry? cfg m
      let nextTotal ← safeAdd total entry.1
      let (entries, finalTotal) ← firstLoop cfg ms nextTotal
      pure (entry :: entries, finalTotal)

/-- Lines 543--549. -/
def availableCapacity? (cfg : Config) (isTopUp : Bool) (m : Module)
    (allocation active : Uint256) : Option Uint256 :=
  if isTopUp && m.isType2 then do
    let weiCapacity ← safeMul active cfg.maxEBType2
    safeDiv weiCapacity cfg.maxEBType1
  else
    safeAdd allocation m.depositableCount

/-- Lines 550--554. Multiplication is Solidity checked before division. -/
def targetValidators? (total : Uint256) (m : Module) : Option Uint256 := do
  let numerator ← safeMul m.shareLimit total
  safeDiv numerator totalBasisPoints

/-- Lines 539--558. Inactive modules retain their current allocation. -/
def secondLoop (cfg : Config) (isTopUp : Bool) (total : Uint256) :
    List Module → List (Uint256 × Uint256) → Option (List Row)
  | [], [] => some []
  | m :: ms, entry :: entries => do
      let (allocation, active) := entry
      if m.isActive then
        let available ← availableCapacity? cfg isTopUp m allocation active
        let target ← targetValidators? total m
        let rows ← secondLoop cfg isTopUp total ms entries
        pure (({
          moduleId := m.moduleId
          currentAllocation := allocation
          capacity := wordMin target available
          targetValidators := target
          activeCount := active
        } : Row) :: rows)
      else
        let rows ← secondLoop cfg isTopUp total ms entries
        pure (({
          moduleId := m.moduleId
          currentAllocation := allocation
          capacity := allocation
          targetValidators := 0
          activeCount := active
        } : Row) :: rows)
  | _, _ => none

/-- Exact checked-`uint256` execution of source lines 493--559. -/
def execute (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256)
    (isTopUp : Bool) : Option (List Row) := do
  let (entries, total) ← firstLoop cfg modules depositsToAllocate
  secondLoop cfg isTopUp total modules entries

namespace MathView

def activeCount (m : Module) : Nat :=
  (m.depositedCount : Nat) - max (m.summaryExitedCount : Nat) (m.accountingExitedCount : Nat)

def allocationEntry (cfg : Config) (m : Module) : Nat :=
  if m.isType2 then
    if (cfg.maxEBType1 : Nat) = 0 then 0
    else ((m.totalModuleStake : Nat) + (cfg.maxEBType1 : Nat) - 1) /
      (cfg.maxEBType1 : Nat)
  else activeCount m

def totalValidators (cfg : Config) (modules : List Module) (deposits : Uint256) : Nat :=
  (deposits : Nat) + (modules.map (allocationEntry cfg)).sum

def availableCapacity (cfg : Config) (isTopUp : Bool) (m : Module) : Nat :=
  if isTopUp && m.isType2 then
    activeCount m * (cfg.maxEBType2 : Nat) / (cfg.maxEBType1 : Nat)
  else allocationEntry cfg m + (m.depositableCount : Nat)

def targetValidators (cfg : Config) (modules : List Module) (deposits : Uint256)
    (m : Module) : Nat :=
  (m.shareLimit : Nat) * totalValidators cfg modules deposits / 10000

def capacity (cfg : Config) (modules : List Module) (deposits : Uint256)
    (isTopUp : Bool) (m : Module) : Nat :=
  if m.isActive then
    min (targetValidators cfg modules deposits m) (availableCapacity cfg isTopUp m)
  else allocationEntry cfg m

def capacities (cfg : Config) (modules : List Module) (deposits : Uint256)
    (isTopUp : Bool) : List Nat :=
  modules.map (capacity cfg modules deposits isTopUp)

end MathView

/-- Named checked-arithmetic bounds for the pinned function. These are exactly
the source operations capable of reverting because of arithmetic. -/
structure CheckedBounds (cfg : Config) (modules : List Module)
    (depositsToAllocate : Uint256) (isTopUp : Bool) : Prop where
  maxEBType1_nonzero : cfg.maxEBType1 ≠ 0
  active_subtraction : ∀ m ∈ modules,
    (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤ (m.depositedCount : Nat)
  total_addition : (depositsToAllocate : Nat) +
    (modules.map (MathView.allocationEntry cfg)).sum ≤ MAX_UINT256
  available_arithmetic : ∀ m ∈ modules, m.isActive = true →
    if isTopUp && m.isType2 then
      MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤ MAX_UINT256
    else
      MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤ MAX_UINT256
  target_multiplication : ∀ m ∈ modules, m.isActive = true →
    (m.shareLimit : Nat) * MathView.totalValidators cfg modules depositsToAllocate ≤ MAX_UINT256

/-- A successful checked subtraction has the same value as mathematical
subtraction under its named underflow bound. -/
theorem safeSub_refines_nat (a b c : Uint256) (hBound : (b : Nat) ≤ (a : Nat))
    (h : safeSub a b = some c) : (c : Nat) = (a : Nat) - (b : Nat) := by
  simp [safeSub, Nat.not_lt.mpr hBound] at h
  subst c
  exact Verity.Core.Uint256.sub_eq_of_le hBound

/-- A successful checked addition has the same value as mathematical addition
under its named overflow bound. -/
theorem safeAdd_refines_nat (a b c : Uint256)
    (hBound : (a : Nat) + (b : Nat) ≤ MAX_UINT256)
    (h : safeAdd a b = some c) : (c : Nat) = (a : Nat) + (b : Nat) := by
  simp [safeAdd, Nat.not_lt.mpr hBound] at h
  subst c
  apply Verity.Core.Uint256.add_eq_of_lt
  rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
  exact Nat.lt_succ_of_le hBound

/-- A successful checked multiplication has the same value as mathematical
multiplication under its named overflow bound. -/
theorem safeMul_refines_nat (a b c : Uint256)
    (hBound : (a : Nat) * (b : Nat) ≤ MAX_UINT256)
    (h : safeMul a b = some c) : (c : Nat) = (a : Nat) * (b : Nat) := by
  simp [safeMul, Nat.not_lt.mpr hBound] at h
  subst c
  apply Verity.Core.Uint256.mul_eq_of_lt
  rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
  exact Nat.lt_succ_of_le hBound

/-- Checked division refines truncating natural division at a nonzero divisor. -/
theorem safeDiv_refines_nat (a b c : Uint256) (hNonzero : b ≠ 0)
    (h : safeDiv a b = some c) : (c : Nat) = (a : Nat) / (b : Nat) := by
  have hb : (b : Nat) ≠ 0 := by
    intro hb
    exact hNonzero (Verity.Core.Uint256.ext (by simpa using hb))
  simp [safeDiv, hb] at h
  subst c
  simp only [HDiv.hDiv, Verity.Core.Uint256.div, hb, if_false,
    Verity.Core.Uint256.coe_ofNat]
  apply Nat.mod_eq_of_lt
  exact Nat.lt_of_le_of_lt (Nat.div_le_self _ _) a.isLt

theorem wordMax_coe (a b : Uint256) :
    (wordMax a b : Nat) = max (a : Nat) (b : Nat) := by
  unfold wordMax
  split <;> rename_i h
  · have hn : (a : Nat) ≤ (b : Nat) := by exact_mod_cast h
    omega
  · have hn : (b : Nat) ≤ (a : Nat) := by
      have hnat : ¬ (a : Nat) ≤ (b : Nat) := by exact_mod_cast h
      omega
    omega

theorem activeCount_success (m : Module)
    (h : (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤
      (m.depositedCount : Nat)) :
    ∃ active, activeCount? m = some active ∧ (active : Nat) = MathView.activeCount m := by
  unfold activeCount?
  have hs : ¬ (m.depositedCount : Nat) <
      (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) := Nat.not_lt.mpr h
  simp only [safeSub, hs, if_false]
  refine ⟨_, rfl, ?_⟩
  unfold MathView.activeCount
  rw [Verity.Core.Uint256.sub_eq_of_le h, wordMax_coe]

theorem ceilDiv_coe (a b : Uint256) (hB : b ≠ 0) :
    (ceilDiv a b : Nat) = ((a : Nat) + (b : Nat) - 1) / (b : Nat) := by
  have hBVal : (b : Nat) ≠ 0 := by
    intro h
    exact hB (Verity.Core.Uint256.ext (by simpa using h))
  have hBPos : 0 < (b : Nat) := Nat.pos_of_ne_zero hBVal
  by_cases hA : (a : Nat) = 0
  · have hAZ : a = 0 := Verity.Core.Uint256.ext (by simpa using hA)
    simp [ceilDiv, hAZ]
    exact (Nat.div_eq_of_lt (Nat.sub_lt hBPos (by decide))).symm
  · have hAPos : 0 < (a : Nat) := Nat.pos_of_ne_zero hA
    have hANe : (a == 0) = false := by
      simp [BEq.beq]
      intro h
      exact hA (congrArg (fun x : Uint256 => x.val) h)
    have hSub : ((a - 1 : Uint256) : Nat) = (a : Nat) - 1 :=
      Verity.Core.Uint256.sub_eq_of_le hAPos
    have hDivLtMod : ((a : Nat) - 1) / (b : Nat) < Verity.Core.Uint256.modulus :=
      Nat.lt_of_le_of_lt (Nat.div_le_self _ _) (Nat.lt_of_le_of_lt (Nat.sub_le _ _) a.isLt)
    have hDivLt : ((a : Nat) - 1) / (b : Nat) + 1 < Verity.Core.Uint256.modulus :=
      Nat.lt_of_le_of_lt
        (Nat.succ_le_of_lt
          (Nat.lt_of_le_of_lt (Nat.div_le_self _ _) (Nat.sub_lt hAPos (by decide)))) a.isLt
    have hDivEq : ((a - 1 : Uint256) / b : Uint256).val =
        ((a : Nat) - 1) / (b : Nat) := by
      simp only [HDiv.hDiv, Verity.Core.Uint256.div, hBVal, if_false,
        Verity.Core.Uint256.ofNat, hSub]
      exact Nat.mod_eq_of_lt hDivLtMod
    have hAddLt : ((a - 1 : Uint256) / b).val + (1 : Uint256).val <
        Verity.Core.Uint256.modulus := by
      rw [hDivEq, Verity.Core.Uint256.val_one]
      exact hDivLt
    have hCeilEq : ceilDiv a b = (a - 1) / b + 1 := by
      unfold ceilDiv
      simp [hANe]
    rw [hCeilEq, Verity.Core.Uint256.add_eq_of_lt hAddLt, hDivEq,
      Verity.Core.Uint256.val_one]
    have key : (a : Nat) + (b : Nat) - 1 = ((a : Nat) - 1) + (b : Nat) := by omega
    rw [key, Nat.add_div_right _ hBPos]

theorem allocationEntry_success (cfg : Config) (m : Module)
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hSub : (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤
      (m.depositedCount : Nat)) :
    ∃ entry, allocationEntry? cfg m = some entry ∧
      (entry.1 : Nat) = MathView.allocationEntry cfg m ∧
      (entry.2 : Nat) = MathView.activeCount m := by
  obtain ⟨active, hActive, hActiveNat⟩ := activeCount_success m hSub
  by_cases hType : m.isType2 = true
  · have hCfgNat : (cfg.maxEBType1 : Nat) ≠ 0 := by
      intro h
      exact hCfg (Verity.Core.Uint256.ext (by simpa using h))
    refine ⟨(ceilDiv m.totalModuleStake cfg.maxEBType1, active), ?_, ?_, hActiveNat⟩
    · simp [allocationEntry?, hActive, hType, ceilDiv?, hCfg]
    · simp only [MathView.allocationEntry, hType, if_true, hCfgNat]
      exact ceilDiv_coe m.totalModuleStake cfg.maxEBType1 hCfg
  · refine ⟨(active, active), ?_, ?_, hActiveNat⟩
    · simp [allocationEntry?, hActive, hType]
    · simp [MathView.allocationEntry, hType, hActiveNat]

theorem firstLoop_refines (cfg : Config) (modules : List Module) (start : Uint256)
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hSub : ∀ m ∈ modules,
      (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤
        (m.depositedCount : Nat))
    (hTotal : (start : Nat) + (modules.map (MathView.allocationEntry cfg)).sum ≤
      MAX_UINT256) :
    ∃ entries total, firstLoop cfg modules start = some (entries, total) ∧
      entries.map (fun e => (e.1 : Nat)) = modules.map (MathView.allocationEntry cfg) ∧
      entries.map (fun e => (e.2 : Nat)) = modules.map MathView.activeCount ∧
      (total : Nat) = (start : Nat) + (modules.map (MathView.allocationEntry cfg)).sum := by
  induction modules generalizing start with
  | nil =>
      refine ⟨[], start, rfl, rfl, rfl, ?_⟩
      simp
  | cons m ms ih =>
      obtain ⟨entry, hEntry, hAlloc, hActive⟩ := allocationEntry_success cfg m hCfg (hSub m (by simp))
      have hHead : (start : Nat) + (entry.1 : Nat) ≤ MAX_UINT256 := by
        simp only [List.map_cons, List.sum_cons] at hTotal
        omega
      have hSafe : safeAdd start entry.1 = some (start + entry.1) := by
        simp [safeAdd, Nat.not_lt.mpr hHead]
      have hNext : ((start + entry.1 : Uint256) : Nat) =
          (start : Nat) + (entry.1 : Nat) := by
        apply Verity.Core.Uint256.add_eq_of_lt
        rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
        exact Nat.lt_succ_of_le hHead
      have hTailBound : ((start + entry.1 : Uint256) : Nat) +
          (ms.map (MathView.allocationEntry cfg)).sum ≤ MAX_UINT256 := by
        rw [hNext, hAlloc]
        simpa only [List.map_cons, List.sum_cons, Nat.add_assoc] using hTotal
      obtain ⟨entries, total, hLoop, hEntries, hActives, hFinal⟩ :=
        ih (start + entry.1) (fun x hx => hSub x (by simp [hx])) hTailBound
      refine ⟨entry :: entries, total, ?_, ?_, ?_, ?_⟩
      · simp [firstLoop, hEntry, hSafe, hLoop]
      · simp [hAlloc, hEntries]
      · simp [hActive, hActives]
      · rw [hFinal, hNext, hAlloc]
        simp [Nat.add_assoc]

theorem wordMin_coe (a b : Uint256) :
    (wordMin a b : Nat) = min (a : Nat) (b : Nat) := by
  unfold wordMin
  split <;> rename_i h
  · have hn : (a : Nat) ≤ (b : Nat) := by exact_mod_cast h
    omega
  · have hn : ¬ (a : Nat) ≤ (b : Nat) := by exact_mod_cast h
    omega

theorem availableCapacity_success (cfg : Config) (isTopUp : Bool) (m : Module)
    (allocation active : Uint256) (hCfg : cfg.maxEBType1 ≠ 0)
    (hAllocation : (allocation : Nat) = MathView.allocationEntry cfg m)
    (hActive : (active : Nat) = MathView.activeCount m)
    (hBound : if isTopUp && m.isType2 then
      MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤ MAX_UINT256
    else MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤ MAX_UINT256) :
    ∃ available, availableCapacity? cfg isTopUp m allocation active = some available ∧
      (available : Nat) = MathView.availableCapacity cfg isTopUp m := by
  cases isTopUp <;> cases hType : m.isType2
  · have hAdd : (allocation : Nat) + (m.depositableCount : Nat) ≤ MAX_UINT256 := by
      simpa [hType, hAllocation] using hBound
    refine ⟨allocation + m.depositableCount, ?_, ?_⟩
    · simp [availableCapacity?, hType, safeAdd, Nat.not_lt.mpr hAdd]
    · rw [Verity.Core.Uint256.add_eq_of_lt]
      · simp [MathView.availableCapacity, hType, hAllocation]
      · rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
        exact Nat.lt_succ_of_le hAdd
  · have hAdd : (allocation : Nat) + (m.depositableCount : Nat) ≤ MAX_UINT256 := by
      simpa [hType, hAllocation] using hBound
    refine ⟨allocation + m.depositableCount, ?_, ?_⟩
    · simp [availableCapacity?, hType, safeAdd, Nat.not_lt.mpr hAdd]
    · rw [Verity.Core.Uint256.add_eq_of_lt]
      · simp [MathView.availableCapacity, hType, hAllocation]
      · rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
        exact Nat.lt_succ_of_le hAdd
  · have hAdd : (allocation : Nat) + (m.depositableCount : Nat) ≤ MAX_UINT256 := by
      simpa [hType, hAllocation] using hBound
    refine ⟨allocation + m.depositableCount, ?_, ?_⟩
    · simp [availableCapacity?, hType, safeAdd, Nat.not_lt.mpr hAdd]
    · rw [Verity.Core.Uint256.add_eq_of_lt]
      · simp [MathView.availableCapacity, hType, hAllocation]
      · rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
        exact Nat.lt_succ_of_le hAdd
  · have hMul : (active : Nat) * (cfg.maxEBType2 : Nat) ≤ MAX_UINT256 := by
      simpa [hType, hActive] using hBound
    have hSafeMul : safeMul active cfg.maxEBType2 = some (active * cfg.maxEBType2) := by
      simp [safeMul, Nat.not_lt.mpr hMul]
    have hMulNat : ((active * cfg.maxEBType2 : Uint256) : Nat) =
        (active : Nat) * (cfg.maxEBType2 : Nat) := by
      apply Verity.Core.Uint256.mul_eq_of_lt
      rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
      exact Nat.lt_succ_of_le hMul
    have hCfgNat : (cfg.maxEBType1 : Nat) ≠ 0 := by
      intro h
      exact hCfg (Verity.Core.Uint256.ext (by simpa using h))
    let available := (active * cfg.maxEBType2) / cfg.maxEBType1
    have hDiv : safeDiv (active * cfg.maxEBType2) cfg.maxEBType1 = some available := by
      simp [available, safeDiv, hCfgNat]
    refine ⟨available, ?_, ?_⟩
    · simp [availableCapacity?, hType, hSafeMul, hDiv]
    · rw [safeDiv_refines_nat _ _ _ hCfg hDiv, hMulNat, hActive]
      simp [MathView.availableCapacity, hType]

theorem targetValidators_success (total : Uint256) (m : Module)
    (hTotal : (total : Nat) = MathView.totalValidators cfg modules deposits)
    (hBound : (m.shareLimit : Nat) * MathView.totalValidators cfg modules deposits ≤
      MAX_UINT256) :
    ∃ target, targetValidators? total m = some target ∧
      (target : Nat) = MathView.targetValidators cfg modules deposits m := by
  have hMul : (m.shareLimit : Nat) * (total : Nat) ≤ MAX_UINT256 := by
    simpa [hTotal] using hBound
  have hSafeMul : safeMul m.shareLimit total = some (m.shareLimit * total) := by
    simp [safeMul, Nat.not_lt.mpr hMul]
  have hMulNat : ((m.shareLimit * total : Uint256) : Nat) =
      (m.shareLimit : Nat) * (total : Nat) := by
    apply Verity.Core.Uint256.mul_eq_of_lt
    rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
    exact Nat.lt_succ_of_le hMul
  let target := (m.shareLimit * total) / totalBasisPoints
  have hDiv : safeDiv (m.shareLimit * total) totalBasisPoints = some target := by
    have hB : (totalBasisPoints : Nat) ≠ 0 := by decide
    simp [target, safeDiv, hB]
  refine ⟨target, ?_, ?_⟩
  · simpa [targetValidators?, hSafeMul, Verity.Core.Uint256.mul_comm] using hDiv
  · rw [safeDiv_refines_nat _ _ _ (by decide) hDiv, hMulNat, hTotal]
    rfl

theorem secondLoop_refines (cfg : Config) (allModules : List Module)
    (deposits : Uint256) (isTopUp : Bool) (total : Uint256)
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hTotal : (total : Nat) = MathView.totalValidators cfg allModules deposits)
    (hAvailable : ∀ m ∈ allModules, m.isActive = true →
      if isTopUp && m.isType2 then
        MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤ MAX_UINT256
      else MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤ MAX_UINT256)
    (hTarget : ∀ m ∈ allModules, m.isActive = true →
      (m.shareLimit : Nat) * MathView.totalValidators cfg allModules deposits ≤ MAX_UINT256) :
    ∀ (modules : List Module) (entries : List (Uint256 × Uint256)),
      (∀ m ∈ modules, m ∈ allModules) →
      entries.map (fun e => (e.1 : Nat)) = modules.map (MathView.allocationEntry cfg) →
      entries.map (fun e => (e.2 : Nat)) = modules.map MathView.activeCount →
      ∃ rows, secondLoop cfg isTopUp total modules entries = some rows ∧
        rows.map (fun r => (r.capacity : Nat)) =
          modules.map (MathView.capacity cfg allModules deposits isTopUp) := by
  intro modules
  induction modules with
  | nil =>
      intro entries _ hAlloc _
      cases entries with
      | nil => exact ⟨[], rfl, rfl⟩
      | cons entry entries => simp at hAlloc
  | cons m ms ih =>
      intro entries hMem hAlloc hActiveEntries
      cases entries with
      | nil => simp at hAlloc
      | cons entry entries =>
          simp only [List.map_cons, List.cons.injEq] at hAlloc hActiveEntries
          have hm : m ∈ allModules := hMem m (by simp)
          have hms : ∀ x ∈ ms, x ∈ allModules := by
            intro x hx
            exact hMem x (by simp [hx])
          obtain ⟨tail, hTail, hTailCaps⟩ := ih entries hms hAlloc.2 hActiveEntries.2
          by_cases hIsActive : m.isActive = true
          · obtain ⟨available, hAvail, hAvailNat⟩ := availableCapacity_success cfg isTopUp m
              entry.1 entry.2 hCfg hAlloc.1 hActiveEntries.1 (hAvailable m hm hIsActive)
            obtain ⟨target, hTargetExec, hTargetNat⟩ := targetValidators_success total m hTotal
              (hTarget m hm hIsActive)
            refine ⟨({
              moduleId := m.moduleId
              currentAllocation := entry.1
              capacity := wordMin target available
              targetValidators := target
              activeCount := entry.2
            } : Row) :: tail, ?_, ?_⟩
            · simp [secondLoop, hIsActive, hAvail, hTargetExec, hTail]
            · simp only [List.map_cons, List.cons.injEq]
              constructor
              · rw [wordMin_coe, hTargetNat, hAvailNat]
                simp [MathView.capacity, hIsActive]
              · exact hTailCaps
          · refine ⟨({
              moduleId := m.moduleId
              currentAllocation := entry.1
              capacity := entry.1
              targetValidators := 0
              activeCount := entry.2
            } : Row) :: tail, ?_, ?_⟩
            · simp [secondLoop, hIsActive, hTail]
            · simp [MathView.capacity, hIsActive, hAlloc.1, hTailCaps]

/-- Under the exact checked-arithmetic bounds, the canonical source-shaped
executor succeeds and its capacity column equals the mathematical model. -/
theorem execute_refines_math (cfg : Config) (modules : List Module)
    (deposits : Uint256) (isTopUp : Bool) (hBounds : CheckedBounds cfg modules deposits isTopUp) :
    ∃ rows, execute cfg modules deposits isTopUp = some rows ∧
      rows.map (fun r => (r.capacity : Nat)) = MathView.capacities cfg modules deposits isTopUp := by
  obtain ⟨entries, total, hFirst, hAlloc, hActive, hTotal⟩ :=
    firstLoop_refines cfg modules deposits hBounds.maxEBType1_nonzero
      hBounds.active_subtraction hBounds.total_addition
  obtain ⟨rows, hSecond, hCaps⟩ := secondLoop_refines cfg modules deposits isTopUp total
    hBounds.maxEBType1_nonzero hTotal hBounds.available_arithmetic
    hBounds.target_multiplication modules entries (by simp) hAlloc hActive
  refine ⟨rows, ?_, hCaps⟩
  simp [execute, hFirst, hSecond]

theorem active_capacity_bounded (cfg : Config) (modules : List Module)
    (deposits : Uint256) (isTopUp : Bool) (m : Module) (hActive : m.isActive = true) :
    MathView.capacity cfg modules deposits isTopUp m ≤
        MathView.targetValidators cfg modules deposits m ∧
      MathView.capacity cfg modules deposits isTopUp m ≤
        MathView.availableCapacity cfg isTopUp m := by
  simp [MathView.capacity, hActive, Nat.min_le_left, Nat.min_le_right]

/-- Router ordering is structural: both columns have exactly one row per input
module, and the row identifiers are unchanged. -/
theorem secondLoop_router_order {cfg : Config} {isTopUp : Bool} {total : Uint256}
    {modules : List Module} {entries : List (Uint256 × Uint256)} {rows : List Row}
    (h : secondLoop cfg isTopUp total modules entries = some rows) :
    rows.map Row.moduleId = modules.map Module.moduleId := by
  induction modules generalizing entries rows with
  | nil =>
      cases entries with
      | nil => simpa [secondLoop] using congrArg (Option.map (List.map Row.moduleId)) h
      | cons entry entries => simp [secondLoop] at h
  | cons m ms ih =>
      cases entries with
      | nil => simp [secondLoop] at h
      | cons entry entries =>
          simp only [secondLoop] at h
          split at h
          · cases hAvailable : availableCapacity? cfg isTopUp m entry.fst entry.snd with
            | none => simp [hAvailable] at h
            | some available =>
              cases hTarget : targetValidators? total m with
              | none => simp [hAvailable, hTarget] at h
              | some target =>
                cases hTail : secondLoop cfg isTopUp total ms entries with
                | none => simp [hAvailable, hTarget, hTail] at h
                | some tail =>
                  simp [hAvailable, hTarget, hTail] at h
                  subst rows
                  simp only [List.map_cons, List.cons.injEq, true_and]
                  exact ih hTail
          · cases hTail : secondLoop cfg isTopUp total ms entries with
            | none => simp [hTail] at h
            | some tail =>
              simp [hTail] at h
              subst rows
              simp only [List.map_cons, List.cons.injEq, true_and]
              exact ih hTail

end LidoSRv3.Audit.AllocCapacity
