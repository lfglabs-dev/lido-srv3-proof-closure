import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Spec.Eip4788AnchorChild
import LidoSRv3.Audit.Spec.ProductionGindexChild
import LidoSRv3.Audit.Spec.SszLiveCorrespondence
import LidoSRv3.Audit.Source.BeaconRootsCorrespondence
import LidoSRv3.Audit.Verity.BeaconRootsTx
import LidoSRv3.Audit.Guarantees.Registry

/-!
# Node 5 parent: modeled live SSZ verify consume

Gateway admission for a top-up / consolidation withdrawal-credentials
witness: the existing `Eip4788AnchorChild.ageCheck` conjoined with
`verifyAtLookup`, i.e. `verifyAtParent` at the inhabited production
generalized index (`150 * 2 ^ 40`, `giFirstValidatorCurr`) against the
parent root produced by the modeled EIP-4788 `BEACON_ROOTS` lookup.

The registered parent-shaped theorem is
`production_witness_admission_correspondence`: a witness verifies at the
production GI against the looked-up parent root (with a fresh age check)
iff the gateway admits it.

Honesty ledger: registered as supplemental `P-SSZ-LIVE-1`; not a
minimal-11 row. The former opaque `eip4788ParentRoot` is discharged at the
model boundary as the EIP-4788 timestamp-indexed 8191-slot history read and
is related Spec→Source→Verity. The gateway consumes that read, and `none`
admits nothing. `combine` stays abstract, so SHA-256 functional correctness
remains the named `A-SHA256-FFI` assumption. `ProductionGindexBinding` is
the in-repo TopUpGateway constructor pin; that pin is not a deployed
identity. This is modeled live-chain verification, not a deployed Solidity
gateway, official consolidation success, or a bus.
-/

namespace LidoSRv3.Audit.Guarantees.PSszLive1

open LidoSRv3.Audit
open LidoSRv3.Audit.Spec.Eip4788AnchorChild
open LidoSRv3.Audit.Spec.ProductionGindexChild
open LidoSRv3.Audit.Spec.SszLiveCorrespondence
open LidoSRv3.Audit.Source.BeaconRootsCorrespondence
open LidoSRv3.Audit.Verity.BeaconRootsTx

/-- Supplemental production-GI / modeled EIP-4788 consume parent.
`A-SHA256-FFI` stays; no deployed Solidity gateway identity. -/
def guarantee : Guarantee := ⟨.pSszLive1, [.model, .source, .verityTx]⟩

