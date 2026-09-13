/-! # TopUpGateway prefix-guard source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
TopUpGateway prefix guards D-AUTH-1, D-SORT-1, D-WC-1, D-PUBKEY-1,
D-MAX-1 as source-level functions.)**

Chantier: grok differential #417 flags D-AUTH-1, D-SORT-1, D-WC-1,
D-PUBKEY-1, D-MAX-1 — the TopUpGateway's live prefix guards
(caller-role, indices-sorted, WC-type, pubkey-length, max-validators)
are only modeled as array shapes on the Verity plane, not as
executable guards.

This composition names each pinned prefix guard as a source-level
function:

- `callerHasTopUpRole` (D-AUTH-1): caller has the top-up role.
- `indicesSorted` (D-SORT-1): the indices array is strictly increasing.
- `wcIsType2` (D-WC-1): the withdrawal-credentials type byte is 2.
- `pubkeyLengthOk` (D-PUBKEY-1): all pubkeys are 48 bytes.
- `validatorCountAtMost` (D-MAX-1): validator count ≤ maxValidators.

**Status:** first real derivation naming the five #417 prefix-guard
divergences as source-level functions. -/

namespace LidoSRv3.Audit.Source.Topup2PrefixGuardsSource

/-- D-AUTH-1: pinned caller-role check as source-level function. -/
def callerHasTopUpRole (caller topUpRoleAddress : Nat) : Bool :=
  decide (caller = topUpRoleAddress)

theorem callerHasTopUpRole_true_of_eq
    {caller topUpRoleAddress : Nat} (hEq : caller = topUpRoleAddress) :
    callerHasTopUpRole caller topUpRoleAddress = true := by
  simp [callerHasTopUpRole, hEq]

/-- D-SORT-1: source-level strictly-increasing check on a Nat list. -/
def indicesSorted : List Nat → Bool
  | [] => true
  | [_] => true
  | x :: y :: rest => decide (x < y) && indicesSorted (y :: rest)

theorem indicesSorted_true_of_singleton (i : Nat) :
    indicesSorted [i] = true := by
  simp [indicesSorted]

theorem indicesSorted_true_of_empty :
    indicesSorted [] = true := by
  simp [indicesSorted]

/-- D-WC-1: withdrawal-credentials type-2 byte constant. -/
def wcType2Byte : Nat := 2

def wcIsType2 (wcTypeByte : Nat) : Bool :=
  decide (wcTypeByte = wcType2Byte)

theorem wcIsType2_true_of_eq
    {wcTypeByte : Nat} (hEq : wcTypeByte = wcType2Byte) :
    wcIsType2 wcTypeByte = true := by
  simp [wcIsType2, hEq]

/-- D-PUBKEY-1: pinned 48-byte pubkey length constant. -/
def pubkeyByteLength : Nat := 48

/-- Source-level definition of the pinned pubkey-length check for a
list of pubkey-length values. -/
def pubkeyLengthOk : List Nat → Bool
  | [] => true
  | len :: rest =>
    decide (len = pubkeyByteLength) && pubkeyLengthOk rest

theorem pubkeyLengthOk_true_of_empty :
    pubkeyLengthOk [] = true := by
  simp [pubkeyLengthOk]

/-- D-MAX-1: source-level definition of the pinned max-validators
check: `validatorCount ≤ maxValidators`. -/
def validatorCountAtMost (validatorCount maxValidators : Nat) : Bool :=
  decide (validatorCount ≤ maxValidators)

theorem validatorCountAtMost_true_of_le
    {validatorCount maxValidators : Nat}
    (hLe : validatorCount ≤ maxValidators) :
    validatorCountAtMost validatorCount maxValidators = true := by
  simp [validatorCountAtMost, hLe]

end LidoSRv3.Audit.Source.Topup2PrefixGuardsSource
