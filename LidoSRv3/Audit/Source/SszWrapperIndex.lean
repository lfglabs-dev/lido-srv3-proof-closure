import Mathlib.Data.Nat.Bitwise
import Lean.Elab.Tactic.Omega
import LidoSRv3.Audit.Source.SszLittleEndianCorrespondence

/-!
# SSZ wrapper index: checked neighbor, header prefix, slot sibling

Source pin: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436.
CLValidatorVerifier.sol:19-22,54,89-99; GIndex.sol:23-30,41-64,76-89.
The independent append specification uses multiplication and pivot subtraction,
not the source shift/XOR/OR algorithm. `fls` is interpreted by its stated
most-significant-bit semantics, including zero=256; correspondence with the
Solady assembly implementation itself remains a source-review boundary.
No memory, SHA256, full wrapper execution or deployment theorem is claimed.
-/
namespace LidoSRv3.Audit.Source.SszWrapperIndex

def indexModulus : Nat := 2 ^ 248
def wordModulus : Nat := 2 ^ 256

structure PackedIndex where
  index : Fin indexModulus
  power : Fin 256
  deriving DecidableEq, Repr

inductive Error where
  | arithmeticPanic | indexOutOfRange | invalidSlot
  deriving DecidableEq, Repr

structure Configuration where
  previous : PackedIndex
  current : PackedIndex
  pivotSlot : Fin (2 ^ 64)
  deriving DecidableEq, Repr

def selected (cfg : Configuration) (slot : Fin (2 ^ 64)) : PackedIndex :=
  if slot.val < cfg.pivotSlot.val then cfg.previous else cfg.current

/-- Source checked sums and range checks, including distinct panic/range errors. -/
def sourceNeighbor (g : PackedIndex) (offset : Fin wordModulus) : Except Error PackedIndex :=
  let i := g.index.val
  let w := 2 ^ g.power.val
  if i % w + offset.val >= wordModulus then .error .arithmeticPanic
  else if i % w + offset.val >= w then .error .indexOutOfRange
  else if i + offset.val >= wordModulus then .error .arithmeticPanic
  else if h : i + offset.val < indexModulus then
    .ok ⟨⟨i + offset.val, h⟩, g.power⟩
  else .error .indexOutOfRange

def fls (n : Nat) : Nat := if n = 0 then 256 else n.log2

/-- Fixed-width source shift; pack's uint248 guard is executed afterwards. -/
def sourceConcat (left right : PackedIndex) : Except Error PackedIndex :=
  let a := left.index.val
  let b := right.index.val
  let d := fls b
  if fls a + 1 + d > 248 then .error .indexOutOfRange
  else
    let joined := ((a <<< d) % wordModulus) ||| (b ^^^ ((1 <<< d) % wordModulus))
    if h : joined < indexModulus then .ok ⟨⟨joined, h⟩, right.power⟩
    else .error .indexOutOfRange

/-- Independent index of the path obtained by descending below a right root:
keep the left root and append the right path bits below its leading one. -/
def appendIndex (a b : Nat) : Nat :=
  a * 2 ^ b.log2 + (b - 2 ^ b.log2)

/-- Removing the leading bit really is pivot subtraction, on its full domain. -/
theorem xor_pivot_eq_sub (b d : Nat) (hlo : 2 ^ d ≤ b) (hhi : b < 2 ^ (d + 1)) :
    b ^^^ (2 ^ d) = b - 2 ^ d := by
  have hp : 0 < 2 ^ d := Nat.two_pow_pos d
  have hq : b / 2 ^ d = 1 := by
    apply Nat.div_eq_of_lt_le
    · simpa using hlo
    · simpa [Nat.pow_succ, Nat.mul_comm] using hhi
  have hxq : (b ^^^ (2 ^ d)) / 2 ^ d = 0 := by
    rw [Nat.xor_div_two_pow, hq]
    rw [Nat.div_self hp]
    decide
  have hxm : (b ^^^ (2 ^ d)) % 2 ^ d = b % 2 ^ d := by
    rw [Nat.xor_mod_two_pow]
    simp
  have h1 := Nat.mod_add_div b (2 ^ d)
  have h2 := Nat.mod_add_div (b ^^^ (2 ^ d)) (2 ^ d)
  rw [hq] at h1
  rw [hxq, hxm] at h2
  omega

