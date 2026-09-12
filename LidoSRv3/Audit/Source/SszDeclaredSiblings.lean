import LidoSRv3.Audit.Guarantees.PSsz1CompiledClEntry
set_option autoImplicit false
set_option maxRecDepth 4096
set_option maxHeartbeats 800000
namespace LidoSRv3.Audit.Source.SszDeclaredSiblings
open EvmYul EvmYul.EVM SszProofCommitted SszWrapperIndex

/-- Fixed-stride modular cursor fact. After a first accepted step, every
intermediate declared step is below the same modular endpoint. Both immediate
wrap and ordinary offsets are admitted; a later wrap forces first-step exit. -/
theorem cursor_arithmetic (a n j : Nat) (ha : a < UInt256.size)
    (hn : 2 ≤ n) (hfit : 32*n < UInt256.size)
    (first : (a+32) % UInt256.size < (a+32*n) % UInt256.size)
    (hj : 1 ≤ j) (hjn : j < n) :
    (a+32*j) % UInt256.size < (a+32*n) % UInt256.size := by
  unfold UInt256.size at *
  omega

/-- Complete ABI-declared indexed view; independent of loop termination. Loads
retain zero padding and modular uint256 offsets, including signed-tail cases. -/
def declaredWords (raw : ByteArray) (offset : UInt256) (count : Nat) : List UInt256 :=
  (List.range count).map (fun j => rawWord raw (offset + UInt256.ofNat (32*j)))

theorem declared_length (raw : ByteArray) (offset : UInt256) (count : Nat) :
    (declaredWords raw offset count).length = count := by simp [declaredWords]

def advance (offset : UInt256) (j : Nat) : UInt256 := offset + UInt256.ofNat (32*j)

theorem advance_zero (offset : UInt256) : advance offset 0 = offset := by
  apply congrArg UInt256.mk
  apply Fin.ext
  change (offset.toNat + 0) % UInt256.size = offset.toNat
  simpa only [UInt256.toNat, Nat.add_zero] using Nat.mod_eq_of_lt offset.val.isLt

theorem advance_succ (offset : UInt256) (j : Nat) :
    advance (offset + UInt256.ofNat 32) j = advance offset (j+1) := by
  apply congrArg UInt256.mk
  apply Fin.ext
  change ((offset.toNat + 32 % UInt256.size) % UInt256.size + (32*j) % UInt256.size) % UInt256.size =
    (offset.toNat + (32*(j+1)) % UInt256.size) % UInt256.size
  simp only [Nat.add_mod_mod, Nat.mod_add_mod]
  congr 1
  omega

theorem end_eq (offset : UInt256) (count : Nat) : endOffset offset count = advance offset count := by
  unfold endOffset advance
  apply congrArg (fun x : UInt256 => offset+x)
  apply congrArg UInt256.mk
  apply Fin.ext
  change ((count % UInt256.size) <<< (5 % UInt256.size)) % UInt256.size = (32*count) % UInt256.size
  norm_num only [UInt256.size, Nat.shiftLeft_eq, Nat.reduceMod, Nat.reducePow]
  omega

theorem declared_succ (raw : ByteArray) (offset : UInt256) (count : Nat) :
    declaredWords raw offset (count+1) = rawWord raw offset :: declaredWords raw (offset + UInt256.ofNat 32) count := by
  simp only [declaredWords,List.range_succ_eq_map,List.map_cons,List.map_map]
  rw [show offset + UInt256.ofNat (32*0) = offset from advance_zero offset]
  congr 1
  apply List.map_congr_left
  intro j hj
  exact congrArg (rawWord raw) (advance_succ offset j).symm

/-- Loop/list identity from actual cursor comparisons. These comparisons are
later derived from the first comparison and the executed count guard. -/
theorem all_steps (rounds : Nat) (raw : ByteArray) (offset ending : UInt256)
    (hsteps : ∀ j, 1 ≤ j → j < rounds → advance offset j < ending) :
    proofWords rounds raw offset ending = declaredWords raw offset rounds := by
  induction rounds generalizing offset with
  | zero => rfl
  | succ rounds ih =>
    rw [declared_succ]
    cases rounds with
    | zero => simp [proofWords,declaredWords]
    | succ n =>
      have hc : offset + UInt256.ofNat 32 < ending := hsteps 1 (by omega) (by omega)
      simp only [proofWords,hc,decide_true,if_true]
      congr 1
      apply ih
      intro j hj hjn
      rw [advance_succ]
      exact hsteps (j+1) (by omega) (by omega)

