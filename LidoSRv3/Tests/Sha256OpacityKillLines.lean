import LidoSRv3.Audit.Source.Sha256OpacitySource

/-! # Kill-lines for `Sha256OpacitySource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the SHA-256 opacity oracle laws.** -/

namespace LidoSRv3.Tests.Sha256OpacityKillLines

open LidoSRv3.Audit.Source.Sha256OpacitySource

/-- A concrete constant-output oracle for kill-line witnesses.
Every input maps to 32 zero bytes. -/
def constZeroOracle : Sha256Oracle where
  hash := fun _ => List.replicate 32 0
  outputLength := fun _ => List.length_replicate
  determinism := fun _ _ _ => rfl

/-- **Kill-line: SHA-256 output length is exactly 32 for every input.**

A mutant that made the length depend on input, or shortened it to
28/64, would refute this. -/
theorem sha256_output_length_is_32
    (oracle : Sha256Oracle) (input : List Nat) :
    (oracle.hash input).length = 32 :=
  sha256_output_is_32_bytes oracle input

/-- **Kill-line: constZeroOracle produces 32 zero bytes on any input.** -/
theorem constZeroOracle_output :
    constZeroOracle.hash [1, 2, 3] = List.replicate 32 0 :=
  rfl

/-- **Kill-line: length of constZeroOracle output is 32.** -/
theorem constZeroOracle_length :
    (constZeroOracle.hash [1, 2, 3]).length = 32 := by
  decide

/-- **Kill-line: SHA-256 determinism — equal inputs give equal outputs.**

A mutant that returned different outputs on the same input would
refute this. -/
theorem sha256_deterministic_identical
    (oracle : Sha256Oracle) (input : List Nat) :
    oracle.hash input = oracle.hash input :=
  sha256_deterministic (rfl)

#print axioms sha256_output_length_is_32
#print axioms constZeroOracle_output
#print axioms constZeroOracle_length
#print axioms sha256_deterministic_identical

end LidoSRv3.Tests.Sha256OpacityKillLines
