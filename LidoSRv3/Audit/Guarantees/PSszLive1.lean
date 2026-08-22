import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Spec.Eip4788AnchorChild
import LidoSRv3.Audit.Spec.SszLiveCorrespondence

/-!
# Node 5 parent: production-GI verify against the looked-up parent root

Gateway admission for a top-up / consolidation withdrawal-credentials
witness: the existing `Eip4788AnchorChild.ageCheck` conjoined with
`verifyAtLookup`, i.e. `verifyAtParent` at the inhabited production
generalized index (`150 * 2 ^ 40`, `giFirstValidatorCurr`) against the
parent root produced by the opaque `eip4788ParentRoot` lookup.

The registered parent-shaped theorem is
`production_witness_admission_correspondence`: a witness verifies at the
production GI against the looked-up parent root (with a fresh age check)
iff the gateway admits it.

Honesty ledger: this is an unregistered leftover node, not a new registry
row or guarantee ID. `combine` stays abstract, so SHA-256 functional
correctness remains the named `A-SHA256-FFI` assumption. The
`eip4788ParentRoot` lookup stays opaque (no precompile, no `block.parent`
read is inhabited); it is consumed by the verify, and admission is false
whenever it returns `none`. The production index is a pinned test-vector
model constant; the deployed-GI equality named by
`ProductionGindexChild.ProductionGindexBinding` stays open and is not
cited as discharged here. Not a live Solidity gateway. Not a bus.
-/

namespace LidoSRv3.Audit.Guarantees.PSszLive1

open LidoSRv3.Audit
open LidoSRv3.Audit.Spec.Eip4788AnchorChild
open LidoSRv3.Audit.Spec.SszLiveCorrespondence

/-- Gateway admission of a top-up / consolidation WC witness: the existing
`ageCheck` on the anchor timestamps, conjoined with live verification at
the production generalized index against the looked-up parent root. -/
def admitTopupOrConsolidation (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (wcProof : WcWitness) : Bool :=
  ageCheck wcProof.anchor && verifyAtLookup combine wcProof

/-- PARENT. One `∀` whose conclusion is the correspondence: the witness
age-checks and verifies at the production GI against the parent root the
opaque EIP-4788 lookup produced, iff the gateway admits it. The lookup is
consumed (a `none` lookup admits nothing); `combine` stays abstract
(`A-SHA256-FFI`); the production GI is the pinned test-vector constant
`productionIndex`, not toy slot 2. -/
theorem production_witness_admission_correspondence :
    ∀ (combine : Ssz.Node → Ssz.Node → Ssz.Node) (wcProof : WcWitness),
      (ageCheck wcProof.anchor = true ∧
          ∃ parentRoot,
            eip4788ParentRoot wcProof.anchor.beaconRootTimestamp =
                some parentRoot ∧
              verifyAtParent combine wcProof.leaf productionIndex parentRoot
                wcProof.path wcProof.branch = true) ↔
        admitTopupOrConsolidation combine wcProof = true := by
  intro combine wcProof
  simp only [admitTopupOrConsolidation, Bool.and_eq_true,
    verifyAtLookup_eq_true_iff]

/-- Unpacked admission soundness: an admitted witness age-checks, the
opaque lookup produced a parent root, and the witness carries the
production generalized-index meaning, branch arity, and structural
reconstruction of exactly that looked-up root. -/
theorem gateway_admission_sound
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (wcProof : WcWitness)
    (h : admitTopupOrConsolidation combine wcProof = true) :
    ageCheck wcProof.anchor = true ∧
      ∃ parentRoot,
        eip4788ParentRoot wcProof.anchor.beaconRootTimestamp =
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
    (h : eip4788ParentRoot wcProof.anchor.beaconRootTimestamp = none) :
    admitTopupOrConsolidation combine wcProof = false := by
  simp [admitTopupOrConsolidation, verifyAtLookup_none combine wcProof h]

/-- Non-vacuity, honestly conditional on the opaque lookup: under a
hypothesized `some` lookup whose root the 47-branch production-path
traversal reconstructs, and a fresh age check, the gateway admits the
constructed witness. This does not evaluate the opaque lookup and does not
discharge it. -/
theorem admitted_construction_under_lookup
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (leaf : Ssz.Node)
    (branch : List Ssz.Node) (anchor : ParentRootAnchor)
    (parentRoot : Ssz.Node)
    (hAge : ageCheck anchor = true)
    (hArity : branch.length = 47)
    (hLookup : eip4788ParentRoot anchor.beaconRootTimestamp = some parentRoot)
    (hRoot : Ssz.traverseBranch combine leaf productionPath branch =
      parentRoot) :
    admitTopupOrConsolidation combine
      ⟨leaf, productionPath, branch, anchor⟩ = true := by
  refine (production_witness_admission_correspondence combine
    ⟨leaf, productionPath, branch, anchor⟩).mp ⟨hAge, parentRoot, hLookup, ?_⟩
  subst hRoot
  exact verifyAtParent_production_construction combine leaf branch hArity

end LidoSRv3.Audit.Guarantees.PSszLive1