/-- Full domain dichotomy: the cursor consumes one word, or every ABI-declared
indexed word. No nonwrapping or canonical-offset assumption is imposed. -/
theorem cursor_dichotomy (raw : ByteArray) (offset : UInt256) (count : Nat)
    (hn : 2 ≤ count) (hfit : 32*count < UInt256.size) :
    proofWords count raw offset (endOffset offset count) = [rawWord raw offset] ∨
    proofWords count raw offset (endOffset offset count) = declaredWords raw offset count := by
  by_cases hc : offset + UInt256.ofNat 32 < endOffset offset count
  · right
    apply all_steps
    intro j hj hjn
    rw [end_eq] at hc ⊢
    have ha := offset.val.isLt
    change (offset.toNat + 32 % UInt256.size) % UInt256.size <
      (offset.toNat + (32*count) % UInt256.size) % UInt256.size at hc
    change (offset.toNat + (32*j) % UInt256.size) % UInt256.size <
      (offset.toNat + (32*count) % UInt256.size) % UInt256.size
    simp only [Nat.add_mod_mod] at hc ⊢
    exact cursor_arithmetic offset.toNat count j ha hn hfit hc hj hjn
  · left
    cases count with
    | zero => omega
    | succ n => simp only [proofWords,hc,decide_false,Bool.false_eq_true,if_false]

theorem declared_get (raw : ByteArray) (offset : UInt256) (count j : Nat) (hj : j < count) :
    (declaredWords raw offset count)[j]? = some (rawWord raw (advance offset j)) := by
  simp only [declaredWords,List.getElem?_map,List.getElem?_range hj,Option.map_some,advance]

/-- The actual sourceWrapper always appends beneath header index11, even for
arbitrary accepted constructor configurations. Its uint248 result bounds depth. -/
theorem wrapper_depth (cfg : Configuration) (slot : Fin (2^64))
    (index : Fin wordModulus) (gi : PackedIndex) (h : sourceWrapper cfg slot index = .ok gi) :
    3 ≤ gi.index.val.log2 ∧ gi.index.val.log2 ≤ 247 := by
  obtain ⟨_,he,_⟩ := wrapper_success cfg slot index gi h
  have hp := Nat.two_pow_pos (((selected cfg slot).index.val + index.val).log2)
  have hlo : 11 ≤ gi.index.val := by rw [he]; unfold appendIndex; omega
  have hn : gi.index.val ≠ 0 := by omega
  have hmax : gi.index.val.log2 < 248 := (Nat.log2_lt hn).mpr gi.index.isLt
  have hmin : 3 ≤ gi.index.val.log2 := by
    by_contra hc
    have hh : gi.index.val < 2^3 := (Nat.log2_lt hn).mp (by omega)
    omega
  omega

/-- Successful actual branch depth excludes the only partial-list alternative.
The ABI guard supplies the word-fit fact internally; it is not a public premise. -/
theorem complete_of_branch (raw : ByteArray) (offset : UInt256) (count : Nat)
    (cfg : Configuration) (slot : Fin (2^64)) (index : Fin wordModulus) (gi : PackedIndex)
    (leaf root : UInt256) (hn : 2 ≤ count) (h64 : count ≤ 2^64-1)
    (hgi : sourceWrapper cfg slot index = .ok gi)
    (hb : SszProofFold.Branch SszProofCalldataStep.ffiPair gi.index.val leaf
      (proofWords count raw offset (endOffset offset count)) root) :
    proofWords count raw offset (endOffset offset count) = declaredWords raw offset count ∧
    count = gi.index.val.log2 ∧ 3 ≤ count ∧ count ≤ 247 := by
  have hfit : 32*count < UInt256.size := by unfold UInt256.size; omega
  obtain ⟨hl,hu⟩ := wrapper_depth cfg slot index gi hgi
  have hd := SszProofFold.branch_depth hb
  rcases cursor_dichotomy raw offset count hn hfit with he | he
  · rw [he] at hd
    simp only [List.length_cons,List.length_nil] at hd
    omega
  · have hn' : count = gi.index.val.log2 := by rw [he,declared_length] at hd; exact hd.symm
    exact ⟨he,hn',by omega,by omega⟩

/-- The earlier slot/proposer comparison points into the same complete declared
indexed list. No contiguous host-buffer or canonical ABI layout is asserted. -/
theorem penultimate (context : EVM.State) (offset : UInt256) (count : Nat) (expected : UInt256)
    (hn : 2 ≤ count)
    (hs : context.calldataload (offset + UInt256.ofNat ((count-2)*32)) = expected) :
    (declaredWords context.executionEnv.calldata offset count)[count-2]? = some expected := by
  rw [declared_get _ _ _ _ (by omega)]
  change some (context.calldataload (offset + UInt256.ofNat (32*(count-2)))) = some expected
  rw [Nat.mul_comm 32 (count-2),hs]

#print axioms declared_get
#print axioms wrapper_depth
#print axioms complete_of_branch
#print axioms penultimate

#print axioms advance_zero
#print axioms advance_succ
#print axioms end_eq
#print axioms declared_succ
#print axioms all_steps
#print axioms cursor_dichotomy

#print axioms cursor_arithmetic
#print axioms declared_length
end LidoSRv3.Audit.Source.SszDeclaredSiblings
