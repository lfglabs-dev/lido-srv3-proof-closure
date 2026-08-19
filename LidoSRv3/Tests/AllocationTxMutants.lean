import LidoSRv3.Audit.Verity.AllocationTx

/-! P-ALLOC-1 faithful-plane fail-closed vectors: wrong-module-binding,
off-by-one, stale-snapshot, two-batch chaining, and rollback. -/

namespace LidoSRv3.Tests.AllocationTxMutants

open Verity
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.Verity.AllocationTx

private def w (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def cfg : Config := ⟨w 32, w 64⟩

/-- Two active type-1 modules with distinct ids and addresses. Summaries live
only at the bound addresses. -/
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
  { moduleId := moduleId
    moduleAddress := state.readMapUint moduleAddressSlot moduleId
    shareLimit := state.readMapUint shareLimitSlot moduleId
    isActive := state.readMapUint statusSlot moduleId == 0
    isType2 := state.readMapUint wcTypeSlot moduleId == 2
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

end LidoSRv3.Tests.AllocationTxMutants
