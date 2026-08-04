import LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound

namespace LidoSRv3.Tests.PAlloc1EugeneBoundVectors

open Verity
open LidoSRv3.Audit.MinFirstAllocation

private def word (n : Nat) : Uint256 := Verity.Core.Uint256.ofNat n

private def selected : Source.Row := ⟨word 10, word 13⟩
private def rows : List Source.Row := [selected, ⟨word 20, word 40⟩]

/-- Capacity headroom binds before the available reward demand. -/
example : Source.checkedAmount rows (word 8) selected = some (word 3) := by decide

/-- The plausible mutant that returns the uncapped reward demand is rejected. -/
example : Source.checkedAmount rows (word 8) selected ≠ some (word 8) := by decide

/-- A smaller per-block demand remains below the configured bond. -/
example : Source.checkedAmount rows (word 2) selected = some (word 2) := by decide

end LidoSRv3.Tests.PAlloc1EugeneBoundVectors
