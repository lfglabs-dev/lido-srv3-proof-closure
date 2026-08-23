import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Spec.Eip4788AnchorChild
import LidoSRv3.Audit.Spec.SszLiveCorrespondence
import LidoSRv3.Audit.Guarantees.PSszLive1

/-!
# Pack N5 fail-closed vectors

Three mutants of the Node 5 parent surface: a gateway that skips the
parent-root lookup, a verifier bound to toy slot 2, and a BEACON_ROOTS read
that ignores the requested timestamp. Premises are retained and the
refutations are parent-shaped. No SHA-256 claim (`A-SHA256-FFI` stays;
`combineAdd` is a test-only concrete combine, not a hash).
-/

namespace LidoSRv3.Tests.PackN5SszLiveMutants

open LidoSRv3.Audit
open LidoSRv3.Audit.Spec.Eip4788AnchorChild
open LidoSRv3.Audit.Spec.SszLiveCorrespondence
open LidoSRv3.Audit.Source.BeaconRootsCorrespondence
open LidoSRv3.Audit.Guarantees.PSszLive1

private def combineAdd (a b : Ssz.Node) : Ssz.Node := a + b

/-! ## Mutant 1: skip the parent-root lookup (age check only) -/

/-- Mutant gateway: admits on `ageCheck` alone, never consulting the
EIP-4788 lookup or the verifier. -/
def admitSkipLookup (_combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (wcProof : WcWitness) : Bool :=
  ageCheck wcProof.anchor

/-- A fresh-anchor witness with an empty (depth-0) path: the honest
production verify rejects it against every claimed parent root, but its
age check passes. -/
def skipLookupKillWitness : WcWitness :=
  ⟨0, [], [], ⟨[]⟩, ⟨0, 0, 0⟩⟩

/-- Kill-line, parent-shaped with premises retained: substituting
`admitSkipLookup` for the honest gateway in
`production_witness_admission_correspondence` is refuted. At
`skipLookupKillWitness` the mutant admits (age check passes), so the
mutant correspondence would hand back a parent root the depth-0 path
verifies against — but `verifyAtParent` at the production index is false
for every root at that depth. -/
theorem skip_lookup_kill_line_refutes_parent :
    ¬ (∀ (combine : Ssz.Node → Ssz.Node → Ssz.Node) (wcProof : WcWitness),
      (ageCheck wcProof.anchor = true ∧
          ∃ parentRoot,
            eip4788ParentRoot wcProof.beaconRoots
                wcProof.anchor.beaconRootTimestamp =
                some parentRoot ∧
              verifyAtParent combine wcProof.leaf productionIndex parentRoot
                wcProof.path wcProof.branch = true) ↔
        admitSkipLookup combine wcProof = true) := by
  intro hMutantParent
  have hAdmit : admitSkipLookup combineAdd skipLookupKillWitness = true := by
    decide
  obtain ⟨-, parentRoot, -, hVerify⟩ :=
    (hMutantParent combineAdd skipLookupKillWitness).mpr hAdmit
  have hFalse : verifyAtParent combineAdd skipLookupKillWitness.leaf
      productionIndex parentRoot skipLookupKillWitness.path
      skipLookupKillWitness.branch = false :=
    verifyAtParent_production_wrong_depth combineAdd
      skipLookupKillWitness.leaf parentRoot skipLookupKillWitness.path
      skipLookupKillWitness.branch (by decide)
  exact Bool.noConfusion (hVerify.symm.trans hFalse)

/-! ## Mutant 2: toy slot 2 instead of `150 * 2 ^ 40` -/

/-- Mutant live verifier bound to the toy `operationIndex` slot 2 instead
of the production generalized index. -/
def verifyAtLookupToySlot (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (wcProof : WcWitness) : Bool :=
  match eip4788ParentRoot wcProof.beaconRoots
      wcProof.anchor.beaconRootTimestamp with
  | none => false
  | some parentRoot =>
      verifyAtParent combine wcProof.leaf
        (Ssz.operationIndex .clValidatorVerifier) parentRoot
        wcProof.path wcProof.branch

/-- Mutant gateway over the toy-slot verifier. -/
def admitToySlot (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (wcProof : WcWitness) : Bool :=
  ageCheck wcProof.anchor && verifyAtLookupToySlot combine wcProof

/-- Concrete divergence: the toy slot 2 accepts a depth-1 witness that the
production index rejects against the same claimed parent root. -/
theorem toy_slot_accepts_shallow_witness_production_rejects :
    verifyAtParent combineAdd 1 (Ssz.operationIndex .clValidatorVerifier) 1
        [.right] [0] = true ∧
      verifyAtParent combineAdd 1 productionIndex 1 [.right] [0] = false :=
  ⟨by decide, by decide⟩

/-- Kill-line, parent-shaped with premises retained: substituting toy
slot 2 for `productionIndex` in the verify side of the parent's soundness
surface (`verifyAtParent_sound` at the production index, as unpacked by
`gateway_admission_sound`) is refuted. The depth-1 toy witness satisfies
the retained verify premise, but its path cannot carry the production
generalized-index meaning (depth 1 ≠ 47). -/
theorem toy_slot_kill_line_refutes_verify_parent :
    ¬ (∀ (combine : Ssz.Node → Ssz.Node → Ssz.Node)
        (leaf parentRoot : Ssz.Node) (path : List Ssz.SiblingSide)
        (branch : List Ssz.Node),
      verifyAtParent combine leaf (Ssz.operationIndex .clValidatorVerifier)
          parentRoot path branch = true →
        Ssz.HasGeneralizedIndex productionIndex (Ssz.pivot productionIndex)
            path ∧
          branch.length = path.length ∧
          Ssz.traverseBranch combine leaf path branch = parentRoot) := by
  intro hMutantParent
  obtain ⟨hGi, -, -⟩ :=
    hMutantParent combineAdd 1 1 [.right] [0] (by decide)
  exact absurd hGi.2.1 (by decide)

/-- Gateway-level divergence, honestly conditional on a hypothesized
`some` lookup (the opaque symbol is not evaluated): under the same anchor
and looked-up root, the toy-slot gateway admits the depth-1 witness the
honest production gateway rejects. -/
theorem toy_slot_gateway_kill_line_under_lookup
    (beaconRoots : BeaconRootsHistory) (anchor : ParentRootAnchor)
    (hAge : ageCheck anchor = true)
    (hLookup :
      eip4788ParentRoot beaconRoots anchor.beaconRootTimestamp = some 1) :
    admitToySlot combineAdd
        ⟨1, [.right], [0], beaconRoots, anchor⟩ = true ∧
      admitTopupOrConsolidation combineAdd
        ⟨1, [.right], [0], beaconRoots, anchor⟩ = false := by
  constructor
  · simp only [admitToySlot, verifyAtLookupToySlot, hLookup, hAge,
      Bool.true_and]
    decide
  · simp [admitTopupOrConsolidation, verifyAtLookup, hLookup,
      verifyAtParent_production_wrong_depth combineAdd 1 1 [.right] [0]
        (by decide)]

/-! ## Mutant 3: ignore the requested BEACON_ROOTS timestamp -/

/-- Mutant read: always returns cell zero's root and never validates the
requested timestamp. -/
def beaconRootsIgnoreTimestamp (storage : BeaconRootsStorage) (_timestamp : Nat) :
    Option Ssz.Node :=
  match storage.cells[0]? with
  | none => none
  | some cell => some cell.rootWord

/-- Two cells that distinguish timestamp-selected slot 1 from the mutant's
constant slot 0. -/
def timestampKillStorage : BeaconRootsStorage :=
  ⟨[⟨99, 11⟩, ⟨1, 7⟩]⟩

/-- The honest modeled read selects slot `1 % 8191`, validates timestamp 1,
and returns root 7; the mutant ignores timestamp and returns root 11. -/
theorem timestamp_lookup_concrete_divergence :
    sourceBeaconRootsRead timestampKillStorage 1 = some 7 ∧
      beaconRootsIgnoreTimestamp timestampKillStorage 1 = some 11 := by
  decide

/-- Kill-line for the identified symbol, with the full consume-parent shape
retained. Replacing the Verity BEACON_ROOTS read by a timestamp-ignoring
lookup fails the parent's identified-root conjunct before admission can be
claimed. -/
theorem ignore_timestamp_kill_line_refutes_consume_parent :
    ¬ LiveSszConsumeParent beaconRootsIgnoreTimestamp := by
  intro hMutantParent
  have hIdentified :=
    (hMutantParent.2 timestampKillStorage combineAdd 0 [] []
      ⟨1, 1, 0⟩).1.2
  have hMismatch :
      sourceBeaconRootsRead timestampKillStorage 1 ≠
        beaconRootsIgnoreTimestamp timestampKillStorage 1 := by
    decide
  exact hMismatch hIdentified

end LidoSRv3.Tests.PackN5SszLiveMutants
