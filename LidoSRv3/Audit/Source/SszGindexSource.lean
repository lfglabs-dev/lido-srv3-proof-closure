/-! # SSZ generalized-index (gindex) source model

**General rule (Thomas 2026-09-13, chantier 3 SSZ derivation
prerequisite): the pinned CLValidatorVerifier consumes production
gindices for the BeaconState fields. This composition names the
gindex arithmetic + the pinned production gindex constants as a
source-level function of the BeaconState schema.**

**Status:** first real source-level naming of the SSZ gindex layout
and the pinned production gindex constants. -/

namespace LidoSRv3.Audit.Source.SszGindexSource

/-- Generalized index (gindex) as a Nat. A gindex identifies a
node in a Merkleized SSZ tree: root has gindex 1, left-child = 2*g,
right-child = 2*g+1. -/
abbrev Gindex := Nat

/-- Gindex of the root node. -/
def root : Gindex := 1

/-- Left-child gindex. -/
def leftChild (g : Gindex) : Gindex := 2 * g

/-- Right-child gindex. -/
def rightChild (g : Gindex) : Gindex := 2 * g + 1

/-- The depth of a gindex is the number of bits minus one. -/
def depth (g : Gindex) : Nat := Nat.log2 g

/-- Root has depth 0. -/
theorem depth_root : depth root = 0 := by
  unfold depth root
  decide

/-- Left-child gindex is exactly `2 * g`. Definitional. -/
theorem leftChild_eq (g : Gindex) : leftChild g = 2 * g := rfl

/-- The pinned BeaconState validators-list gindex for the beacon
state SSZ schema (production layout). -/
def validatorsListGindex : Gindex :=
  -- Production BeaconState.validators is at gindex 11 in the SSZ
  -- schema (per the pinned CLValidatorVerifier layout).
  11

/-- The pinned dummy-validator-at-gindex-2 stays as a legacy scaffold
gindex; retained here so downstream can distinguish production vs.
scaffold. -/
def scaffoldValidatorGindex : Gindex := 2

/-- Production and scaffold gindices are distinct. -/
theorem production_and_scaffold_distinct :
    validatorsListGindex ≠ scaffoldValidatorGindex := by
  unfold validatorsListGindex scaffoldValidatorGindex
  decide

end LidoSRv3.Audit.Source.SszGindexSource
