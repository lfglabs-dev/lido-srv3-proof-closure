import LidoSRv3.Audit.Model.AllocCapacity

/-!
Pinned checked-`uint256` semantics and independent Audit-model correspondence
for `SRLib._getModulesAllocationAndCapacity` at Lido core
`17005714f151e5502c559932319a3f2f74ac2436`, `SRLib.sol:493--559`.

`AllocCapacity.execute` is the single source-shaped interpreter: its first and
second loops follow `SRLib.sol:506-533` and `SRLib.sol:539-558` and use Verity
`safe*` operations for Solidity checked arithmetic.  The independent Audit model is
`AllocCapacity.MathView.capacities`: a direct `List.map` over unbounded natural
number equations.  It has no executor, loop state, `Option`, or `safe*`
operations.

The theorem below is therefore deliberately not an equality between two
programs.  Under the explicitly named checked-arithmetic bounds it proves that
the source interpreter succeeds and that the returned capacity column equals
the independently defined Audit model.  Array allocation, storage and external
call success remain source-boundary assumptions; TX and EVM correspondence are
not claimed here.
-/

namespace LidoSRv3.Audit.SolidityAllocCapacity

open Verity
open LidoSRv3.Audit.AllocCapacity

abbrev SourceModule := AllocCapacity.Module
abbrev SourceConfig := AllocCapacity.Config

/-! ## SRLib._getModulesAllocationAndCapacity (SRLib.sol:493-559) -/

/-- The already checked, source-shaped semantics.  This name is an API export,
not a second implementation. -/
def execute := AllocCapacity.execute

/-- Solidity-facing name, `SRLib.sol:493`. Proofs use `execute`. -/
abbrev _getModulesAllocationAndCapacity := execute

/-- Non-definitional correspondence from checked source execution to the
minimal independent Audit model.  The assumptions are exactly `CheckedBounds`:
nonzero type-1 effective balance, no active-count subtraction underflow, and no
overflow in total, available-capacity, or target multiplication. -/
theorem source_execute_refines_audit_model
    (cfg : SourceConfig) (modules : List SourceModule)
    (depositsToAllocate : Uint256) (isTopUp : Bool)
    (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp) :
    ∃ rows, execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp := by
  exact AllocCapacity.execute_refines_math cfg modules depositsToAllocate isTopUp hBounds

/-- Successful checked source execution preserves router order. -/
theorem router_order_preserved {cfg : SourceConfig} {modules : List SourceModule}
    {depositsToAllocate : Uint256} {isTopUp : Bool} {rows : List AllocCapacity.Row}
    (h : execute cfg modules depositsToAllocate isTopUp = some rows) :
    rows.map AllocCapacity.Row.moduleId = modules.map AllocCapacity.Module.moduleId := by
  simp only [execute] at h
  simp only [AllocCapacity.execute] at h
  cases hFirst : AllocCapacity.firstLoop cfg modules depositsToAllocate with
  | none => simp [hFirst] at h
  | some result =>
      obtain ⟨entries, total⟩ := result
      simp [hFirst] at h
      exact AllocCapacity.secondLoop_router_order h

end LidoSRv3.Audit.SolidityAllocCapacity
