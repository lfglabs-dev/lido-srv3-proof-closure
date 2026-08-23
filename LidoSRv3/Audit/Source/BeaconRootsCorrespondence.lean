import LidoSRv3.Audit.Spec.Eip4788AnchorChild

/-!
# EIP-4788 BEACON_ROOTS source correspondence

This source-shaped layer represents the paired timestamp/root cells read by
the EIP-4788 system contract. It models the contract's ring-buffer lookup;
it is not a deployed-address or bytecode-identity claim.
-/

namespace LidoSRv3.Audit.Source.BeaconRootsCorrespondence

open LidoSRv3.Audit.Spec.Eip4788AnchorChild

/-- Source-shaped paired storage cell. -/
structure StoredBeaconRoot where
  timestampWord : Nat
  rootWord : Nat
  deriving DecidableEq, Repr

/-- Source-shaped storage snapshot. A short list is a sparse snapshot and
therefore fails closed for missing ring-buffer cells. -/
structure BeaconRootsStorage where
  cells : List StoredBeaconRoot
  deriving DecidableEq, Repr

/-- Project source-shaped storage into the Spec history representation. -/
def toSpecHistory (storage : BeaconRootsStorage) : BeaconRootsHistory where
  slots := storage.cells.map fun cell =>
    { timestamp := cell.timestampWord, parentRoot := cell.rootWord }

/-- Source-shaped read: reject zero, select `timestamp % 8191`, validate the
stored timestamp, and return the paired root. -/
def sourceBeaconRootsRead (storage : BeaconRootsStorage) (timestamp : Nat) :
    Option Nat :=
  if timestamp = 0 then none
  else
    match storage.cells[timestamp % historyBufferLength]? with
    | none => none
    | some cell =>
        if cell.timestampWord = timestamp then some cell.rootWord else none

/-- Universal Source→Spec correspondence for the modeled EIP-4788 read. -/
theorem source_beacon_roots_matches_spec
    (storage : BeaconRootsStorage) (timestamp : Nat) :
    sourceBeaconRootsRead storage timestamp =
      eip4788ParentRoot (toSpecHistory storage) timestamp := by
  by_cases hZero : timestamp = 0
  · subst timestamp
    simp [sourceBeaconRootsRead, eip4788ParentRoot, beaconRootsLookup]
  · simp only [sourceBeaconRootsRead, eip4788ParentRoot, beaconRootsLookup,
      hZero, ↓reduceIte, toSpecHistory]
    rw [List.getElem?_map]
    cases hCell : storage.cells[timestamp % historyBufferLength]? with
    | none => simp
    | some cell =>
        by_cases hTimestamp : cell.timestampWord = timestamp
        · simp [hTimestamp]
        · simp [hTimestamp]

end LidoSRv3.Audit.Source.BeaconRootsCorrespondence
