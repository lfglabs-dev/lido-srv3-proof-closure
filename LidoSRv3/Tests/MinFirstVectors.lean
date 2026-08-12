import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Guarantees.PAlloc2

namespace LidoSRv3.Tests.MinFirstVectors

open LidoSRv3.Audit
open LidoSRv3.Audit.MinFirst

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n
private def b (id allocation capacity : Nat) (active := true)
    (credentialType := CredentialType.wc02) : Bucket :=
  ⟨word id, active, credentialType, allocation, capacity⟩

example : candidate? [b 0 5 10, b 1 0 10] = some (b 1 0 10) := by decide
/- A later, fuller bucket is a plausible broken MinFirst choice and is rejected. -/
example : candidate? [b 0 0 10, b 1 2 10] ≠ some (b 1 2 10) := by decide
example : candidate? [b 0 0 10, b 1 0 10] = some (b 0 0 10) := by decide
example : candidate? [b 0 10 10, b 1 1 10] = some (b 1 1 10) := by decide
example : candidate? [b 0 0 10 false, b 1 1 10] = some (b 1 1 10) := by decide
example : candidate? [b 0 0 10 true .wc01, b 1 1 10] = some (b 0 0 10 true .wc01) := by decide
example : allocate 1 [b 0 11 10, b 1 0 1] = [b 0 11 10, b 1 1 1] := by decide
example : allocate 3 [b 0 0 1, b 1 0 1] = [b 0 1 1, b 1 1 1] := by decide
example :
    allocate 1 [b 0 0 10, b 1 0 10] = [b 0 1 10, b 1 0 10] ∧
    allocate 1 [b 1 0 10, b 0 0 10] = [b 1 1 10, b 0 0 10] := by decide

/- Full proportional-amount vectors for the pinned Solidity example.  These
reject unit-step, missing-next-level-cap, and last-equal-candidate mutants. -/
private def fullRows : List MinFirstAllocation.Model.Bucket :=
  [⟨9998, 10000⟩, ⟨70, 101⟩, ⟨0, 100⟩]

example :
    MinFirstAllocation.Model.candidate? fullRows = some ⟨0, 100⟩ ∧
    MinFirstAllocation.Model.amount fullRows 101 ⟨0, 100⟩ = 70 := by decide

private def equalRows : List MinFirstAllocation.Model.Bucket :=
  [⟨9998, 10000⟩, ⟨70, 101⟩, ⟨70, 100⟩]

example :
    MinFirstAllocation.Model.candidate? equalRows = some ⟨70, 101⟩ ∧
    MinFirstAllocation.Model.amount equalRows 31 ⟨70, 101⟩ = 16 := by decide

private def sourceRows : List MinFirstAllocation.Source.Row :=
  [⟨word 9998, word 10000⟩, ⟨word 70, word 101⟩, ⟨word 0, word 100⟩]

example :
    MinFirstAllocation.Source.checkedAmount sourceRows (word 101) ⟨word 0, word 100⟩ =
      some (word 70) := by decide

end LidoSRv3.Tests.MinFirstVectors
