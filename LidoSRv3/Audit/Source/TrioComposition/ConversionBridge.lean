import LidoSRv3.Audit.Source.TrioComposition.ParentComposition
import LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion

/-! Relate indexed in-place decoded array conversion to the recursive parent
conversion, including checked failures. Compiler memory remains separate. -/
namespace LidoSRv3.Audit.Source.TrioComposition
open TrioAlloc1
namespace ConversionBridge
open TrioAlloc2.ParentConversion

def prepend (a b : Word) (out : Arrays) : Arrays :=
  ⟨a :: out.allocated, b :: out.newAllocations⟩

theorem positiveRows_cons (n i : Nat) (unit a b : Word) (xs ys : List Word) :
    positiveRows n (i+1) unit ⟨a::xs,b::ys⟩ =
      (positiveRows n i unit ⟨xs,ys⟩).map (prepend a b) := by
  induction n generalizing i xs ys with
  | zero => rfl
  | succ n ih =>
    simp only [positiveRows, TrioAlloc2.ParentConversion.read, List.getElem?_cons_succ, List.set_cons_succ]
    cases hn : ys[i]? <;> simp [hn, bind, Except.bind, Except.map]
    rename_i next
    cases hp : xs[i]? <;> simp [hp, bind, Except.bind, Except.map]
    rename_i previous
    cases hs : TrioAlloc2.checkedSub next previous <;> simp [hs, bind, Except.bind, Except.map]
    rename_i delta
    cases hd : TrioAlloc2.checkedMul delta unit <;> simp [hd, bind, Except.bind, Except.map]
    rename_i deltaWei
    cases hm : TrioAlloc2.checkedMul next unit <;> simp [hm, bind, Except.bind, Except.map]
    rename_i nextWei
    exact ih (i+1) (xs.set i deltaWei) (ys.set i nextWei)

theorem zeroRows_cons (n i : Nat) (unit a b : Word) (xs ys : List Word) :
    zeroRows n (i+1) unit ⟨a::xs,b::ys⟩ =
      (zeroRows n i unit ⟨xs,ys⟩).map (prepend a b) := by
  induction n generalizing i xs ys with
  | zero => rfl
  | succ n ih =>
    simp only [zeroRows, TrioAlloc2.ParentConversion.read, List.getElem?_cons_succ,
      List.set_cons_succ]
    cases hp : xs[i]? <;> simp [hp, bind, Except.bind, Except.map]
    rename_i previous
    cases hm : TrioAlloc2.checkedMul previous unit <;> simp [hm, bind, Except.bind, Except.map]
    rename_i scaled
    cases hn : ys[i]? <;> simp [hn, bind, Except.bind, Except.map]
    exact ih (i+1) (xs.set i TrioAlloc2.zero) (ys.set i scaled)

theorem libraryResult_bind (r : TrioAlloc2.Result α) (f : α → TrioAlloc2.Result β) :
    libraryResult (r >>= f) = (libraryResult r >>= fun x => libraryResult (f x)) := by
  cases r with
  | ok x => rfl
  | error e => cases e <;> rfl

theorem libraryResult_map (r : TrioAlloc2.Result α) (f : α → β) :
    libraryResult (r.map f) = (libraryResult r).map f := by
  cases r with
  | ok x => rfl
  | error e => cases e <;> rfl

theorem mul_bridge (a b : Word) :
    libraryResult (TrioAlloc2.checkedMul a b) = checked (a.val*b.val) := by
  unfold TrioAlloc2.checkedMul checked
  split <;> rfl

theorem sub_bridge (a b : Word) :
    libraryResult (TrioAlloc2.checkedSub a b) = TrioAlloc1.checkedSub a.val b.val := by
  have bound : a.val-b.val < 2^256 := Nat.lt_of_le_of_lt (Nat.sub_le ..) a.isLt
  by_cases h : b.val ≤ a.val
  · simp [TrioAlloc2.checkedSub, TrioAlloc1.checkedSub, h, checked, bound, libraryResult]
  · simp [TrioAlloc2.checkedSub, TrioAlloc1.checkedSub, h, libraryResult]

theorem div_bridge (a b : Word) :
    libraryResult (TrioAlloc2.checkedDiv a b) = TrioAlloc1.checkedDiv a b := by
  have bound : a.val/b.val < 2^256 := Nat.lt_of_le_of_lt (Nat.div_le_self ..) a.isLt
  unfold TrioAlloc2.checkedDiv TrioAlloc1.checkedDiv
  split
  · rfl
  · simp [libraryResult, word, Nat.mod_eq_of_lt bound]

def arrays (pair : List Word × List Word) : Arrays := ⟨pair.1,pair.2⟩

theorem bind_ok (x : α) (f : α → Except ε β) : (Except.ok x >>= f) = f x := rfl

