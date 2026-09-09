import LidoSRv3.Audit.Source.SszVerifierEntry

/-!
Generic SSZ merkleization spine and independent ordered-chunk reduction.
Neither construction mentions BeaconState, a validator field or a source index.
Depths remain symbolic; no complete depth40 tree is evaluated by these proofs.
-/
namespace LidoSRv3.Audit.Source.SszPerfectTree
open SszWrapperIndex SszValidatorLeaf SszProofFold

/-- A complete binary spine over ordered subtree values. A bottom subtree may
itself represent a composite SSZ value; its root is the corresponding chunk. -/
def perfectTree : Nat → (Nat → Tree α) → Tree α
  | 0, values => values 0
  | depth + 1, values => .node (perfectTree depth values)
      (perfectTree depth (fun i => values (2 ^ depth + i)))

/-- Independent ordered list of chunks, used only symbolically at large depth. -/
def chunks (depth : Nat) (values : Nat → α) : List α :=
  (List.range (2 ^ depth)).map values

/-- Ordered SSZ chunk reduction by list halves, with zero padding interpreted
by the caller's chunk list. This operates on a list, not on perfectTree. -/
def orderedMerkle (hash : α → α → α) (zero : α) : Nat → List α → α
  | 0, values => values.headD zero
  | depth + 1, values => hash
      (orderedMerkle hash zero depth (values.take (2 ^ depth)))
      (orderedMerkle hash zero depth (values.drop (2 ^ depth)))

theorem chunks_length (depth : Nat) (values : Nat → α) :
    (chunks depth values).length = 2 ^ depth := by simp [chunks]

theorem chunks_split (depth : Nat) (values : Nat → α) :
    chunks (depth + 1) values = chunks depth values ++
      chunks depth (fun i => values (2 ^ depth + i)) := by
  simp only [chunks, Nat.pow_succ, Nat.mul_two, List.range_add, List.map_append,
    List.map_map, Function.comp_def]

/-- The chunk function for a valid bounded list is exactly its ordered values
followed by bottom-level zero chunks. No input element is silently truncated. -/
theorem chunks_padding (depth : Nat) (values : List α) (zero : α)
    (hbound : values.length ≤ 2 ^ depth) :
    chunks depth (fun i => values[i]?.getD zero) =
      values ++ List.replicate (2 ^ depth - values.length) zero := by
  apply List.ext_getElem
  · simp only [chunks_length, List.length_append, List.length_replicate]
    omega
  · intro i hi hj
    simp only [chunks, List.getElem_map, List.getElem_range]
    by_cases hin : i < values.length
    · rw [List.getElem_append_left hin, List.getElem?_eq_getElem hin]
      rfl
    · have hout : values.length ≤ i := by omega
      rw [List.getElem_append_right hout, List.getElem?_eq_none hout]
      simp only [Option.getD_none, List.getElem_replicate]

/-- Genuine agreement between the tree interpretation and ordered list
merkleization, proved for every depth and every subtree-valued input. -/
theorem perfect_digest_ordered (hash : α → α → α) (zero : α)
    (depth : Nat) (values : Nat → Tree α) :
    treeDigest hash (perfectTree depth values) =
      orderedMerkle hash zero depth (chunks depth (fun i => treeDigest hash (values i))) := by
  induction depth generalizing values with
  | zero => rfl
  | succ depth ih =>
      rw [chunks_split]
      simp only [perfectTree, treeDigest, orderedMerkle,
        ← chunks_length depth (fun i => treeDigest hash (values i)),
        List.take_left, List.drop_left]
      simp only [chunks_length]
      rw [ih values, ih (fun i => values (2 ^ depth + i))]

/-- Independent root-to-position address from successive interval halves. -/
def addressPath : Nat → Nat → List Bool
  | 0, _ => []
  | depth + 1, i =>
      if i < 2 ^ depth then false :: addressPath depth i
      else true :: addressPath depth (i - 2 ^ depth)

theorem address_length (depth i : Nat) : (addressPath depth i).length = depth := by
  induction depth generalizing i with
  | zero => rfl
  | succ depth ih => simp only [addressPath]; split <;> simp [ih]

theorem address_index (depth i : Nat) (hi : i < 2 ^ depth) :
    treeIndex (addressPath depth i) = 2 ^ depth + i := by
  induction depth generalizing i with
  | zero =>
      have hz : i = 0 := by simpa using hi
      subst i
      rfl
  | succ depth ih =>
      simp only [addressPath]
      split
      · next h => rw [treeIndex, address_length, ih i h]; simp only [Nat.pow_succ]; omega
      · next h =>
          have hb : i - 2 ^ depth < 2 ^ depth := by simp only [Nat.pow_succ] at hi; omega
          rw [treeIndex, address_length, ih _ hb]
          simp only [Nat.pow_succ]
          omega

theorem perfect_subtree (depth i : Nat) (values : Nat → Tree α)
    (hi : i < 2 ^ depth) :
    subtreeAt (perfectTree depth values) (addressPath depth i) = some (values i) := by
  induction depth generalizing i values with
  | zero =>
      have hz : i = 0 := by simpa using hi
      subst i
      change subtreeAt (values 0) [] = some (values 0)
      cases values 0 <;> rfl
  | succ depth ih =>
      simp only [perfectTree, addressPath]
      split
      · next h => exact ih i values h
      · next h =>
          have hb : i - 2 ^ depth < 2 ^ depth := by simp only [Nat.pow_succ] at hi; omega
          have he : 2 ^ depth + (i - 2 ^ depth) = i := by omega
          simpa only [subtreeAt, he] using ih (i - 2 ^ depth) (fun j => values (2 ^ depth + j)) hb

/-- Traversal composes through a selected subtree independently of hashing. -/
theorem subtree_append (tree selected : Tree α) (above below : List Bool)
    (h : subtreeAt tree above = some selected) :
    subtreeAt tree (above ++ below) = subtreeAt selected below := by
  induction above generalizing tree with
  | nil => simp only [subtreeAt, Option.some.injEq] at h; subst tree; rfl
  | cons side rest ih =>
      cases tree with
      | leaf value => simp [subtreeAt] at h
      | node left right => cases side <;> exact ih _ h

/-- Reaching a subtree gives an actual canonical sibling list, not a digest
match assumption. The sibling hashes are calculated from the same tree. -/
theorem subtree_branch_exists (hash : α → α → α) (tree selected : Tree α)
    (path : List Bool) (h : subtreeAt tree path = some selected) :
    ∃ proof, treeBranch hash tree path = some proof := by
  induction path generalizing tree with
  | nil => exact ⟨[], by cases tree <;> rfl⟩
  | cons side rest ih =>
      cases tree with
      | leaf value => simp [subtreeAt] at h
      | node left right =>
          cases side
          · obtain ⟨proof, hp⟩ := ih left h
            exact ⟨proof ++ [treeDigest hash right], by simp only [treeBranch, hp, Option.map_some]⟩
          · obtain ⟨proof, hp⟩ := ih right h
            exact ⟨proof ++ [treeDigest hash left], by simp only [treeBranch, hp, Option.map_some]⟩

end LidoSRv3.Audit.Source.SszPerfectTree
