import LidoSRv3.Audit.Guarantees.PAlloc1

/-!
# P-ALLOC-1 audit probe (round 2 note)

Machine-checked observations behind the round-2 proof audit in
`report/P-ALLOC-1.md`.  This module is **not evidence**: it is not imported by
`LidoSRv3.Audit.Guarantees.AllGuarantees`, not printed by
`LidoSRv3.Audit.Trust`, and not named in `audit/guarantees.yaml`.

1. `bind_round_trip` — the registered Verity theorem's `hBind` premise has a
   concrete witness, so `verity_tx_simulates_allocation` is not vacuous.
2. `verity_tx_simulates_any_exec` — the registered Verity correspondence is
   reproved with the interpreter replaced by an arbitrary function of the same
   type, so it uses no property of `sourceExecute` whatsoever.
3. `capacity_target_mutant_survives_registered_verity_shape` — the registered
   parent's kill-line mutant (`capacity := target`, dropping the `wordMin`
   headroom clamp) satisfies the registered *Verity* statement's exact shape,
   while `capacity_target_mutant_is_observably_wrong` shows it really does
   commit a different capacity column.
4. `zero_allocation_column_mutant_survives_registered_parent` — a mutant that
   reports a zero allocation column while computing capacities honestly
   satisfies the registered *abstract* parent `checked_execute`'s exact shape,
   because that parent compares only the capacity column.
-/

namespace LidoSRv3.Tests.Alloc1AuditProbe

open Verity
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.Verity.AllocationTx

