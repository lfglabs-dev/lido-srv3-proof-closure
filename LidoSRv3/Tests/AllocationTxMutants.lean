import LidoSRv3.Audit.Verity.AllocationTx

/-! P-ALLOC-1 faithful-plane fail-closed vectors: wrong-module-binding,
off-by-one, stale-snapshot, two-batch chaining, and rollback. -/

namespace LidoSRv3.Tests.AllocationTxMutants

open Verity
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.Verity.AllocationTx

private def w (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def cfg : Config := ⟨w 32, w 64⟩

/-- Two active type-1 modules with distinct ids and addresses. `stateFor`
packs each router config into one word; summary maps support only the legacy
free-count sibling tests below. -/
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

private def runView (ms : List BoundModule) (deposits : Word) (isTopUp : Bool) : View :=
  let before := stateFor ms
  observe ms ((allocate ms.length cfg deposits isTopUp).run before)

/-- Positive: two-module first loop accumulates `totalValidators = 10 + 10 + 10`
and both capacities clamp to the shared target 15. -/
example :
    runView modules (w 10) false =
      ⟨.committed, [w 10, w 10], [w 15, w 15], [w 17, w 18], w 30⟩ := by
  native_decide

/-- Off-by-one mutant: dropping the last router index loses the second
address and changes the accumulated total / targets. -/
example :
    let before := stateFor modules
    observe [modA] ((allocate 1 cfg (w 10) false).run before) ≠
      runView modules (w 10) false := by
  native_decide

/-- Wrong-module-binding mutant: look up summaries by module id, skipping
`getIStakingModule`. Summaries live only at the bound addresses, so the
mutant sees zero depositable/deposited words. -/
def wrongBindOne (state : ContractState) (index : Nat) : BoundModule :=
  let moduleId := state.readMapUint moduleIdSlot index
  let packed := state.readMapUint moduleConfigSlot moduleId
  { moduleId := moduleId
    moduleAddress := configModuleAddress packed
    shareLimit := configShareLimit packed
    isActive := configStatus packed == 0
    isType2 := configWcType packed == 2
    accountingExitedCount := state.readMapUint accountingExitedSlot moduleId
    depositableCount := state.readMapUint summaryDepositableSlot moduleId
    depositedCount := state.readMapUint summaryDepositedSlot moduleId
    summaryExitedCount := state.readMapUint summaryExitedSlot moduleId
    totalModuleStake := state.readMapUint summaryStakeSlot moduleId }

def wrongBindView (ms : List BoundModule) (deposits : Word) : View :=
  let state := stateFor ms
  let bound := (List.range ms.length).map (wrongBindOne state)
  sourceView cfg bound deposits false

example : wrongBindView modules (w 10) ≠ runView modules (w 10) false := by
  native_decide

/-- Packed-config positive control: address/share/status/WC are recovered from
one `ModuleStateConfig` word rather than independent maps. -/
example :
    configModuleAddress (packConfig modA) = modA.moduleAddress ∧
    configShareLimit (packConfig modA) = modA.shareLimit ∧
    configStatus (packConfig modA) = 0 ∧
    configWcType (packConfig modA) = 1 := by
  native_decide

private def summaryBytes (exited deposited depositable : Nat) : List Nat :=
  List.replicate 31 0 ++ [exited] ++
  List.replicate 31 0 ++ [deposited] ++
  List.replicate 31 0 ++ [depositable]

/-- Decoder mutant: swap the first two ABI return words. -/
private def decodeSummarySwapped (data : List Nat) : Option DecodedSummary :=
  if 96 ≤ data.length then
    some
      { exitedCount := decodeUint256At data 32
        depositedCount := decodeUint256At data 0
        depositableCount := decodeUint256At data 64 }
  else none

/-- Kill-line for the newly live summary boundary. The pinned interface order
is `(exited, deposited, depositable)`; swapping exited/deposited changes the
`BoundModule` fields consumed by the allocation loop. -/
theorem summary_field_order_kill_line_refutes_decoder :
    decodeSummary (summaryBytes 1 2 3) =
      some ⟨w 1, w 2, w 3⟩ ∧
    decodeSummarySwapped (summaryBytes 1 2 3) ≠
      some ⟨w 1, w 2, w 3⟩ := by
  native_decide

/-- The WC02 stake boundary has a separate selector and one-word ABI shape;
using the summary selector or accepting a short return cannot stand in for it. -/
theorem type2_total_stake_boundary_rejects_summary_substitution :
    totalStakeSelector = 0x0c852f5c ∧
    totalStakeCalldata = [0x0c, 0x85, 0x2f, 0x5c] ∧
    totalStakeCalldata ≠ [0x9a, 0xbd, 0xdf, 0x09] ∧
    decodeTotalStake (List.replicate 31 0 ++ [7]) = some (w 7) ∧
    decodeTotalStake (List.replicate 31 0) = none := by
  native_decide

/-- A WC02 row cannot be admitted on the summary result alone: malformed
`getTotalModuleStake` returndata reverts the whole binding transaction. -/
private def malformedStakeAdversary :
    Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel :=
  { stateTransition := fun _ world => world
    result := fun site _ =>
      if site.siteId = 0 then .success (List.replicate 96 0) else .success (List.replicate 31 0)
    gasUsed := fun _ _ => 0 }

private def type2Module : BoundModule := { modA with isType2 := true }
private def type2State : ContractState := stateFor [type2Module]

#guard match (bindLiveOne malformedStakeAdversary type2State 0) type2State with
  | .revert "TotalModuleStakeMalformedReturn" rollback =>
      rollback.sender == type2State.sender &&
      rollback.readMapUint moduleIdSlot 0 == type2State.readMapUint moduleIdSlot 0 &&
      rollback.readMapUint moduleConfigSlot (w 7) == type2State.readMapUint moduleConfigSlot (w 7)
  | _ => false

/-- Stale-snapshot mutant: after rebinding module 7 from address 17 to 19,
the live transaction must observe the new address's summary. A snapshot
taken before the rebind still reports address 17. -/
private def rebound : BoundModule :=
  { modA with moduleAddress := w 19, depositableCount := w 4, depositedCount := w 20 }

example :
    let live := stateFor [rebound, modB]
    let stale := stateFor [modA, modB]
    observe [rebound, modB] ((allocate 2 cfg (w 10) false).run live) ≠
      observe [modA, modB] ((allocate 2 cfg (w 10) false).run stale) := by
  native_decide

/-- Two-batch chaining: a second allocation batch on the same bound modules
with a larger deposit demand raises both targets. A mutant that reuses the
first batch's capacities is rejected. -/
example :
    let first := runView modules (w 10) false
    let second := runView modules (w 30) false
    first = ⟨.committed, [w 10, w 10], [w 15, w 15], [w 17, w 18], w 30⟩ ∧
      second = ⟨.committed, [w 10, w 10], [w 25, w 25], [w 17, w 18], w 50⟩ ∧
      first.capacities ≠ second.capacities := by
  native_decide

/-- Independent-batch mutant: reset `totalValidators` per module instead of
accumulating across the allocation loop. Each module then sees total 20
and target 10, so capacities collapse to current allocation. -/
private def independentBatchView : View :=
  let oneA := runView [modA] (w 10) false
  let oneB := runView [modB] (w 10) false
  ⟨.committed, oneA.allocations ++ oneB.allocations,
    oneA.capacities ++ oneB.capacities,
    oneA.moduleAddresses ++ oneB.moduleAddresses,
    w 20⟩

example : independentBatchView ≠ runView modules (w 10) false := by
  native_decide

/-- Failure after allocation, capacity, address, and total writes is rolled
back by `Contract.run`, not merely hidden by the observation. -/
example :
    let before := stateFor modules
    (allocate 2 cfg (w 10) false true).run before =
      .revert "INJECTED_AFTER_WRITES" before := by
  rfl

/-- Write-noop mutant: a success that skips `persistRows` disagrees with
`observe`, which reads the storage arrays. -/
private def allocateNoWrite (count : Nat) (cfg : Config) (deposits : Word)
    (isTopUp : Bool) : Contract Result :=
  fun snapshot =>
    let modules := sourceBindAll snapshot count
    match sourceExecute cfg modules deposits isTopUp with
    | none => .revert "ALLOC_ARITHMETIC" snapshot
    | some (rows, total) =>
        .success ⟨rows.map Row.currentAllocation, rows.map Row.capacity,
          modules.map BoundModule.moduleAddress, total⟩ snapshot

example :
    let before := stateFor modules
    observe modules ((allocateNoWrite modules.length cfg (w 10) false).run
      before) ≠ sourceView cfg modules (w 10) false := by
  native_decide

/-- Kill-line mutant: `capacity := target` instead of `wordMin target available`.
The mutant executor disagrees with `MathView.capacities`, which uses `min`. -/
private def secondLoopMutant (cfg' : Config) (isTopUp : Bool) (total : Verity.Core.Uint256) :
    List Module → List (Verity.Core.Uint256 × Verity.Core.Uint256) → Option (List Row)
  | [], [] => some []
  | m :: ms, entry :: entries => do
      let (allocation, active) := entry
      if m.isActive then
        let _available ← availableCapacity? cfg' isTopUp m allocation active
        let target ← targetValidators? total m
        let rows ← secondLoopMutant cfg' isTopUp total ms entries
        pure (({
          moduleId := m.moduleId
          currentAllocation := allocation
          capacity := target
          targetValidators := target
          activeCount := active
        } : Row) :: rows)
      else
        let rows ← secondLoopMutant cfg' isTopUp total ms entries
        pure (({
          moduleId := m.moduleId
          currentAllocation := allocation
          capacity := allocation
          targetValidators := 0
          activeCount := active
        } : Row) :: rows)
  | _, _ => none

private def executeMutant (cfg' : Config) (modules' : List Module)
    (deposits : Verity.Core.Uint256) (isTopUp : Bool) : Option (List Row) := do
  let (entries, total) ← firstLoop cfg' modules' deposits
  secondLoopMutant cfg' isTopUp total modules' entries

private def killLineModules : List Module :=
  [ { moduleId := w 1, shareLimit := w 8000, isActive := true, isType2 := false
      depositableCount := w 1, depositedCount := w 10
      summaryExitedCount := w 0, accountingExitedCount := w 0
      totalModuleStake := w 0 }
  , { moduleId := w 2, shareLimit := w 8000, isActive := true, isType2 := false
      depositableCount := w 1, depositedCount := w 10
      summaryExitedCount := w 0, accountingExitedCount := w 0
      totalModuleStake := w 0 } ]

/-- **Kill-line for the registered P-ALLOC-1 parent.**  The registered parent
`LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute` claims, under
`CheckedBounds`, that the executor succeeds and its capacity column equals
`MathView.capacities`.  This theorem is the explicit negation of that
predicate shape with the mutant executor `executeMutant` (`capacity :=
target`, skipping the `wordMin` clamp against available headroom) substituted
for `SolidityAllocCapacity.execute`: at the `killLineModules` witness
`CheckedBounds` holds, the mutant *commits* a row list, and its capacity
column `[24, 24]` -- the raw share-limit targets -- differs from
`MathView.capacities`' `[11, 11]`, each clamped to the available headroom
`10 + 1`.  `PAlloc1.checked_execute` is Wave 2's narrowed parent: it no
longer conjoins the `active_capacity_bounded` `Nat.min` tautology (P-ALLOC-1
audit issue 1), so this kill-line is checked against the parent's entire
(now purely executable) statement, not half of it. -/
theorem capacity_target_kill_line_refutes_parent :
    CheckedBounds cfg killLineModules (w 10) false ∧
      (∃ rows, executeMutant cfg killLineModules (w 10) false = some rows) ∧
        (executeMutant cfg killLineModules (w 10) false).map (fun rows =>
          rows.map (fun r => (r.capacity : Nat))) ≠
        some (MathView.capacities cfg killLineModules (w 10) false) := by
  refine ⟨⟨by decide, by decide, by decide, by decide, by decide⟩, ⟨_, rfl⟩,
    by decide⟩

end LidoSRv3.Tests.AllocationTxMutants
