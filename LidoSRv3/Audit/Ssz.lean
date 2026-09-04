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

/-- The source-shaped helper entry points that consume validator witnesses.

Exclusion note: `clValidatorVerifier` denotes
`CLValidatorVerifier._verifyValidator` (`CLValidatorVerifier.sol:44-57`),
which is NOT transcribed: `_verifySlot` (50), `_getParentBlockRoot` (52),
`concat(GI_STATE_ROOT, _getValidatorGI(...))` (54) and
`_validatorHashTreeRoot` (55) have no model here. Only its final call
`SSZ.verifyProof({proof: _vw.proofValidator, root: parentBlockRoot, leaf: validatorLeaf, gI: gIndexValidator})`
(56) is modelled, via `verifyValidatorWitness`. The two other tags name
the sibling wrappers in the same way (call site only). -/
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

/-! ## SSZ.verifyProof (contracts/common/lib/SSZ.sol:179-248) -/

/-- `SSZ.sol:179-248 verifyProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf, GIndex gI)`,
abstract plane. Clause-by-clause map (the Lean conjuncts are pure checks on
supplied data, not the Yul loop):

* pivot decode: `SSZ.sol:180  uint256 index = gI.index();` and the
  pivot/path decomposition (`pivotBoundary == pivot index`) which Solidity
  never materializes, it walks `index` bit by bit;
* loop length: `SSZ.sol:185-189  if iszero(proof.length) { revert InvalidProof }`
  and `SSZ.sol:190  let end := add(proof.offset, shl(5, proof.length))`:
  the loop runs once per proof element, hence
  `branch.length == path.length`;
* `SSZ.sol:200  index := shr(1, index)` per iteration is the step of
  `pathAux` (value / 2), and `SSZ.sol:199  let scratch := shl(5, and(index, 1))`
  chooses the sibling side (`.left` / `.right`);
* `SSZ.sol:201-205  if iszero(index) { revert BranchHasExtraItem() }` (the
  proof is longer than the depth) and
  `SSZ.sol:236-240  if iszero(eq(index, 1)) { revert BranchHasMissingItem() }`
  (shorter than the depth) together are
  `path.length == Nat.log2 pivotBoundary` and
  `indexFromPivotPath pivotBoundary path == index.value`;
* final `SSZ.sol:242-246  if iszero(eq(leaf, root)) { revert InvalidProof() }`
  is `traverseBranch combine leaf path branch == expectedRoot`.

Abstract-plane reminder: `combine` replaces the SHA-256 STATICCALL of
`SSZ.sol:214-221` (`staticcall(gas(), 0x02, 0x00, 0x40, 0x00, 0x20)`) and
its `revert(0, 0)` on failure (223-226); the Yul scratch memory (`mstore`
at 209-213, `mload(0x00)` at 229), the calldata pointers (`offset`, `end`)
and the raw-selector reverts (`mstore(0x00, 0x09bde339)` and friends) are
not transcribed. The revert selectors and first-failure control flow live
in the independent `Source.SszVerifierProgram.observeVerifierControl`
(same span, no import in either direction on purpose).

Structural verification checks independently supplied pivot/path data against
the claimed generalized index, checks branch arity, and reconstructs the
supplied root using that supplied path.
-/
def verifyProof (combine : Node → Node → Node) (leaf : Node)
    (index : GeneralizedIndex) (pivotBoundary : Nat) (path : List SiblingSide)
    (branch : List Node) (expectedRoot : Node) : Bool :=
  -- SSZ.sol:180  uint256 index = gI.index();  (pivot decomposition, model-side)
  (pivotBoundary == pivot index) &&
    -- SSZ.sol:201 / 236  BranchHasExtraItem / BranchHasMissingItem  (depth = proof length)
    (path.length == Nat.log2 pivotBoundary) &&
      -- SSZ.sol:199-200  scratch := shl(5, and(index, 1)); index := shr(1, index)  (path bits are the index bits)
      (indexFromPivotPath pivotBoundary path == index.value) &&
        -- SSZ.sol:185-190  proof.length / end  (one iteration per proof element)
        (branch.length == path.length) &&
          -- SSZ.sol:242  if iszero(eq(leaf, root))  (fold replaces the SHA-256 staticcall 214-221)
          (traverseBranch combine leaf path branch == expectedRoot)

/-- `CLValidatorVerifier.sol:56  SSZ.verifyProof({proof: _vw.proofValidator, root: parentBlockRoot, leaf: validatorLeaf, gI: gIndexValidator});`
with `validatorLeaf` (55, `_validatorHashTreeRoot`) replaced by the
structural `validatorRoot`. Bind a witness wrapper to the structural proof
helper. -/
def verifyValidatorWitness (combine : Node → Node → Node) (witness : ValidatorWitness)
    (expectedRoot : Node) : Bool :=
  verifyProof combine (validatorRoot combine witness.validator) witness.index
    witness.pivotBoundary witness.path witness.branch expectedRoot

/-- Bind the structural helper to its source-shaped call-site operations.

Exclusion: for `.clValidatorVerifier` this is the call site
`CLValidatorVerifier.sol:56` only; `_verifyValidator` (44-57) itself
(`_verifySlot` 50, `_getParentBlockRoot` 52, `concat(GI_STATE_ROOT, ...)`
54, `_validatorHashTreeRoot` 55) is not transcribed, and `operationIndex`
is a model slot, not `gIndexValidator`. -/
def bindOperation (operation : Operation) (combine : Node → Node → Node)
    (witness : ValidatorWitness) (expectedRoot : Node) : Bool :=
  (witness.operation == operation) &&
    (witness.index == operationIndex operation) &&
    verifyValidatorWitness combine witness expectedRoot

/-- Solidity-facing name, `CLValidatorVerifier.sol:44 _verifyValidator`
(call site only, see `bindOperation`). -/
abbrev verifyValidator := bindOperation

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
