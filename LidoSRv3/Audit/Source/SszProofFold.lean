import LidoSRv3.Audit.Source.SszWrapperIndex

/-!
Digest-carrying interpretation of SSZ.sol:179-249 at
lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436.
Typed proof elements replace calldata accesses; calldata pointer/end arithmetic
and scratch memory are not modeled. A successful SHA precompile is interpreted
as returning its complete digest. The source does NOT check returndatasize.
-/
namespace LidoSRv3.Audit.Source.SszProofFold

inductive Error where
  | invalidProof | extraItem | hashFailure | missingItem
  deriving DecidableEq, Repr

/-- A precompile may fail; success supplies the computed digest, not a match flag. -/
abbrev Hash (α : Type) := α → α → Option α

/-- The scratch side is selected from the CURRENT index, before shifting.
The parent-zero guard precedes the attempted hash. -/
def sourceFold (hash : Hash α) : Nat → α → List α → Except Error (Nat × α)
  | index, leaf, [] => .ok (index, leaf)
  | index, leaf, sibling :: rest =>
      let right := (index &&& 1) != 0
      let parent := index >>> 1
      if parent = 0 then .error .extraItem
      else
        match (if right then hash sibling leaf else hash leaf sibling) with
        | none => .error .hashFailure
        | some digest => sourceFold hash parent digest rest

/-- Entry gIndex is the source's decoded uint248, including zero and one.
The empty check is first. Missing siblings take priority over root mismatch. -/
def sourceVerify [DecidableEq α] (hash : Hash α)
    (index : Fin SszWrapperIndex.indexModulus) (leaf : α) (proof : List α)
    (root : α) : Except Error Unit :=
  if proof = [] then .error .invalidProof
  else do
    let (lastIndex, digest) ← sourceFold hash index.val leaf proof
    if lastIndex ≠ 1 then .error .missingItem
    else if digest = root then .ok () else .error .invalidProof

/-- Independent finite Merkle path. A parent at index n has children 2*n and
2*n+1, respectively. The proof lists siblings from leaf towards root. Unlike
the source, the specification constructs indices from a root at 1; it has no
shift, scratch offset, loop state, final-index check or executable equality. -/
inductive Branch (hash : Hash α) : Nat → α → List α → α → Prop where
  | root (digest : α) : Branch hash 1 digest [] digest
  | left {index : Nat} {leaf sibling parent root : α} {rest : List α}
      (hashed : hash leaf sibling = some parent)
      (above : Branch hash index parent rest root) :
      Branch hash (2 * index) leaf (sibling :: rest) root
  | right {index : Nat} {leaf sibling parent root : α} {rest : List α}
      (hashed : hash sibling leaf = some parent)
      (above : Branch hash index parent rest root) :
      Branch hash (2 * index + 1) leaf (sibling :: rest) root

/-- Full-depth bounds come from the structural path, not a supplied no-wrap bound. -/
theorem branch_interval {hash : Hash α} {index : Nat} {leaf root : α} {proof : List α}
    (h : Branch hash index leaf proof root) :
    2 ^ proof.length ≤ index ∧ index < 2 ^ (proof.length + 1) := by
  induction h with
  | root => simp
  | left hh ha ih =>
      simp only [List.length_cons, Nat.pow_succ] at *
      omega
  | right hh ha ih =>
      simp only [List.length_cons, Nat.pow_succ] at *
      omega

theorem branch_positive {hash : Hash α} {index : Nat} {leaf root : α} {proof : List α}
    (h : Branch hash index leaf proof root) : 0 < index :=
  lt_of_lt_of_le (Nat.two_pow_pos _) (branch_interval h).1

theorem branch_depth {hash : Hash α} {index : Nat} {leaf root : α} {proof : List α}
    (h : Branch hash index leaf proof root) : index.log2 = proof.length := by
  exact (Nat.log2_eq_iff (by have := branch_positive h; omega)).mpr (branch_interval h)

