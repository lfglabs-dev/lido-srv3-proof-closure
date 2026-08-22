import LidoSRv3.Audit.Spec.Eip4788AnchorChild

/-!
# Pack W2-EIP4788 fail-closed vectors

A mutant that drops the age bound accepts a stale timestamp the honest
`ageCheck` rejects. This does not inhabit EIP-4788 parent-root lookup,
live `SSZ.verifyProof`, or SHA.
-/

namespace LidoSRv3.Tests.PackW2Eip4788Mutants

open LidoSRv3.Audit.Spec.Eip4788AnchorChild

/-- Mutant: only `ts ≤ now`. Drops `now − ts ≤ maxRootAge`. -/
def ageCheckSkipAgeBound (a : ParentRootAnchor) : Bool :=
  decide (a.beaconRootTimestamp ≤ a.currentTimestamp)

/-- Kill-line: on `⟨0, 100, 1⟩` the mutant accepts (0 ≤ 100) while honest
`ageCheck` is false (age 100 exceeds `maxRootAge` 1). -/
theorem skip_age_bound_kill_line :
    ageCheckSkipAgeBound ⟨0, 100, 1⟩ = true ∧
      ageCheck ⟨0, 100, 1⟩ = false := by
  decide

end LidoSRv3.Tests.PackW2Eip4788Mutants
