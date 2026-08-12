import LidoSRv3.Audit.Verity.AddressYulInterface

namespace LidoSRv3.Tests.AddressYulInterface

open Verity
open LidoSRv3.Audit
open LidoSRv3.Audit.AddressEquivariance
open LidoSRv3.Audit.Verity.AddressYulInterface

private def identityRenaming : Renaming :=
  { apply := id, injective := Function.injective_id }

private def swapRenaming (left right : Address) : Renaming :=
  { apply := Equiv.swap left right
    injective := (Equiv.swap left right).injective }

private def revertedAt (target : Address) : TxObservation Unit :=
  ⟨(), [⟨target, Quantity.zero, 0⟩], .reverted⟩

private def vector (word : Nat) (rho : Renaming) (target : Address) :
    HarnessVector Unit :=
  { addressWord := EvmYul.UInt256.ofNat word
    rho := rho
    renameState := id
    before := revertedAt target
    after := renameObservation rho id (revertedAt target) }

/-- Identity vector: the four-operation interface builds and relates to itself. -/
theorem identity_vector :
    Builds (vector 1 identityRenaming 1) ∧
      RespectsAbstractRename (vector 1 identityRenaming 1) := by
  exact mutant_sensitive_harness Unit identityRenaming id (revertedAt 1)
    (EvmYul.UInt256.ofNat 1)

/-- Identity program plus a nontrivial address rename. -/
theorem identity_plus_rename_vector :
    Builds (vector 1 (swapRenaming 1 2) 1) ∧
      RespectsAbstractRename (vector 1 (swapRenaming 1 2) 1) := by
  exact mutant_sensitive_harness Unit (swapRenaming 1 2) id (revertedAt 1)
    (EvmYul.UInt256.ofNat 1)

/-- A different 20-byte address word still builds the same typed interface. -/
theorem address_stomp_build_vector :
    Builds (vector 2 identityRenaming 2) := by
  rfl

/-- All-zero calldata/address bytes remain a valid syntax build vector. -/
theorem zero_bytes_vector :
    Builds (vector 0 identityRenaming 0) ∧
      RespectsAbstractRename (vector 0 identityRenaming 0) := by
  exact mutant_sensitive_harness Unit identityRenaming id (revertedAt 0)
    (EvmYul.UInt256.ofNat 0)

/-- Guard regression: all four typed operations are present. -/
theorem four_builtin_guard : (addressProgram (EvmYul.UInt256.ofNat 1)).length = 4 := by
  rfl

/--
Mutant sensitivity: stomping the expected renamed target from address 2 to the
different 20-byte address 3 cannot satisfy the abstract renaming relation.
-/
theorem rejects_address_stomp_mutant :
    ¬ Equivariant (swapRenaming 1 2) id (revertedAt 1) (revertedAt 3) := by
  intro h
  have attempts := congrArg TxObservation.attemptedCalls h
  simp [renameObservation, revertedAt, renameCall, swapRenaming] at attempts
  exact (by decide : (3 : Address) ≠ 2) attempts

end LidoSRv3.Tests.AddressYulInterface
