import LidoSRv3.Audit.Source.BeaconRootsCorrespondence

/-!
# EIP-4788 BEACON_ROOTS Verity transaction model

This module executes the modeled system-contract read over the source-shaped
storage snapshot. It establishes the Verity→Source leg used by the live-SSZ
consume parent. It does not identify deployed bytecode or an execution-layer
address.
-/

namespace LidoSRv3.Audit.Verity.BeaconRootsTx

open LidoSRv3.Audit.Spec.Eip4788AnchorChild
open LidoSRv3.Audit.Source.BeaconRootsCorrespondence

/-- Inputs observed by the modeled BEACON_ROOTS read transaction. -/
structure ReadInput where
  storage : BeaconRootsStorage
  timestamp : Nat
  deriving DecidableEq, Repr

/-- Verity-plane execution of the EIP-4788 read guards and ring lookup. -/
def executeRead (input : ReadInput) : Option Nat :=
  if input.timestamp = 0 then none
  else
    match input.storage.cells[input.timestamp % historyBufferLength]? with
    | none => none
    | some cell =>
        if cell.timestampWord = input.timestamp then some cell.rootWord else none

/-- Universal Verity→Source correspondence for the modeled read transaction. -/
theorem execute_read_matches_source (input : ReadInput) :
    executeRead input =
      sourceBeaconRootsRead input.storage input.timestamp := by
  rfl

/-- Spec→Source→Verity chain for every modeled storage snapshot and timestamp. -/
theorem spec_source_verity_beacon_roots
    (storage : BeaconRootsStorage) (timestamp : Nat) :
    eip4788ParentRoot (toSpecHistory storage) timestamp =
        sourceBeaconRootsRead storage timestamp ∧
      sourceBeaconRootsRead storage timestamp =
        executeRead ⟨storage, timestamp⟩ := by
  exact ⟨(source_beacon_roots_matches_spec storage timestamp).symm,
    (execute_read_matches_source ⟨storage, timestamp⟩).symm⟩

end LidoSRv3.Audit.Verity.BeaconRootsTx
