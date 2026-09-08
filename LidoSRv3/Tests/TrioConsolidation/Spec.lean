import audit.trio.consolidation.Spec

namespace LidoSRv3.Tests.TrioConsolidation.Spec

open audit.trio.consolidation

private def key (id length : Nat := 48) : Pubkey := ⟨id, length⟩

example : validateBusAdd 4 2
    [⟨[key 11, key 12], key 21⟩, ⟨[key 13], key 22⟩] = .ok 3 := by
  rfl

example : validateBusAdd 4 2 [⟨[], key 21⟩] = .error (.emptyGroup 0) := by
  rfl

/-- The batch-size guard precedes public-key validation in the pinned bus. -/
example : validateBusAdd 1 2 [⟨[key 11, key 12 47], key 21⟩] =
    .error (.batchTooLarge 2 1) := by
  rfl

/-- Within key validation, target length precedes source length. -/
example : validateBusAdd 2 2 [⟨[key 11 47], key 21 47⟩] =
    .error (.invalidTargetLength 0 47) := by
  rfl

private def witnesses : List WitnessGroup :=
  [⟨[key 11, key 12], key 21⟩, ⟨[key 13], key 22⟩]

example : preparePairs witnesses =
    [(key 11, key 21), (key 12, key 21), (key 13, key 22)] := by
  rfl

example : preparedSources witnesses = [key 11, key 12, key 13] := by rfl

example : preparedTargets witnesses = [key 21, key 21, key 22] := by rfl

example : (preparedSources witnesses).zip (preparedTargets witnesses) =
    preparePairs witnesses := prepared_zip witnesses

example : validateVaultAdd (word 3) (word 9)
    [key 11, key 12, key 13] [key 21, key 21, key 22] =
    .ok [(key 11, key 21), (key 12, key 21), (key 13, key 22)] := by
  rfl

example : validateVaultAdd (word 3) (word 9)
    (preparedSources witnesses) (preparedTargets witnesses) =
    .ok (preparePairs witnesses) := by
  apply validateVaultAdd_prepared
  · decide
  · decide
  · decide
  · rfl

/-- Exact fee is checked before the vault loop validates key lengths. -/
example : validateVaultAdd (word 3) (word 5) [key 11 47] [key 21] =
    .error (.incorrectFee (word 3) (word 5)) := by
  rfl

example : validateVaultAdd (word 3) (word 3) [key 11 47] [key 21] =
    .error (.invalidSourceLength 0 47) := by
  rfl

end LidoSRv3.Tests.TrioConsolidation.Spec