theorem concat_expression_eq_append (a b : Nat) (hb : b ≠ 0) :
    (a <<< b.log2) ||| (b ^^^ (1 <<< b.log2)) = appendIndex a b := by
  have hlo := Nat.log2_self_le hb
  have hhi : b < 2 ^ (b.log2 + 1) := Nat.lt_log2_self
  have ht : b - 2 ^ b.log2 < 2 ^ b.log2 := by
    rw [Nat.pow_succ] at hhi
    omega
  simp only [Nat.shiftLeft_eq, Nat.one_mul]
  rw [xor_pivot_eq_sub b b.log2 hlo hhi]
  rw [← Nat.shiftLeft_eq a b.log2, ← Nat.shiftLeft_add_eq_or_of_lt ht]
  simp [appendIndex, Nat.shiftLeft_eq]

/-- Bound of the independent path append; source depth guard implies pack fits. -/
theorem append_lt_pow (a b : Nat) (hb : b ≠ 0) :
    appendIndex a b < 2 ^ (a.log2 + 1 + b.log2) := by
  have ha : a < 2 ^ (a.log2 + 1) := Nat.lt_log2_self
  have hhi : b < 2 ^ (b.log2 + 1) := Nat.lt_log2_self
  have hlo := Nat.log2_self_le hb
  have ht : b - 2 ^ b.log2 < 2 ^ b.log2 := by
    rw [Nat.pow_succ] at hhi
    omega
  calc
    appendIndex a b < a * 2 ^ b.log2 + 2 ^ b.log2 := Nat.add_lt_add_left ht _
    _ = (a + 1) * 2 ^ b.log2 := by rw [Nat.add_mul]; simp
    _ ≤ 2 ^ (a.log2 + 1) * 2 ^ b.log2 := Nat.mul_le_mul_right _ (by omega)
    _ = 2 ^ (a.log2 + 1 + b.log2) := (Nat.pow_add _ _ _).symm

