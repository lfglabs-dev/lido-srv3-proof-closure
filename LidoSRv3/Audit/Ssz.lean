/-!
# Structural SSZ witness model

This module is intentionally about the executable *shape* of the SSZ proof
helpers: container leaves, generalized-index paths, pivot/branch traversal,
and the wrappers which bind that traversal to the three source-shaped
operations.  `Node` and `combine` are abstract.  Consequently it establishes
neither SSZ serialization nor SHA-256 correctness, precompile behavior,
Solidity correspondence, EVM execution, nor end-to-end validator provenance.
-/

namespace LidoSRv3.Audit.Ssz

/-- An opaque structural tree node.  It is not a cryptographic digest. -/
abbrev Node := Nat

/-- Which side of the current node contains the branch sibling. -/
inductive SiblingSide
  | left | right
  deriving DecidableEq, Repr

/-- A source-shaped Validator container represented by its structural leaves. -/
structure Validator where
  pubkey : Node
  withdrawalCredentials : Node
  effectiveBalance : Node
  slashed : Node
  activationEligibilityEpoch : Node
  activationEpoch : Node
  exitEpoch : Node
  withdrawableEpoch : Node
  deriving DecidableEq, Repr

/-- The structural (not SSZ-cryptographic) binary container root. -/
def validatorRoot (combine : Node → Node → Node) (validator : Validator) : Node :=
  let a := combine validator.pubkey validator.withdrawalCredentials
  let b := combine validator.effectiveBalance validator.slashed
  let c := combine validator.activationEligibilityEpoch validator.activationEpoch
  let d := combine validator.exitEpoch validator.withdrawableEpoch
  combine (combine a b) (combine c d)

/-- A generalized index together with its root-to-leaf branch path. -/
structure GeneralizedIndex where
  value : Nat
  isPositive : 0 < value
  deriving DecidableEq, Repr

/-- The highest one-bit is the generalized-index pivot. -/
def pivot (index : GeneralizedIndex) : Nat :=
  Nat.shiftLeft 1 (Nat.log2 index.value)

/--
The leaf-to-root sibling directions selected by a generalized index.  The
fuel is deliberately bounded by `value`, making this a total executable
structural traversal without assuming any numeric word width.
-/
def pathAux : Nat → Nat → List SiblingSide
  | 0, _ => []
  | fuel + 1, value =>
      if value ≤ 1 then []
      else
        (if value % 2 = 0 then .right else .left) :: pathAux fuel (value / 2)

def branchPath (index : GeneralizedIndex) : List SiblingSide :=
  pathAux (Nat.log2 (pivot index)) index.value

/-- The low generalized-index bits encoded by a leaf-to-root branch path. -/
def pathOffset : List SiblingSide → Nat
  | [] => 0
  | .left :: sides => 1 + 2 * pathOffset sides
  | .right :: sides => 2 * pathOffset sides

/-- Reconstruct a generalized index from independently supplied pivot/path data. -/
def indexFromPivotPath (pivotBoundary : Nat) (path : List SiblingSide) : Nat :=
  pivotBoundary + pathOffset path

/--
An independently supplied pivot/path pair has the structural generalized-index
meaning claimed for `index`: it uses that index's pivot boundary, has exactly
the pivot depth, and reconstructs the index value.  This is MODEL-only
generalized-index arithmetic; it is not an SSZ or cryptographic claim.
-/
def HasGeneralizedIndex (index : GeneralizedIndex) (pivotBoundary : Nat)
    (path : List SiblingSide) : Prop :=
  pivotBoundary = pivot index ∧
    path.length = Nat.log2 pivotBoundary ∧
      indexFromPivotPath pivotBoundary path = index.value

