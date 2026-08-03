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
    else if (m.totalModuleStake : Nat) = 0 then 0
    else ((m.totalModuleStake : Nat) - 1) / (cfg.maxEBType1 : Nat) + 1
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