/-- Gateway admission of a top-up / consolidation WC witness: the existing
`ageCheck` on the anchor timestamps, conjoined with modeled live verification at
the production generalized index against the looked-up parent root. -/
def admitTopupOrConsolidation (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (wcProof : WcWitness) : Bool :=
  ageCheck wcProof.anchor && verifyAtLookup combine wcProof

/-- Admission correspondence: the witness age-checks and verifies at the
production GI against the parent root the modeled EIP-4788 lookup produced,
iff the gateway admits it. The lookup is consumed (a `none` lookup admits
nothing); `combine` stays abstract (`A-SHA256-FFI`); the production GI is
`productionIndex`, not toy slot 2. Kept as a lemma of the registered
constructor-pin parent below. -/
theorem production_witness_admission_correspondence :
    ∀ (combine : Ssz.Node → Ssz.Node → Ssz.Node) (wcProof : WcWitness),
      (ageCheck wcProof.anchor = true ∧
          ∃ parentRoot,
            eip4788ParentRoot wcProof.beaconRoots
                wcProof.anchor.beaconRootTimestamp =
                some parentRoot ∧
              verifyAtParent combine wcProof.leaf productionIndex parentRoot
                wcProof.path wcProof.branch = true) ↔
        admitTopupOrConsolidation combine wcProof = true := by
  intro combine wcProof
  simp only [admitTopupOrConsolidation, Bool.and_eq_true,
    verifyAtLookup_eq_true_iff]

/-- Constructor-pin lemma retained from the earlier parent.
`ProductionGindexBinding` is the constructor-pin decode of
`g_index_first_validator_curr`, and gateway admission of a top-up /
consolidation WC witness is ageCheck plus production-GI verify against
the modeled looked-up parent root. The pin is an in-repo constructor
literal, not a live-deployment identity. -/
theorem production_witness_admission_from_core_gindex :
    ProductionGindexBinding ∧
      ∀ (combine : Ssz.Node → Ssz.Node → Ssz.Node) (wcProof : WcWitness),
        (ageCheck wcProof.anchor = true ∧
            ∃ parentRoot,
              eip4788ParentRoot wcProof.beaconRoots
                  wcProof.anchor.beaconRootTimestamp =
                  some parentRoot ∧
                verifyAtParent combine wcProof.leaf productionIndex parentRoot
                  wcProof.path wcProof.branch = true) ↔
          admitTopupOrConsolidation combine wcProof = true :=
  ⟨production_gindex_binding, production_witness_admission_correspondence⟩

/-- Build the WC witness whose modeled history is projected from the
source-shaped BEACON_ROOTS storage snapshot. -/
def witnessFromBeaconRootsStorage (storage : BeaconRootsStorage)
    (leaf : Ssz.Node) (path : List Ssz.SiblingSide)
    (branch : List Ssz.Node) (anchor : ParentRootAnchor) : WcWitness :=
  ⟨leaf, path, branch, toSpecHistory storage, anchor⟩

/-- The root result observed on the Verity transaction leg. -/
def verityBeaconRootsRead (storage : BeaconRootsStorage) (timestamp : Nat) :
    Option Ssz.Node :=
  executeRead ⟨storage, timestamp⟩

/-- Parent shape parameterized by the Verity-plane root lookup so an
identified-root mutant can be substituted at exactly that symbol.

The first conjunction is Spec→Source→Verity identification. The second
conjunction is the consume statement: age check plus production-GI
`verifyAtParent` against that identified root is equivalent to top-up /
consolidation WC admission. `combine` remains universally quantified under
`A-SHA256-FFI`. -/
def LiveSszConsumeParent
    (verityLookup : BeaconRootsStorage → Nat → Option Ssz.Node) : Prop :=
  ProductionGindexBinding ∧
    ∀ (storage : BeaconRootsStorage)
      (combine : Ssz.Node → Ssz.Node → Ssz.Node)
      (leaf : Ssz.Node) (path : List Ssz.SiblingSide)
      (branch : List Ssz.Node) (anchor : ParentRootAnchor),
      let wcProof :=
        witnessFromBeaconRootsStorage storage leaf path branch anchor
      (eip4788ParentRoot wcProof.beaconRoots anchor.beaconRootTimestamp =
            sourceBeaconRootsRead storage anchor.beaconRootTimestamp ∧
          sourceBeaconRootsRead storage anchor.beaconRootTimestamp =
            verityLookup storage anchor.beaconRootTimestamp) ∧
        ((ageCheck anchor = true ∧
              ∃ parentRoot,
                verityLookup storage anchor.beaconRootTimestamp =
                    some parentRoot ∧
                  verifyAtParent combine leaf productionIndex parentRoot
                    path branch = true) ↔
            admitTopupOrConsolidation combine wcProof = true)

/-- PARENT. Modeled live SSZ consume through Spec→Source→Verity
`BEACON_ROOTS`, the production generalized index, and the age check.

The old opaque EIP-4788 OPEN is discharged by
`eip4788_parent_root_identified` and the universal source/Verity
correspondence. `A-SHA256-FFI` remains named because `combine` is abstract.
The constructor pin is not a deployed identity. -/
theorem modeled_beacon_roots_live_ssz_consume :
    LiveSszConsumeParent verityBeaconRootsRead := by
  refine ⟨production_gindex_binding, ?_⟩
  intro storage combine leaf path branch anchor
  let wcProof :=
    witnessFromBeaconRootsStorage storage leaf path branch anchor
  have hChain :=
    spec_source_verity_beacon_roots storage anchor.beaconRootTimestamp
  have hAdmission :=
    production_witness_admission_correspondence combine wcProof
  refine ⟨?_, ?_⟩
  · simpa [wcProof, witnessFromBeaconRootsStorage, verityBeaconRootsRead]
      using hChain
  · change
      (ageCheck anchor = true ∧
          ∃ parentRoot,
            verityBeaconRootsRead storage anchor.beaconRootTimestamp =
                some parentRoot ∧
              verifyAtParent combine leaf productionIndex parentRoot
                path branch = true) ↔
        admitTopupOrConsolidation combine wcProof = true
    have hSpecSource :
        eip4788ParentRoot wcProof.beaconRoots anchor.beaconRootTimestamp =
          sourceBeaconRootsRead storage anchor.beaconRootTimestamp := by
      simpa [wcProof, witnessFromBeaconRootsStorage] using hChain.1
    have hSourceVerity :
        sourceBeaconRootsRead storage anchor.beaconRootTimestamp =
          verityBeaconRootsRead storage anchor.beaconRootTimestamp := by
      simpa [verityBeaconRootsRead] using hChain.2
    rw [← hSourceVerity, ← hSpecSource]
    simpa [wcProof, witnessFromBeaconRootsStorage] using hAdmission

/-- Unpacked admission soundness: an admitted witness age-checks, the
modeled lookup produced a parent root, and the witness carries the
production generalized-index meaning, branch arity, and structural
reconstruction of exactly that looked-up root. -/
theorem gateway_admission_sound
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (wcProof : WcWitness)
    (h : admitTopupOrConsolidation combine wcProof = true) :
    ageCheck wcProof.anchor = true ∧
      ∃ parentRoot,
        eip4788ParentRoot wcProof.beaconRoots
            wcProof.anchor.beaconRootTimestamp =
            some parentRoot ∧
          Ssz.HasGeneralizedIndex productionIndex
            (Ssz.pivot productionIndex) wcProof.path ∧
          wcProof.branch.length = wcProof.path.length ∧
          Ssz.traverseBranch combine wcProof.leaf wcProof.path
            wcProof.branch = parentRoot := by
  obtain ⟨hAge, parentRoot, hLookup, hVerify⟩ :=
    (production_witness_admission_correspondence combine wcProof).mpr h
  exact ⟨hAge, parentRoot, hLookup,
    verifyAtParent_sound combine wcProof.leaf productionIndex parentRoot
      wcProof.path wcProof.branch hVerify⟩

/-- Fail-closed on the lookup: when `eip4788ParentRoot` is `none` the
gateway admits nothing, age check notwithstanding. -/
theorem admission_false_of_lookup_none
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (wcProof : WcWitness)
    (h : eip4788ParentRoot wcProof.beaconRoots
      wcProof.anchor.beaconRootTimestamp = none) :
    admitTopupOrConsolidation combine wcProof = false := by
  simp [admitTopupOrConsolidation, verifyAtLookup_none combine wcProof h]

/-- Non-vacuity under a modeled `some` history read whose root the 47-branch
production-path traversal reconstructs, and a fresh age check. -/
theorem admitted_construction_under_lookup
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (leaf : Ssz.Node)
    (branch : List Ssz.Node) (anchor : ParentRootAnchor)
    (beaconRoots : BeaconRootsHistory) (parentRoot : Ssz.Node)
    (hAge : ageCheck anchor = true)
    (hArity : branch.length = 47)
    (hLookup : eip4788ParentRoot beaconRoots anchor.beaconRootTimestamp =
      some parentRoot)
    (hRoot : Ssz.traverseBranch combine leaf productionPath branch =
      parentRoot) :
    admitTopupOrConsolidation combine
      ⟨leaf, productionPath, branch, beaconRoots, anchor⟩ = true := by
  refine (production_witness_admission_correspondence combine
    ⟨leaf, productionPath, branch, beaconRoots, anchor⟩).mp
      ⟨hAge, parentRoot, hLookup, ?_⟩
  subst hRoot
  exact verifyAtParent_production_construction combine leaf branch hArity

end LidoSRv3.Audit.Guarantees.PSszLive1
