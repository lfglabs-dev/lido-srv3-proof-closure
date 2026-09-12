import audit.trio.consolidation.Spec

namespace LidoSRv3.Tests.TrioConsolidation.Spec

open audit.trio.consolidation

private def key (id length : Nat := 48) : Pubkey := ⟨id, length⟩
private def wrapKey (id : Nat) : Pubkey := ⟨id + pubkeyModulus, 48⟩

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

/-- Unrestricted integer encoding wraps at `2^384`. -/
example : integerBE pubkeyLength 1 =
    integerBE pubkeyLength (1 + pubkeyModulus) := integerBE48_collides_unbounded

/-- Actual 48-byte representation refuses the wrapping identity, so distinct
identities do not encode to the same 48 bytes. -/
example : pubkeyOctets (key 1) = some (integerBE pubkeyLength 1) := by
  native_decide

example : pubkeyOctets (wrapKey 1) = none := by
  native_decide

example : pubkeyOctets (key 1) ≠ pubkeyOctets (wrapKey 1) := by
  native_decide

example : pubkeyOctets (key 1) ≠ pubkeyOctets (key 2) := by
  native_decide

example : encodePackedRequest (key 11) (key 21) =
    some (integerBE 48 11 ++ integerBE 48 21) := by
  native_decide

example : (encodePackedRequest (key 11) (key 21)).map List.length = some 96 := by
  native_decide

/-- Length-47 keys have no 48-byte representation, even with a small identity. -/
example : pubkeyOctets (key 11 47) = none := by
  native_decide

end LidoSRv3.Tests.TrioConsolidation.Spec
