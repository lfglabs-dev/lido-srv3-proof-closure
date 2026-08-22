import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Spec.Eip4788AnchorChild
import LidoSRv3.Audit.Spec.ProductionGindexChild

/-!
# Node 5: SSZ live-chain correspondence layer

Inhabits a named `ProductionGindex` model constant from the pinned
lidofinance/core@af095e48 test vector
(`GI_FIRST_VALIDATOR_CURR` packed
`0x0000000000000000000000000000000000000000000000000096000000000028`,
labeled mainnet values in `test/0.8.25/validatorExitDelayVerifier.test.ts`;
pack layout `(index << 8) | pow` per `contracts/common/lib/GIndex.sol`), and
binds `Ssz.verifyProof` to a parent-root argument through `verifyAtParent`.

This is a MODEL constant from the pinned test vector, NOT a discharge of a
deployment assumption: `ProductionGindexChild.ProductionGindexBinding`
(deployed-GI equality) stays exactly as that child records it, and the toy
slots 2/3/4 stay the leftover record for `Ssz.operationIndex`. The parent
root consumed here is `Eip4788AnchorChild.eip4788ParentRoot`, which stays an
opaque lookup; when the lookup is `none`, verification is false. `combine`
stays abstract, so SHA-256 functional correctness remains the named
`A-SHA256-FFI` assumption; no claim about deployed SHA, Yul, the beacon-roots
precompile, or EVM execution is made.
-/

namespace LidoSRv3.Audit.Spec.SszLiveCorrespondence

open LidoSRv3.Audit
open LidoSRv3.Audit.Spec.Eip4788AnchorChild

/-- A named production generalized-index constant: the raw validator-tree
index, the depth `pow`, and the `(index << 8) | pow` packed word from
`GIndex.sol`. Model data pinned from the test vector, not a deployed-GI
equality. -/
structure ProductionGindex where
  index : Nat
  pow : Nat
  packed : Nat
  deriving DecidableEq, Repr

/-- The inhabited `ProductionGindex`: `GI_FIRST_VALIDATOR_CURR` from the
pinned lidofinance/core@af095e48 vector. `pow = 0x28 = 40`,
`index = 0x960000000000 = 150 * 2 ^ 40`. -/
def giFirstValidatorCurr : ProductionGindex :=
  { index := 150 * 2 ^ 40
    pow := 40
    packed :=
      0x0000000000000000000000000000000000000000000000000096000000000028 }

/-- The pinned packed word decodes as `(index << 8) | pow`, the
`GIndex.sol` pack layout. -/
theorem giFirstValidatorCurr_packed_decodes :
    giFirstValidatorCurr.packed =
      (giFirstValidatorCurr.index <<< 8) ||| giFirstValidatorCurr.pow := by
  decide

theorem giFirstValidatorCurr_pow : giFirstValidatorCurr.pow = 40 := rfl

theorem giFirstValidatorCurr_index :
    giFirstValidatorCurr.index = 150 * 2 ^ 40 := rfl

/-- The production generalized index as the structural `Ssz` layer consumes
it. Value `150 * 2 ^ 40`, not a toy `operationIndex` slot. -/
def productionIndex : Ssz.GeneralizedIndex :=
  ⟨giFirstValidatorCurr.index, by decide⟩

theorem production_index_value : productionIndex.value = 150 * 2 ^ 40 := rfl

/-- The toy slots stay the leftover record: cites
`ProductionGindexChild.cl_validator_index_is_toy` without rewriting that
child. The new parent below uses `productionIndex`, not slot 2. -/
theorem toy_slots_remain_leftover_record :
    (Ssz.operationIndex .clValidatorVerifier).value = 2 :=
  ProductionGindexChild.cl_validator_index_is_toy

/-- The production index is not the toy slot 2 the leftover record keeps. -/
theorem production_index_ne_toy_slot :
    productionIndex.value ≠ (Ssz.operationIndex .clValidatorVerifier).value := by
  decide

/-- The production pivot boundary is `2 ^ 47` (`log2 150 = 7`, plus the
40-deep subtree). -/
theorem production_pivot : Ssz.pivot productionIndex = 2 ^ 47 := by decide

/-- The production branch depth is 47. -/
theorem production_pivot_depth :
    Nat.log2 (Ssz.pivot productionIndex) = 47 := by decide

/-- The structural leaf-to-root path selected by the production index. -/
def productionPath : List Ssz.SiblingSide := Ssz.branchPath productionIndex

theorem production_path_length : productionPath.length = 47 := by decide

/-- The production path reconstructs exactly `150 * 2 ^ 40` from the
production pivot boundary. -/
theorem production_path_reconstructs_index :
    Ssz.indexFromPivotPath (Ssz.pivot productionIndex) productionPath =
      productionIndex.value := by
  decide