/-- Construction of an independent path is sufficient for the executable fold. -/
theorem branch_fold {hash : Hash α} {index : Nat} {leaf root : α} {proof : List α}
    (h : Branch hash index leaf proof root) :
    sourceFold hash index leaf proof = .ok (1, root) := by
  induction h with
  | root => rfl
  | @left index leaf sibling parent root rest hh ha ih =>
      have hp := branch_positive ha
      simp [sourceFold, Nat.shiftRight_eq_div_pow, Nat.mul_comm 2 index, hh, Nat.ne_of_gt hp, ih]
  | @right index leaf sibling parent root rest hh ha ih =>
      have hp := branch_positive ha
      have hd : (2 * index + 1) / 2 = index := by omega
      have hm : (2 * index + 1) % 2 = 1 := by omega
      simp [sourceFold, Nat.shiftRight_eq_div_pow, hd, hm, hh, Nat.ne_of_gt hp, ih]

/-- The digest carried by every successful source iteration creates a real
Merkle parent; no computed-root or final-match premise is introduced. -/
theorem fold_branch {hash : Hash α} (proof : List α) (index : Nat) (leaf root : α)
    (h : sourceFold hash index leaf proof = .ok (1, root)) :
    Branch hash index leaf proof root := by
  induction proof generalizing index leaf with
  | nil =>
      simp only [sourceFold, Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, rfl⟩ := h
      exact .root _
  | cons sibling rest ih =>
      simp only [sourceFold, Nat.and_one_is_mod, Nat.shiftRight_eq_div_pow, pow_one] at h
      split at h
      · contradiction
      next hp =>
        by_cases he : index % 2 = 0
        · simp only [he, bne_self_eq_false, Bool.false_eq_true, ↓reduceIte] at h
          cases hh : hash leaf sibling with
          | none => simp [hh] at h
          | some parent =>
              simp only [hh] at h
              have ha := ih (index / 2) parent h
              have hi : 2 * (index / 2) = index := by omega
              rw [← hi]
              exact .left hh ha
        · have ho : index % 2 = 1 := by omega
          simp only [ho] at h
          cases hh : hash sibling leaf with
          | none => simp [hh] at h
          | some parent =>
              simp only [hh] at h
              have ha := ih (index / 2) parent h
              have hi : 2 * (index / 2) + 1 = index := by omega
              rw [← hi]
              exact .right hh ha

theorem fold_root_iff {hash : Hash α} (proof : List α) (index : Nat) (leaf root : α) :
    sourceFold hash index leaf proof = .ok (1, root) ↔
      Branch hash index leaf proof root :=
  ⟨fold_branch proof index leaf root, branch_fold⟩

/-- Exact acceptance criterion, with both hash operand order and actual digest
encoded in the independently constructed Merkle path. -/
theorem verify_success_iff [DecidableEq α] (hash : Hash α)
    (index : Fin SszWrapperIndex.indexModulus) (leaf root : α) (proof : List α) :
    sourceVerify hash index leaf proof root = .ok () ↔
      proof ≠ [] ∧ Branch hash index.val leaf proof root := by
  unfold sourceVerify
  by_cases hn : proof = []
  · simp [hn]
  · simp only [hn, ↓reduceIte]
    cases hf : sourceFold hash index.val leaf proof with
    | error e =>
        simp only [bind, Except.bind, reduceCtorEq, false_iff]
        intro h
        have he := branch_fold h.2
        rw [hf] at he
        contradiction
    | ok result =>
        obtain ⟨lastIndex, digest⟩ := result
        simp only [bind, Except.bind]
        constructor
        · intro h
          split at h
          · contradiction
          next hi =>
            split at h
            next hd =>
              have hindex : lastIndex = 1 := by omega
              subst lastIndex
              subst digest
              exact ⟨hn, fold_branch proof index.val leaf root hf⟩
            · contradiction
        · intro h
          have he := branch_fold h.2
          rw [hf] at he
          have hx := Except.ok.inj he
          obtain ⟨rfl, rfl⟩ := Prod.mk.inj hx
          simp

/-- A successful typed uint248 verification consumes exactly its depth, hence
at most 247 siblings. This is derived, never an entry restriction on proof length. -/
theorem verify_depth [DecidableEq α] (hash : Hash α)
    (index : Fin SszWrapperIndex.indexModulus) (leaf root : α) (proof : List α)
    (h : sourceVerify hash index leaf proof root = .ok ()) :
    0 < proof.length ∧ proof.length = index.val.log2 ∧ proof.length ≤ 247 := by
  obtain ⟨hn, hb⟩ := (verify_success_iff hash index leaf root proof).mp h
  have hd := branch_depth hb
  have hi := branch_interval hb
  have hidx := index.isLt
  have hpow : 2 ^ proof.length < 2 ^ 248 := by
    exact lt_of_le_of_lt hi.1 hidx
  have hlen : proof.length < 248 := (Nat.pow_lt_pow_iff_right (by decide)).mp hpow
  exact ⟨List.length_pos_iff.mpr hn, hd.symm, by omega⟩

/-- Graft an independently authenticated subtree beneath another path. This
structural composition uses arithmetic child indices, not the source loop. -/
theorem branch_graft {hash : Hash α} {index outer : Nat}
    {leaf subtree root : α} {proof aboveProof : List α}
    (below : Branch hash index leaf proof subtree)
    (above : Branch hash outer subtree aboveProof root) :
    Branch hash ((outer - 1) * 2 ^ proof.length + index)
      leaf (proof ++ aboveProof) root := by
  induction below with
  | root =>
      have ho := branch_positive above
      simpa only [List.length_nil, pow_zero, Nat.mul_one, List.nil_append,
        Nat.sub_add_cancel ho] using above
  | @left index leaf sibling parent subtree rest hh hb ih =>
      have h := Branch.left hh (ih above)
      have he : (outer - 1) * 2 ^ (rest.length + 1) =
          2 * ((outer - 1) * 2 ^ rest.length) := by
        rw [Nat.pow_succ, ← Nat.mul_assoc]
        omega
      simpa only [List.length_cons, he, List.cons_append, Nat.mul_add, Nat.add_assoc] using h
  | @right index leaf sibling parent subtree rest hh hb ih =>
      have h := Branch.right hh (ih above)
      have he : (outer - 1) * 2 ^ (rest.length + 1) =
          2 * ((outer - 1) * 2 ^ rest.length) := by
        rw [Nat.pow_succ, ← Nat.mul_assoc]
        omega
      simpa only [List.length_cons, he, List.cons_append, Nat.mul_add, Nat.add_assoc] using h

open SszWrapperIndex in
/-- Independent root-to-leaf path position. Prefixing a left/right step places
the remaining path inside the left/right half of its new complete level. -/
def treeIndex : List Bool → Nat
  | [] => 1
  | false :: rest => 2 ^ rest.length + treeIndex rest
  | true :: rest => 2 * 2 ^ rest.length + treeIndex rest

open SszWrapperIndex in
/-- Digest at an independently traversed tree position; stopping at an internal
node is allowed and returns that subtree's digest. -/
def treeAt (pair : α → α → α) : Tree α → List Bool → Option α
  | tree, [] => some (treeDigest pair tree)
  | .leaf _, _ :: _ => none
  | .node left _, false :: rest => treeAt pair left rest
  | .node _ right, true :: rest => treeAt pair right rest

open SszWrapperIndex in
theorem tree_branch_length (pair : α → α → α) (tree : Tree α)
    (path : List Bool) (proof : List α)
    (h : treeBranch pair tree path = some proof) : proof.length = path.length := by
  induction path generalizing tree proof with
  | nil =>
      simp only [treeBranch, Option.some.injEq] at h
      subst proof
      rfl
  | cons side rest ih =>
      cases tree with
      | leaf value => simp [treeBranch] at h
      | node left right =>
          cases side
          · simp only [treeBranch] at h
            cases hc : treeBranch pair left rest with
            | none => simp [hc] at h
            | some childProof =>
                simp only [hc, Option.map_some, Option.some.injEq] at h
                subst proof
                simp [ih _ _ hc]
          · simp only [treeBranch] at h
            cases hc : treeBranch pair right rest with
            | none => simp [hc] at h
            | some childProof =>
                simp only [hc, Option.map_some, Option.some.injEq] at h
                subst proof
                simp [ih _ _ hc]

open SszWrapperIndex in
/-- Canonical tree extraction and independent tree traversal construct the
Merkle relation. No accepted-root equality or hash injectivity is assumed. -/
theorem tree_branch_authenticates (pair : α → α → α) (tree : Tree α)
    (path : List Bool) (proof : List α) (leaf : α)
    (hp : treeBranch pair tree path = some proof)
    (hl : treeAt pair tree path = some leaf) :
    Branch (fun a b => some (pair a b)) (treeIndex path) leaf proof (treeDigest pair tree) := by
  induction path generalizing tree proof leaf with
  | nil =>
      simp only [treeBranch, Option.some.injEq] at hp
      simp only [treeAt, Option.some.injEq] at hl
      subst proof
      subst leaf
      exact .root _
  | cons side rest ih =>
      cases tree with
      | leaf value => simp [treeBranch] at hp
      | node left right =>
          cases side
          · simp only [treeBranch] at hp
            cases hc : treeBranch pair left rest with
            | none => simp [hc] at hp
            | some childProof =>
                simp only [hc, Option.map_some, Option.some.injEq] at hp
                subst proof
                have hb := ih left childProof leaf hc hl
                have hg := branch_graft hb (Branch.left rfl (Branch.root (pair (treeDigest pair left) (treeDigest pair right))))
                have hlen := tree_branch_length pair left rest childProof hc
                simpa [treeIndex, treeDigest, hlen] using hg
          · simp only [treeBranch] at hp
            cases hc : treeBranch pair right rest with
            | none => simp [hc] at hp
            | some childProof =>
                simp only [hc, Option.map_some, Option.some.injEq] at hp
                subst proof
                have hb := ih right childProof leaf hc hl
                have hg := branch_graft hb (Branch.right rfl (Branch.root (pair (treeDigest pair left) (treeDigest pair right))))
                have hlen := tree_branch_length pair right rest childProof hc
                simpa [treeIndex, treeDigest, hlen] using hg

open SszWrapperIndex in
/-- Real digest consumer: the root is the mathematical tree digest, the leaf
comes from traversal and siblings from extraction. Only the input index/path
correspondence and nonempty source domain remain, not the desired result. -/
theorem tree_verifies [DecidableEq α] (pair : α → α → α) (tree : Tree α)
    (path : List Bool) (proof : List α) (leaf : α)
    (index : Fin indexModulus) (hi : index.val = treeIndex path)
    (hn : path ≠ []) (hp : treeBranch pair tree path = some proof)
    (hl : treeAt pair tree path = some leaf) :
    sourceVerify (fun a b => some (pair a b)) index leaf proof (treeDigest pair tree) = .ok () := by
  apply (verify_success_iff _ _ _ _ _).mpr
  constructor
  · have hlen := tree_branch_length pair tree path proof hp
    intro hz
    simp [hz] at hlen
    exact hn (List.length_eq_zero_iff.mp hlen.symm)
  · rw [hi]
    exact tree_branch_authenticates pair tree path proof leaf hp hl

/-- Path depth follows from the independent positional encoding itself. -/
theorem tree_index_interval (path : List Bool) :
    2 ^ path.length ≤ treeIndex path ∧ treeIndex path < 2 ^ (path.length + 1) := by
  induction path with
  | nil => simp [treeIndex]
  | cons side rest ih =>
      cases side <;> simp only [treeIndex, List.length_cons, Nat.pow_succ] at * <;> omega

theorem tree_index_depth (path : List Bool) : (treeIndex path).log2 = path.length := by
  have h := tree_index_interval path
  have hp := Nat.two_pow_pos path.length
  exact (Nat.log2_eq_iff (by omega)).mpr h

/-- Header state_root is the root-to-leaf path left/right/right. -/
theorem header_tree_index (path : List Bool) :
    treeIndex ([false, true, true] ++ path) = 10 * 2 ^ path.length + treeIndex path := by
  simp only [List.cons_append, List.nil_append, treeIndex, List.length_cons, Nat.pow_succ]
  omega

open SszWrapperIndex in
/-- Link the admitted pinned wrapper index to an independent state-tree path.
The state path's own field/index provenance remains explicit; its depth is
DERIVED from its index and the actual successful wrapper guard. -/
theorem pinned_header_path_index (pivot slot : Fin (2 ^ 64))
    (offset : Fin wordModulus) (out : PackedIndex) (path : List Bool)
    (hw : sourceWrapper (pinnedConfiguration pivot) slot offset = .ok out)
    (hs : treeIndex path = 150 * 2 ^ 40 + offset.val) :
    treeIndex ([false, true, true] ++ path) = out.index.val ∧ path.length = 47 := by
  obtain ⟨ho, hi, _, _⟩ := pinned_wrapper_success pivot slot offset out hw
  have hd : (treeIndex path).log2 = 47 := by
    rw [hs]
    exact pinned_neighbor_depth offset ho
  have hlen : path.length = 47 := (tree_index_depth path).symm.trans hd
  constructor
  · rw [header_tree_index, hlen, hs, hi]
    omega
  · exact hlen

open SszWrapperIndex in
/-- Concrete consumer of all three delivered components: admitted header index,
uint64 little-endian slot/proposer chunks, and the digest-carrying proof loop.
Both checks use the SAME independently extracted proof and tree. The only
state-path index link supplied concerns input selection, not any digest output. -/
theorem pinned_encoded_header_verifies
    (pair : BitVec 256 → BitVec 256 → BitVec 256)
    (pivot : Fin (2 ^ 64)) (slot proposer : BitVec 64)
    (offset : Fin wordModulus) (out : PackedIndex)
    (parentRoot bodyRoot leaf : BitVec 256) (state : Tree (BitVec 256))
    (path : List Bool) (stateProof : List (BitVec 256))
    (hw : sourceWrapper (pinnedConfiguration pivot) ⟨slot.toNat, slot.isLt⟩ offset = .ok out)
    (hs : treeIndex path = 150 * 2 ^ 40 + offset.val)
    (hp : treeBranch pair state path = some stateProof)
    (hl : treeAt pair state path = some leaf) :
    let header := headerTree (SszLittleEndianCorrespondence.uint64Chunk slot)
      (SszLittleEndianCorrespondence.uint64Chunk proposer) parentRoot bodyRoot 0 state
    ∃ proof,
      treeBranch pair header ([false, true, true] ++ path) = some proof ∧
      proof.length = 50 ∧
      sourceVerify (fun a b => some (pair a b)) out.index leaf proof
        (treeDigest pair header) = .ok () ∧
      sourceVerifySlotArithmetic pair proof slot proposer = .ok () := by
  dsimp only
  obtain ⟨hi, hlen⟩ := pinned_header_path_index pivot ⟨slot.toNat, slot.isLt⟩ offset out path hw hs
  obtain ⟨proof, hpFull, hpLen, hSlot⟩ := encoded_slot_accepts_header_branch pair
    slot proposer parentRoot bodyRoot state path stateProof hp
  have hstateLen := tree_branch_length pair state path stateProof hp
  refine ⟨proof, hpFull, by omega, ?_, hSlot⟩
  apply tree_verifies pair _ ([false, true, true] ++ path) proof leaf out.index hi.symm
    (by simp) hpFull
  simpa only [List.cons_append, List.nil_append, headerTree, treeAt] using hl

end LidoSRv3.Audit.Source.SszProofFold