/-- The source depth guard derives both shift safety and uint248 pack safety.
No separate no-wrap or result-fit premise is required. -/
theorem concat_of_depth (left right : PackedIndex)
    (hd : fls left.index.val + 1 + fls right.index.val ≤ 248) :
    ∃ out, sourceConcat left right = .ok out ∧
      out.index.val = appendIndex left.index.val right.index.val ∧
      out.power = right.power := by
  have ha : left.index.val ≠ 0 := by
    intro hz
    simp [fls, hz] at hd
    omega
  have hb : right.index.val ≠ 0 := by
    intro hz
    simp [fls, hz] at hd
  have hd' : left.index.val.log2 + 1 + right.index.val.log2 ≤ 248 := by
    simpa [fls, ha, hb] using hd
  have hp : appendIndex left.index.val right.index.val < indexModulus :=
    Nat.lt_of_lt_of_le (append_lt_pow _ _ hb) (Nat.pow_le_pow_right (by decide) hd')
  have hword : appendIndex left.index.val right.index.val < wordModulus :=
    Nat.lt_trans hp (by decide : indexModulus < wordModulus)
  have hs : left.index.val <<< right.index.val.log2 < wordModulus := by
    simp only [Nat.shiftLeft_eq]
    unfold appendIndex at hword
    omega
  have hroot : 1 <<< right.index.val.log2 < wordModulus := by
    simp only [Nat.shiftLeft_eq, Nat.one_mul]
    exact Nat.lt_of_le_of_lt (Nat.log2_self_le hb)
      (Nat.lt_trans right.index.isLt (by decide : indexModulus < wordModulus))
  refine ⟨⟨⟨appendIndex left.index.val right.index.val, hp⟩, right.power⟩, ?_, rfl, rfl⟩
  simp only [sourceConcat, fls, if_neg ha, if_neg hb,
    if_neg (Nat.not_lt.mpr hd'), Nat.mod_eq_of_lt hs, Nat.mod_eq_of_lt hroot,
    concat_expression_eq_append _ _ hb, dif_pos hp]

/-- Successful checked neighbor reads the selected base and derives its domain. -/
theorem neighbor_success (g out : PackedIndex) (offset : Fin wordModulus)
    (h : sourceNeighbor g offset = .ok out) :
    out.index.val = g.index.val + offset.val ∧
    out.power = g.power ∧ offset.val < 2 ^ g.power.val := by
  unfold sourceNeighbor at h
  dsimp only at h
  split at h
  · contradiction
  · split at h
    · contradiction
    next hw =>
      split at h
      · contradiction
      · split at h
        · have he := Except.ok.inj h
          subst out
          exact ⟨rfl, rfl, by omega⟩
        · contradiction

/-- Index 11 is the header's fourth field (state_root), at depth three. -/
def stateRootIndex : PackedIndex := ⟨⟨11, by decide⟩, ⟨3, by decide⟩⟩

def sourceWrapper (cfg : Configuration) (slot : Fin (2 ^ 64))
    (offset : Fin wordModulus) : Except Error PackedIndex := do
  let validator ← sourceNeighbor (selected cfg slot) offset
  sourceConcat stateRootIndex validator

/-- Generic successful concatenation refines the independent arithmetic path
spec, with no assumed final word-fit or shifted-value equality. -/
theorem concat_success (left right out : PackedIndex)
    (h : sourceConcat left right = .ok out) :
    out.index.val = appendIndex left.index.val right.index.val ∧ out.power = right.power := by
  have hd : fls left.index.val + 1 + fls right.index.val ≤ 248 := by
    by_contra hn
    simp [sourceConcat, Nat.lt_of_not_ge hn] at h
  obtain ⟨actual, he, hi, hp⟩ := concat_of_depth left right hd
  rw [he] at h
  cases Except.ok.inj h
  exact ⟨hi, hp⟩

/-- Generic constructor inputs and both fork branches remain explicit. The
offset bound is obtained from execution success, not supplied as a premise. -/
theorem wrapper_success (cfg : Configuration) (slot : Fin (2 ^ 64))
    (offset : Fin wordModulus) (out : PackedIndex)
    (h : sourceWrapper cfg slot offset = .ok out) :
    offset.val < 2 ^ (selected cfg slot).power.val ∧
    out.index.val = appendIndex 11 ((selected cfg slot).index.val + offset.val) ∧
    out.power = (selected cfg slot).power := by
  unfold sourceWrapper at h
  cases hn : sourceNeighbor (selected cfg slot) offset with
  | error e => simp [hn, bind, Except.bind] at h
  | ok shifted =>
    simp only [hn, bind, Except.bind] at h
    obtain ⟨hi, hp, hb⟩ := neighbor_success _ shifted offset hn
    obtain ⟨hc, hpower⟩ := concat_success stateRootIndex shifted out h
    refine ⟨hb, ?_, hpower.trans hp⟩
    simpa only [stateRootIndex, Fin.val_mk, hi] using hc

/-- The current source configuration artifact, not a deployed immutable fact. -/
def pinnedBase : PackedIndex :=
  ⟨⟨150 * 2 ^ 40, by decide⟩, ⟨40, by decide⟩⟩

def pinnedConfiguration (pivot : Fin (2 ^ 64)) : Configuration :=
  ⟨pinnedBase, pinnedBase, pivot⟩

def pinnedNeighbor (offset : Fin wordModulus) (h : offset.val < 2 ^ 40) : PackedIndex :=
  ⟨⟨150 * 2 ^ 40 + offset.val, by unfold indexModulus; omega⟩, ⟨40, by decide⟩⟩

/-- Exact outcomes for every uint256 offset; acceptance width is not assumed. -/
theorem source_neighbor_pinned (offset : Fin wordModulus) :
    sourceNeighbor pinnedBase offset =
      if h : offset.val < 2 ^ 40 then .ok (pinnedNeighbor offset h)
      else .error .indexOutOfRange := by
  have hw := offset.isLt
  dsimp only [sourceNeighbor, pinnedBase]
  rw [Nat.mul_mod_left, Nat.zero_add]
  rw [if_neg (Nat.not_le.mpr hw)]
  by_cases h : offset.val < 2 ^ 40
  · have hs : 150 * 2 ^ 40 + offset.val < wordModulus := by unfold wordModulus; omega
    have hp : 150 * 2 ^ 40 + offset.val < indexModulus := by unfold indexModulus; omega
    rw [if_neg (Nat.not_le.mpr h), if_neg (Nat.not_le.mpr hs), dif_pos hp, dif_pos h]
    rfl
  · rw [if_pos (Nat.le_of_not_gt h), dif_neg h]

theorem pinned_neighbor_depth (offset : Fin wordModulus) (h : offset.val < 2 ^ 40) :
    (pinnedNeighbor offset h).index.val.log2 = 47 := by
  apply (Nat.log2_eq_iff (by simp [pinnedNeighbor])).mpr
  simp only [pinnedNeighbor, Fin.val_mk]
  constructor <;> omega

/-- Header concatenation computes 1430 rather than the state-relative 150. -/
theorem pinned_append_value (offset : Fin wordModulus) (h : offset.val < 2 ^ 40) :
    appendIndex stateRootIndex.index.val (pinnedNeighbor offset h).index.val =
      1430 * 2 ^ 40 + offset.val := by
  unfold appendIndex
  rw [pinned_neighbor_depth offset h]
  simp only [stateRootIndex, pinnedNeighbor, Fin.val_mk]
  omega

/-- Generic fork selection is retained even though the two pinned layout
parameters happen to be equal in the source configuration artifact. -/
theorem selected_pinned (pivot slot : Fin (2 ^ 64)) :
    selected (pinnedConfiguration pivot) slot = pinnedBase := by
  simp [selected, pinnedConfiguration]

/-- Useful consumer: derive accepted offset range from the actual source
operation and identify the complete header-relative index and metadata. -/
theorem pinned_wrapper_success (pivot slot : Fin (2 ^ 64))
    (offset : Fin wordModulus) (out : PackedIndex)
    (h : sourceWrapper (pinnedConfiguration pivot) slot offset = .ok out) :
    offset.val < 2 ^ 40 ∧ out.index.val = 1430 * 2 ^ 40 + offset.val ∧
      out.index.val.log2 = 50 ∧ out.power.val = 40 := by
  unfold sourceWrapper at h
  rw [selected_pinned, source_neighbor_pinned] at h
  split at h
  next ho =>
    simp only [bind, Except.bind] at h
    have hd : fls stateRootIndex.index.val + 1 + fls (pinnedNeighbor offset ho).index.val ≤ 248 := by
      have hn : (pinnedNeighbor offset ho).index.val ≠ 0 := by simp [pinnedNeighbor]
      simp [fls, stateRootIndex, hn, pinned_neighbor_depth, show Nat.log2 11 = 3 from by decide]
    obtain ⟨actual, ha, hi, hp⟩ := concat_of_depth stateRootIndex (pinnedNeighbor offset ho) hd
    rw [ha] at h
    have he := Except.ok.inj h
    subst out
    have hval : actual.index.val = 1430 * 2 ^ 40 + offset.val := by
      rw [hi, pinned_append_value]
    refine ⟨ho, hval, ?_, ?_⟩
    · rw [hval]
      apply (Nat.log2_eq_iff (by omega)).mpr
      constructor <;> omega
    · rw [hp]; rfl
  · simp [bind, Except.bind] at h

/-- The pinned source accepts exactly the offsets in its configured subtree.
This prevents the successful-result theorem from being vacuous. -/
theorem pinned_wrapper_accepts_iff (pivot slot : Fin (2 ^ 64))
    (offset : Fin wordModulus) :
    (∃ out, sourceWrapper (pinnedConfiguration pivot) slot offset = .ok out) ↔
      offset.val < 2 ^ 40 := by
  constructor
  · rintro ⟨out, h⟩
    exact (pinned_wrapper_success pivot slot offset out h).1
  · intro ho
    have hn : (pinnedNeighbor offset ho).index.val ≠ 0 := by simp [pinnedNeighbor]
    have hd : fls stateRootIndex.index.val + 1 + fls (pinnedNeighbor offset ho).index.val ≤ 248 := by
      simp [fls, stateRootIndex, hn, pinned_neighbor_depth, show Nat.log2 11 = 3 from by decide]
    obtain ⟨out, hs, _, _⟩ := concat_of_depth stateRootIndex (pinnedNeighbor offset ho) hd
    refine ⟨out, ?_⟩
    simpa only [sourceWrapper, selected_pinned, source_neighbor_pinned,
      dif_pos ho, bind, Except.bind] using hs

/-- The actual index's three final parent steps enter header indices 11,5,2.
Their parities are 1,1,0; the middle sibling is therefore header node 4. -/
theorem pinned_header_steps (pivot slot : Fin (2 ^ 64))
    (offset : Fin wordModulus) (out : PackedIndex)
    (h : sourceWrapper (pinnedConfiguration pivot) slot offset = .ok out) :
    out.index.val / 2 ^ 47 = 11 ∧ out.index.val / 2 ^ 48 = 5 ∧
    out.index.val / 2 ^ 49 = 2 := by
  obtain ⟨ho, hi, _, _⟩ := pinned_wrapper_success pivot slot offset out h
  rw [hi]
  constructor
  · omega
  · constructor <;> omega

/-- An independent binary tree; it does not reuse source calldata offsets. -/
inductive Tree (α : Type) where
  | leaf (value : α)
  | node (left right : Tree α)
  deriving Repr

def treeDigest (pair : α → α → α) : Tree α → α
  | .leaf value => value
  | .node left right => pair (treeDigest pair left) (treeDigest pair right)

/-- Canonical sibling extraction follows root-to-leaf directions; the returned
proof is leaf-to-root. False goes left, true goes right. -/
def treeBranch (pair : α → α → α) : Tree α → List Bool → Option (List α)
  | _, [] => some []
  | .leaf _, _ :: _ => none
  | .node left right, false :: rest =>
      (treeBranch pair left rest).map (fun p => p ++ [treeDigest pair right])
  | .node left right, true :: rest =>
      (treeBranch pair right rest).map (fun p => p ++ [treeDigest pair left])

/-- Independent BeaconBlockHeader tree: slot, proposer, parentRoot, stateRoot,
bodyRoot and three zero chunks. The state subtree is arbitrary. -/
def headerTree (slot proposer parentRoot bodyRoot zero : α) (state : Tree α) : Tree α :=
  .node (.node (.node (.leaf slot) (.leaf proposer)) (.node (.leaf parentRoot) state))
    (.node (.node (.leaf bodyRoot) (.leaf zero)) (.node (.leaf zero) (.leaf zero)))

/-- Indexing fragment AFTER `_verifySlot` computes its SHA pair. The subtraction
panics for lengths 0/1; the index cannot be out of bounds otherwise. A SHA call
failure can occur before this fragment and is not represented here. -/
def sourceSlotSibling (proof : List α) : Except Error α :=
  if proof.length < 2 then .error .arithmeticPanic
  else match proof[proof.length - 2]? with
    | some value => .ok value
    | none => .error .arithmeticPanic

/-- The source's length-minus-two expression picks the slot/proposer subtree
of an independently extracted header proof, for every state subtree and path.
This is position correspondence, not hash injectivity or proof authentication. -/
theorem slot_sibling_of_header_branch (pair : α → α → α)
    (slot proposer parentRoot bodyRoot zero : α) (state : Tree α)
    (path : List Bool) (stateProof : List α)
    (h : treeBranch pair state path = some stateProof) :
    ∃ fullProof,
      treeBranch pair (headerTree slot proposer parentRoot bodyRoot zero state)
        ([false, true, true] ++ path) = some fullProof ∧
      fullProof.length = stateProof.length + 3 ∧
      sourceSlotSibling fullProof = .ok (pair slot proposer) := by
  let tailRoot := pair (pair bodyRoot zero) (pair zero zero)
  refine ⟨stateProof ++ [parentRoot, pair slot proposer, tailRoot], ?_, ?_, ?_⟩
  · simp [headerTree, treeBranch, treeDigest, h, tailRoot, List.append_assoc]
  · simp
  · simp only [sourceSlotSibling, List.length_append, List.length_cons,
      List.length_nil]
    have hn : stateProof.length + (1 + (1 + (1 + 0))) - 2 = stateProof.length + 1 := by omega
    simp only [hn]
    rw [List.getElem?_append_right (by omega)]
    simp

/-- Arithmetic/encoding part of `_verifySlot` after successful pair hashing.
`pair` is universally quantified; precompile call failures and returndata-size
checks are not represented. It computes the expected value, rather than taking
a root-match boolean or expected digest as an independent input. -/
def sourceVerifySlotArithmetic (pair : BitVec 256 → BitVec 256 → BitVec 256)
    (proof : List (BitVec 256)) (slot proposer : BitVec 64) : Except Error Unit := do
  let expected := pair
    (SszLittleEndianCorrespondence.sourceUint256 (slot.zeroExtend 256))
    (SszLittleEndianCorrespondence.sourceUint256 (proposer.zeroExtend 256))
  let actual ← sourceSlotSibling proof
  if actual = expected then .ok () else .error .invalidSlot

/-- Concrete uint64 encoding is now consumed by the actual slot/proposer check
shape. The reference header uses the independent octet chunks, not the source
mask/shift function. This is construction/position correctness, NOT uniqueness
of an arbitrary branch that hashes to a root. -/
theorem encoded_slot_accepts_header_branch
    (pair : BitVec 256 → BitVec 256 → BitVec 256)
    (slot proposer : BitVec 64) (parentRoot bodyRoot : BitVec 256)
    (state : Tree (BitVec 256)) (path : List Bool) (stateProof : List (BitVec 256))
    (h : treeBranch pair state path = some stateProof) :
    ∃ fullProof,
      treeBranch pair
        (headerTree (SszLittleEndianCorrespondence.uint64Chunk slot)
          (SszLittleEndianCorrespondence.uint64Chunk proposer) parentRoot bodyRoot 0 state)
        ([false, true, true] ++ path) = some fullProof ∧
      fullProof.length = stateProof.length + 3 ∧
      sourceVerifySlotArithmetic pair fullProof slot proposer = .ok () := by
  obtain ⟨fullProof, hp, hl, hs⟩ := slot_sibling_of_header_branch pair
    (SszLittleEndianCorrespondence.uint64Chunk slot)
    (SszLittleEndianCorrespondence.uint64Chunk proposer) parentRoot bodyRoot 0 state path stateProof h
  refine ⟨fullProof, hp, hl, ?_⟩
  simp [sourceVerifySlotArithmetic, SszLittleEndianCorrespondence.source_uint64_chunk,
    hs, bind, Except.bind]

end LidoSRv3.Audit.Source.SszWrapperIndex