theorem positive_equiv (n : Nat) (unit : Word) (xs ys : List Word)
    (hx : xs.length = n) (hy : ys.length = n) :
    libraryResult (positiveRows n 0 unit ⟨xs,ys⟩) =
      (convertPositive unit n xs ys).map arrays := by
  induction n generalizing xs ys with
  | zero =>
    have ex : xs = [] := List.length_eq_zero_iff.mp hx
    have ey : ys = [] := List.length_eq_zero_iff.mp hy
    subst xs; subst ys; rfl
  | succ n ih =>
    cases xs with
    | nil => simp at hx
    | cons x xs =>
      cases ys with
      | nil => simp at hy
      | cons y ys =>
        have tx : xs.length = n := by simpa using hx
        have ty : ys.length = n := by simpa using hy
        simp only [positiveRows, TrioAlloc2.ParentConversion.read, List.getElem?_cons_zero,
          List.set_cons_zero, bind_ok, convertPositive, readHead, List.tail_cons]
        simp only [libraryResult_bind, sub_bridge, mul_bridge]
        simp only [bind, Except.bind]
        cases hs : TrioAlloc1.checkedSub y.val x.val <;> simp [hs, Except.map]
        rename_i delta
        cases hd : checked (delta.val*unit.val) <;> simp [hd, Except.map]
        rename_i deltaWei
        cases hm : checked (y.val*unit.val) <;> simp [hm, Except.map]
        rename_i nextWei
        rw [positiveRows_cons, libraryResult_map, ih xs ys tx ty]
        cases convertPositive unit n xs ys <;> rfl

theorem zero_equiv (n : Nat) (unit : Word) (xs ys : List Word)
    (hx : xs.length = n) (hy : ys.length = n) :
    libraryResult (zeroRows n 0 unit ⟨xs,ys⟩) =
      (convertZero unit n xs).map arrays := by
  induction n generalizing xs ys with
  | zero =>
    have ex : xs = [] := List.length_eq_zero_iff.mp hx
    have ey : ys = [] := List.length_eq_zero_iff.mp hy
    subst xs; subst ys; rfl
  | succ n ih =>
    cases xs with
    | nil => simp at hx
    | cons x xs =>
      cases ys with
      | nil => simp at hy
      | cons y ys =>
        have tx : xs.length = n := by simpa using hx
        have ty : ys.length = n := by simpa using hy
        simp only [zeroRows, TrioAlloc2.ParentConversion.read, List.getElem?_cons_zero,
          List.set_cons_zero, bind_ok, convertZero, readHead, List.tail_cons]
        simp only [libraryResult_bind, mul_bridge]
        simp only [bind, Except.bind]
        cases hm : checked (x.val*unit.val) <;> simp [hm, Except.map]
        rename_i scaled
        rw [zeroRows_cons, libraryResult_map, ih xs ys tx ty]
        cases convertZero unit n xs <;> rfl

def output (value : Output) : ParentOutput :=
  ⟨value.totalAllocated, value.arrays.allocated, value.arrays.newAllocations⟩

/-- Total multiplication and all ordered row operations agree on every outcome. -/
theorem positive_conversion_equiv (n : Nat) (unit total : Word) (xs ys : List Word)
    (hx : xs.length = n) (hy : ys.length = n) :
    libraryResult ((positive n unit total ⟨xs,ys⟩).map output) =
      (do
        let totalWei ← checked (total.val*unit.val)
        let rows ← convertPositive unit n xs ys
        pure (⟨totalWei, rows.1, rows.2⟩ : ParentOutput)) := by
  rw [libraryResult_map]
  simp only [positive, libraryResult_bind, mul_bridge]
  cases hm : checked (total.val*unit.val) <;> simp [hm, bind, Except.bind, Except.map]
  rename_i totalWei
  rw [positive_equiv n unit xs ys hx hy]
  cases convertPositive unit n xs ys <;> rfl

/-- Zero demand agrees including late multiplication failure. -/
theorem zero_conversion_equiv (n : Nat) (unit : Word) (xs : List Word)
    (hx : xs.length = n) :
    libraryResult ((zeroDemand n unit xs).map output) =
      (convertZero unit n xs).map (fun rows =>
        (⟨word 0, rows.1, rows.2⟩ : ParentOutput)) := by
  rw [libraryResult_map]
  simp only [zeroDemand, libraryResult_bind]
  rw [zero_equiv n unit xs (List.replicate n TrioAlloc2.zero) hx (List.length_replicate ..)]
  cases convertZero unit n xs <;> rfl

/-- Actual producer and consumer outcomes supply both array lengths. No
successful conversion, checked multiplication or subtraction is assumed. -/
theorem producer_consumer_conversion_equiv
    (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (produced : CapacityOutput)
    (producer : produce layout storage oracle input before = (.ok produced, after))
    (allocated : TrioAlloc2.StepOutput)
    (consumer : TrioAlloc2.allocate produced.allocations produced.capacities
      input.depositsToAllocate = .ok allocated) :
    libraryResult ((positive (storage (countSlot layout)).val input.config.maxEBType1
      allocated.amount ⟨produced.allocations,allocated.buckets⟩).map output) =
      (do
        let totalWei ← checked (allocated.amount.val*input.config.maxEBType1.val)
        let rows ← convertPositive input.config.maxEBType1 (storage (countSlot layout)).val
          produced.allocations allocated.buckets
        pure (⟨totalWei, rows.1, rows.2⟩ : ParentOutput)) := by
  have oldLength := (producer_length_from_storage layout storage oracle input before after
    produced producer).1
  have freshLength := TrioAlloc2.allocate_preserves_length _ _ _ _ consumer
  exact positive_conversion_equiv _ _ _ _ _ oldLength (freshLength.trans oldLength)

#print axioms positive_conversion_equiv
#print axioms zero_conversion_equiv
#print axioms producer_consumer_conversion_equiv

#print axioms positive_equiv
#print axioms zero_equiv

end ConversionBridge
end LidoSRv3.Audit.Source.TrioComposition