/-- Structural verification against an explicit parent root: exactly
`Ssz.verifyProof` at the index's own pivot boundary, with `parentRoot` as
the `expectedRoot`. `combine` stays abstract (`A-SHA256-FFI`). -/
def verifyAtParent (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (leaf : Ssz.Node) (gi : Ssz.GeneralizedIndex) (parentRoot : Ssz.Node)
    (path : List Ssz.SiblingSide) (branch : List Ssz.Node) : Bool :=
  Ssz.verifyProof combine leaf gi (Ssz.pivot gi) path branch parentRoot

/-- Soundness of `verifyAtParent` at any generalized index: success yields
the generalized-index meaning of the supplied path, branch arity, and
reconstruction of the parent root. MODEL-layer only; no SSZ-cryptographic
or SHA-256 claim. -/
theorem verifyAtParent_sound
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (leaf : Ssz.Node)
    (gi : Ssz.GeneralizedIndex) (parentRoot : Ssz.Node)
    (path : List Ssz.SiblingSide) (branch : List Ssz.Node)
    (h : verifyAtParent combine leaf gi parentRoot path branch = true) :
    Ssz.HasGeneralizedIndex gi (Ssz.pivot gi) path ∧
      branch.length = path.length ∧
      Ssz.traverseBranch combine leaf path branch = parentRoot := by
  simp [verifyAtParent, Ssz.verifyProof, beq_iff_eq] at h
  rcases h with ⟨⟨⟨hDepth, hValue⟩, hArity⟩, hRoot⟩
  exact ⟨⟨rfl, hDepth, hValue⟩, hArity, hRoot⟩

/-- A path whose depth is not the production 47 can never verify at the
production index, for every combine, leaf, branch, and claimed parent
root. This is the structural rejection the kill-lines lean on. -/
theorem verifyAtParent_production_wrong_depth
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (leaf parentRoot : Ssz.Node)
    (path : List Ssz.SiblingSide) (branch : List Ssz.Node)
    (hDepth : path.length ≠ 47) :
    verifyAtParent combine leaf productionIndex parentRoot path branch =
      false := by
  simp [verifyAtParent, Ssz.verifyProof, production_pivot_depth, hDepth]

/-- Construction leg at the production index: a 47-branch witness along the
production path verifies against its own structural traversal root. This is
structural non-vacuity of `verifyAtParent` at `productionIndex`; the
`Nat`-tree traversal is not a finish and makes no SHA-256 claim. -/
theorem verifyAtParent_production_construction
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (leaf : Ssz.Node)
    (branch : List Ssz.Node) (hArity : branch.length = 47) :
    verifyAtParent combine leaf productionIndex
      (Ssz.traverseBranch combine leaf productionPath branch)
      productionPath branch = true := by
  simp [verifyAtParent, Ssz.verifyProof, production_pivot_depth,
    production_path_length, production_path_reconstructs_index, hArity]

/-- A top-up / consolidation withdrawal-credentials proof witness: the
structural leaf, its branch data, and the EIP-4788 anchor timestamps the
gateway age-checks. -/
structure WcWitness where
  leaf : Ssz.Node
  path : List Ssz.SiblingSide
  branch : List Ssz.Node
  anchor : ParentRootAnchor
  deriving DecidableEq, Repr

/-- Live-chain verification: the parent root used by verify is
`eip4788ParentRoot ts` when `some`, at the production generalized index.
The lookup stays opaque but is consumed here, not an unused symbol. When
the lookup is `none`, verify is false. -/
def verifyAtLookup (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (w : WcWitness) : Bool :=
  match eip4788ParentRoot w.anchor.beaconRootTimestamp with
  | none => false
  | some parentRoot =>
      verifyAtParent combine w.leaf productionIndex parentRoot w.path w.branch

/-- When the opaque lookup is `none`, verify is false. -/
theorem verifyAtLookup_none (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (w : WcWitness)
    (h : eip4788ParentRoot w.anchor.beaconRootTimestamp = none) :
    verifyAtLookup combine w = false := by
  simp [verifyAtLookup, h]

/-- When the opaque lookup is `some`, verify is exactly `verifyAtParent`
against the looked-up parent root at the production index. -/
theorem verifyAtLookup_some (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (w : WcWitness) (parentRoot : Ssz.Node)
    (h : eip4788ParentRoot w.anchor.beaconRootTimestamp = some parentRoot) :
    verifyAtLookup combine w =
      verifyAtParent combine w.leaf productionIndex parentRoot
        w.path w.branch := by
  simp [verifyAtLookup, h]

/-- Live verification succeeds iff the opaque lookup produced a parent root
and the witness verifies against exactly that root at the production
index. -/
theorem verifyAtLookup_eq_true_iff (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (w : WcWitness) :
    verifyAtLookup combine w = true ↔
      ∃ parentRoot,
        eip4788ParentRoot w.anchor.beaconRootTimestamp = some parentRoot ∧
          verifyAtParent combine w.leaf productionIndex parentRoot
            w.path w.branch = true := by
  cases hLookup : eip4788ParentRoot w.anchor.beaconRootTimestamp with
  | none => simp [verifyAtLookup, hLookup]
  | some parentRoot => simp [verifyAtLookup, hLookup]

end LidoSRv3.Audit.Spec.SszLiveCorrespondence