private def w (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def cfg : Config := ⟨w 32, w 64⟩

private def modA : BoundModule :=
  { moduleId := w 7, moduleAddress := w 17, shareLimit := w 5000
    isActive := true, isType2 := false
    depositableCount := w 90, depositedCount := w 10
    summaryExitedCount := w 0, accountingExitedCount := w 0
    totalModuleStake := w 0 }

private def modB : BoundModule :=
  { moduleId := w 8, moduleAddress := w 18, shareLimit := w 5000
    isActive := true, isType2 := false
    depositableCount := w 90, depositedCount := w 10
    summaryExitedCount := w 0, accountingExitedCount := w 0
    totalModuleStake := w 0 }

private def modules : List BoundModule := [modA, modB]

/-! ## 1. `hBind` is satisfiable -/

/-- The registered Verity theorem assumes `sourceBindAll state modules.length =
modules`.  The seed harness produces such a state, so the theorem is not
vacuous. -/
theorem bind_round_trip :
    sourceBindAll (stateFor modules) modules.length = modules := by
  native_decide

/-- Stronger: `hBind` is not a restriction on the state at all.  For every
state and every count, the bind of that state satisfies the premise, so the
registered Verity theorem applies to every state and every `count`, including
counts above `MAX_STAKING_MODULES_COUNT` and counts that walk unseeded rows. -/
theorem bind_premise_is_total (state : ContractState) (count : Nat) :
    sourceBindAll state (sourceBindAll state count).length =
      sourceBindAll state count := by
  simp [sourceBindAll]

/-! ## 2. The Verity correspondence holds for an arbitrary interpreter -/

abbrev ExecFn := Config → List BoundModule → Word → Bool → Option (List Row × Word)

def allocateGen (exec : ExecFn) (count : Nat) (cfg : Config) (deposits : Word)
    (isTopUp : Bool) (failAfterWrites : Bool := false) : Contract Result :=
  fun snapshot =>
    let modules := sourceBindAll snapshot count
    match exec cfg modules deposits isTopUp with
    | none => .revert "ALLOC_ARITHMETIC" snapshot
    | some (rows, total) =>
        let addresses := modules.map BoundModule.moduleAddress
        let dirty := persistRows rows addresses snapshot
        let dirty := dirty.writeSlot totalSlot total
        if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
        else
          .success ⟨rows.map Row.currentAllocation, rows.map Row.capacity,
            addresses, total⟩ dirty

def sourceViewGen (exec : ExecFn) (cfg : Config) (modules : List BoundModule)
    (deposits : Word) (isTopUp : Bool) : View :=
  match exec cfg modules deposits isTopUp with
  | none => ⟨.reverted, [], [], modules.map BoundModule.moduleAddress, 0⟩
  | some (rows, total) =>
      ⟨.committed, rows.map Row.currentAllocation, rows.map Row.capacity,
        modules.map BoundModule.moduleAddress, total⟩

private theorem persistRows_read' (rows : List Row) (addrs : List Word)
    (state : ContractState) :
    (persistRows rows addrs state).readArray allocationSlot =
      rows.map Row.currentAllocation ∧
    (persistRows rows addrs state).readArray capacitySlot =
      rows.map Row.capacity ∧
    (persistRows rows addrs state).readArray boundAddressSlot = addrs := by
  unfold persistRows ContractState.readArray ContractState.writeArray
  simp [allocationSlot, capacitySlot, boundAddressSlot]

/-- **The registered Verity statement is interpreter-agnostic.**  This is
`verity_tx_simulates_pinned_source` with `sourceExecute` replaced by an
arbitrary `exec` of the same type and the honest proof script unchanged.  No
property of `exec` is assumed, so the registered correspondence certifies the
bind identity, the persist/reread channel, and the revert-arm agreement, and
nothing about the allocation arithmetic. -/
theorem verity_tx_simulates_any_exec (exec : ExecFn)
    (cfg : Config) (modules : List BoundModule) (deposits : Word)
    (isTopUp : Bool) (state : ContractState)
    (hBind : sourceBindAll state modules.length = modules) :
    observe modules
        ((allocateGen exec modules.length cfg deposits isTopUp).run state) =
      sourceViewGen exec cfg modules deposits isTopUp := by
  unfold Contract.run allocateGen sourceViewGen
  simp only [hBind]
  cases hRun : exec cfg modules deposits isTopUp with
  | none => simp [observe]
  | some result =>
      rcases result with ⟨rows, total⟩
      have hread := persistRows_read' rows (modules.map BoundModule.moduleAddress) state
      simp [observe, ContractState.readArray, totalSlot,
        ContractState.readSlot_writeSlot_same, ContractState.storageArray_writeSlot]
      exact hread

/-! ## 3. The registered parent's kill-line mutant satisfies the Verity shape -/

/-- The kill-line mutation of `AllocCapacity.secondLoop`: report the raw
share-limit target as capacity, skipping the `wordMin` clamp against available
headroom.  This is the mutant `AllocationTxMutants.capacity_target_kill_line_refutes_parent`
uses to refute the registered abstract parent. -/
def secondLoopCapTarget (cfg : Config) (isTopUp : Bool) (total : Uint256) :
    List Module → List (Uint256 × Uint256) → Option (List Row)
  | [], [] => some []
  | m :: ms, entry :: entries => do
      let (allocation, active) := entry
      if m.isActive then
        let _available ← availableCapacity? cfg isTopUp m allocation active
        let target ← targetValidators? total m
        let rows ← secondLoopCapTarget cfg isTopUp total ms entries
        pure (({ moduleId := m.moduleId, currentAllocation := allocation
                 capacity := target, targetValidators := target
                 activeCount := active } : Row) :: rows)
      else
        let rows ← secondLoopCapTarget cfg isTopUp total ms entries
        pure (({ moduleId := m.moduleId, currentAllocation := allocation
                 capacity := allocation, targetValidators := 0
                 activeCount := active } : Row) :: rows)
  | _, _ => none

def execCapTarget : ExecFn := fun cfg ms deposits isTopUp => do
  let (entries, total) ← firstLoop cfg (ms.map toSourceModule) deposits
  let rows ← secondLoopCapTarget cfg isTopUp total (ms.map toSourceModule) entries
  some (rows, total)

/-- **The parent kill-line does not bear on the registered Verity cell.**  The
`capacity := target` mutant, which refutes the registered abstract parent,
satisfies the registered Verity theorem's exact shape. -/
theorem capacity_target_mutant_survives_registered_verity_shape
    (cfg : Config) (modules : List BoundModule) (deposits : Word)
    (isTopUp : Bool) (state : ContractState)
    (hBind : sourceBindAll state modules.length = modules) :
    observe modules
        ((allocateGen execCapTarget modules.length cfg deposits isTopUp).run state) =
      sourceViewGen execCapTarget cfg modules deposits isTopUp :=
  verity_tx_simulates_any_exec execCapTarget cfg modules deposits isTopUp state hBind

private def killA : BoundModule :=
  { moduleId := w 1, moduleAddress := w 11, shareLimit := w 8000
    isActive := true, isType2 := false
    depositableCount := w 1, depositedCount := w 10
    summaryExitedCount := w 0, accountingExitedCount := w 0
    totalModuleStake := w 0 }

private def killB : BoundModule := { killA with moduleId := w 2, moduleAddress := w 12 }

private def killModules : List BoundModule := [killA, killB]

/-- The surviving mutant is a real behavioural change, not a rewriting: on the
kill-line witness it commits capacities `[24, 24]` where the honest interpreter
commits `[11, 11]`. -/
theorem capacity_target_mutant_is_observably_wrong :
    (sourceViewGen execCapTarget cfg killModules (w 10) false).capacities =
        [w 24, w 24] ∧
      (sourceView cfg killModules (w 10) false).capacities = [w 11, w 11] := by
  native_decide

/-! ## 4. The registered abstract parent does not constrain the allocation column -/

def zeroAlloc (r : Row) : Row := { r with currentAllocation := 0 }

/-- Mutation of `AllocCapacity.secondLoop` that reports a zero allocation
column while computing every capacity exactly as the honest interpreter does.
The live function returns both columns and the allocation column is the input
to `MinFirstAllocationStrategy`. -/
def secondLoopZeroAlloc (cfg : Config) (isTopUp : Bool) (total : Uint256) :
    List Module → List (Uint256 × Uint256) → Option (List Row)
  | [], [] => some []
  | m :: ms, entry :: entries => do
      let (allocation, active) := entry
      if m.isActive then
        let available ← availableCapacity? cfg isTopUp m allocation active
        let target ← targetValidators? total m
        let rows ← secondLoopZeroAlloc cfg isTopUp total ms entries
        pure (({ moduleId := m.moduleId, currentAllocation := 0
                 capacity := wordMin target available, targetValidators := target
                 activeCount := active } : Row) :: rows)
      else
        let rows ← secondLoopZeroAlloc cfg isTopUp total ms entries
        pure (({ moduleId := m.moduleId, currentAllocation := 0
                 capacity := allocation, targetValidators := 0
                 activeCount := active } : Row) :: rows)
  | _, _ => none

def executeZeroAlloc (cfg : Config) (modules : List Module) (deposits : Uint256)
    (isTopUp : Bool) : Option (List Row) := do
  let (entries, total) ← firstLoop cfg modules deposits
  secondLoopZeroAlloc cfg isTopUp total modules entries

private theorem secondLoopZeroAlloc_eq (cfg : Config) (isTopUp : Bool)
    (total : Uint256) :
    ∀ (ms : List Module) (entries : List (Uint256 × Uint256)),
      secondLoopZeroAlloc cfg isTopUp total ms entries =
        (secondLoop cfg isTopUp total ms entries).map (List.map zeroAlloc) := by
  intro ms
  induction ms with
  | nil =>
      intro entries
      cases entries <;> simp [secondLoop, secondLoopZeroAlloc]
  | cons m ms ih =>
      intro entries
      cases entries with
      | nil => simp [secondLoop, secondLoopZeroAlloc]
      | cons entry entries =>
          by_cases hActive : m.isActive
          · cases hAvail : availableCapacity? cfg isTopUp m entry.fst entry.snd with
            | none => simp [secondLoop, secondLoopZeroAlloc, hActive, hAvail]
            | some available =>
                cases hTarget : targetValidators? total m with
                | none =>
                    simp [secondLoop, secondLoopZeroAlloc, hActive, hAvail, hTarget]
                | some target =>
                    simp [secondLoop, secondLoopZeroAlloc, hActive, hAvail, hTarget,
                      ih entries, zeroAlloc]
                    cases secondLoop cfg isTopUp total ms entries <;> simp
          · simp [secondLoop, secondLoopZeroAlloc, hActive, ih entries]
            cases secondLoop cfg isTopUp total ms entries <;> simp [zeroAlloc]

private theorem executeZeroAlloc_eq (cfg : Config) (modules : List Module)
    (deposits : Uint256) (isTopUp : Bool) :
    executeZeroAlloc cfg modules deposits isTopUp =
      (LidoSRv3.Audit.AllocCapacity.execute cfg modules deposits isTopUp).map
        (List.map zeroAlloc) := by
  unfold executeZeroAlloc LidoSRv3.Audit.AllocCapacity.execute
  cases hFirst : firstLoop cfg modules deposits with
  | none => simp
  | some result =>
      rcases result with ⟨entries, total⟩
      simp [secondLoopZeroAlloc_eq]

/-- **The registered abstract parent tolerates a wrong allocation column.**
`PAlloc1.checked_execute`'s exact shape holds for `executeZeroAlloc`, because
the parent compares only `rows.map Row.capacity` against `MathView.capacities`.
-/
theorem zero_allocation_column_mutant_survives_registered_parent
    (cfg : Config) (modules : List Module) (deposits : Uint256) (isTopUp : Bool)
    (hBounds : CheckedBounds cfg modules deposits isTopUp) :
    ∃ rows, executeZeroAlloc cfg modules deposits isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules deposits isTopUp := by
  obtain ⟨rows, hExec, hCaps⟩ :=
    LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute cfg modules deposits isTopUp hBounds
  have hE : LidoSRv3.Audit.AllocCapacity.execute cfg modules deposits isTopUp =
      some rows := hExec
  refine ⟨rows.map zeroAlloc, ?_, ?_⟩
  · rw [executeZeroAlloc_eq, hE]
    rfl
  · rw [← hCaps]
    simp [zeroAlloc]

/-- The tolerated mutant really is wrong: on the kill-line witness the honest
allocation column is `[10, 10]` and the mutant's is `[0, 0]`. -/
theorem zero_allocation_column_is_observably_wrong :
    ((LidoSRv3.Audit.SolidityAllocCapacity.execute cfg
        (killModules.map toSourceModule) (w 10) false).map
      (fun rows => rows.map Row.currentAllocation)) = some [w 10, w 10] ∧
    ((executeZeroAlloc cfg (killModules.map toSourceModule) (w 10) false).map
      (fun rows => rows.map Row.currentAllocation)) = some [w 0, w 0] := by
  native_decide

end LidoSRv3.Tests.Alloc1AuditProbe