/-- Fold an explicit branch from its leaf towards the generalized-index pivot. -/
def traverseBranch (combine : Node → Node → Node) (leaf : Node) :
    List SiblingSide → List Node → Node
  | [], _ => leaf
  | .left :: sides, sibling :: siblings =>
      traverseBranch combine (combine sibling leaf) sides siblings
  | .right :: sides, sibling :: siblings =>
      traverseBranch combine (combine leaf sibling) sides siblings
  | _ :: sides, [] => traverseBranch combine leaf sides []

/-- The source-shaped helper entry points that consume validator witnesses. -/
inductive Operation
  | clValidatorVerifier
  | clProofVerifier
  | consolidationGateway
  deriving DecidableEq, Repr

/--
Distinct model-level generalized-index slots for the three named wrappers.
These slots make operation binding part of the traversed structure; they do
not assert that the numbers are production source constants.
-/
def operationIndex : Operation → GeneralizedIndex
  | .clValidatorVerifier => ⟨2, by decide⟩
  | .clProofVerifier => ⟨3, by decide⟩
  | .consolidationGateway => ⟨4, by decide⟩

/--
A proof witness declares the named operation it is intended for, together with
its validator, generalized index, and consumed sibling branch.  The operation
tag is structural model data, not a claim of source correspondence.
-/
structure ValidatorWitness where
  operation : Operation
  validator : Validator
  index : GeneralizedIndex
  pivotBoundary : Nat
  path : List SiblingSide
  branch : List Node
  deriving DecidableEq, Repr

/--
Structural verification checks independently supplied pivot/path data against
the claimed generalized index, checks branch arity, and reconstructs the
supplied root using that supplied path.
-/
def verifyProof (combine : Node → Node → Node) (leaf : Node)
    (index : GeneralizedIndex) (pivotBoundary : Nat) (path : List SiblingSide)
    (branch : List Node) (expectedRoot : Node) : Bool :=
  (pivotBoundary == pivot index) &&
    (path.length == Nat.log2 pivotBoundary) &&
      (indexFromPivotPath pivotBoundary path == index.value) &&
        (branch.length == path.length) &&
          (traverseBranch combine leaf path branch == expectedRoot)

/-- Bind a witness wrapper to the structural proof helper. -/
def verifyValidatorWitness (combine : Node → Node → Node) (witness : ValidatorWitness)
    (expectedRoot : Node) : Bool :=
  verifyProof combine (validatorRoot combine witness.validator) witness.index
    witness.pivotBoundary witness.path witness.branch expectedRoot

/-- Bind the structural helper to its source-shaped call-site operations. -/
def bindOperation (operation : Operation) (combine : Node → Node → Node)
    (witness : ValidatorWitness) (expectedRoot : Node) : Bool :=
  (witness.operation == operation) &&
    (witness.index == operationIndex operation) &&
    verifyValidatorWitness combine witness expectedRoot

/--
Successful operation binding proves that the independently supplied pivot/path
has the claimed generalized-index meaning, consumes exactly that supplied path,
and reconstructs the supplied structural root. This is a MODEL-layer theorem
over the executable structural helper only; it makes no SSZ, SHA-256, Solidity,
EVM, transaction, source-correspondence, or end-to-end claim.
-/
theorem structural_witness_binding_sound
    (h : bindOperation operation combine witness expectedRoot = true) :
    witness.operation = operation ∧
      witness.index = operationIndex operation ∧
      HasGeneralizedIndex witness.index witness.pivotBoundary witness.path ∧
      witness.branch.length = witness.path.length ∧
      traverseBranch combine (validatorRoot combine witness.validator)
        witness.path witness.branch = expectedRoot := by
  simp [bindOperation, verifyValidatorWitness, verifyProof] at h
  rcases h with ⟨⟨hOperation, hIndex⟩,
    ⟨⟨⟨hPivot, hDepth⟩, hValue⟩, hArity⟩, hRoot⟩
  exact ⟨hOperation, hIndex, ⟨hPivot, hDepth, hValue⟩, hArity, hRoot⟩

end LidoSRv3.Audit.Ssz
