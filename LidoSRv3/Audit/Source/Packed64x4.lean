import LidoSRv3.Audit.Source.TrioAlloc1.Bytes

/-!
[Packed64x4](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/lib/Packed64x4.sol)
at the four field positions used by NOR. Division/remainder express the source
shift/mask operations. Indices outside 0..3 are outside this interface.
The setters check overflow before modifying the word; SafeMath add/sub errors
precede the packed-width check. These are 0.4.24 Error(string) failures.
-/
namespace LidoSRv3.Audit.Source.Packed64x4
open TrioAlloc1

def get (packed : Word) (index : Fin 4) : Word :=
  ⟨field packed (64 * index.val) 64,
    Nat.lt_trans (Nat.mod_lt _ (by decide)) (by decide)⟩

theorem get_width (packed : Word) (index : Fin 4) :
    (get packed index).val < 2^64 := Nat.mod_lt _ (by decide)

/-- Standard Error(string) bytes, shared by the getter and packed writers. -/
def errorString (message : String) : Bytes :=
  let raw := message.toUTF8.data.toList.map fun b => byte b.toNat
  encodeBE 4 0x08c379a0 ++ encodeWord (word 32) ++ encodeWord (word raw.length) ++
    raw ++ List.replicate ((32 - raw.length % 32) % 32) (byte 0)

def replace (packed : Word) (index : Fin 4) (value : Fin (2^64)) : Word :=
  word (packed.val % 2^(64 * index.val) + value.val * 2^(64 * index.val) +
    packed.val / 2^(64 * (index.val+1)) * 2^(64 * (index.val+1)))

def set (packed : Word) (index : Fin 4) (value : Word) : Except Bytes Word :=
  if bound : value.val < 2^64 then .ok (replace packed index ⟨value.val, bound⟩)
  else .error (errorString "PACKED_OVERFLOW")

def add (packed : Word) (index : Fin 4) (value : Word) : Except Bytes Word :=
  let sum := (get packed index).val + value.val
  if sum < 2^256 then set packed index (word sum)
  else .error (errorString "MATH_ADD_OVERFLOW")

def sub (packed : Word) (index : Fin 4) (value : Word) : Except Bytes Word :=
  if value.val ≤ (get packed index).val then
    set packed index (word ((get packed index).val - value.val))
  else .error (errorString "MATH_SUB_UNDERFLOW")

theorem get_replace (packed : Word) (index : Fin 4) (value : Fin (2^64)) :
    (get (replace packed index value) index).val = value.val := by
  have hp := packed.isLt
  have hv := value.isLt
  have indices : index.val = 0 ∨ index.val = 1 ∨ index.val = 2 ∨ index.val = 3 := by
    have := index.isLt
    omega
  rcases indices with hi | hi | hi | hi <;>
    simp only [get, replace, field, word, hi] <;> omega

/-- Updating one packed counter leaves every other counter unchanged. -/
theorem get_replace_other (packed : Word) (index other : Fin 4) (value : Fin (2^64))
    (different : other ≠ index) :
    get (replace packed index value) other = get packed other := by
  have hp := packed.isLt
  have hv := value.isLt
  have hi : index.val = 0 ∨ index.val = 1 ∨ index.val = 2 ∨ index.val = 3 := by
    have := index.isLt
    omega
  have ho : other.val = 0 ∨ other.val = 1 ∨ other.val = 2 ∨ other.val = 3 := by
    have := other.isLt
    omega
  have ne : other.val ≠ index.val := fun equal => different (Fin.ext equal)
  apply Fin.ext
  rcases hi with hi | hi | hi | hi <;> rcases ho with ho | ho | ho | ho <;>
    simp_all only [get, replace, field, word] <;> omega

attribute [local irreducible] replace

theorem set_success (packed : Word) (index : Fin 4) (value result : Word)
    (success : set packed index value = .ok result) :
    (get result index).val = value.val ∧
      ∀ other, other ≠ index → get result other = get packed other := by
  unfold set at success
  split at success
  · cases success
    exact ⟨get_replace _ _ _, fun other different => get_replace_other _ _ _ _ different⟩
  · cases success

theorem add_success (packed : Word) (index : Fin 4) (value result : Word)
    (success : add packed index value = .ok result) :
    (get result index).val = (get packed index).val + value.val ∧
      ∀ other, other ≠ index → get result other = get packed other := by
  dsimp only [add] at success
  split at success
  · have spec := set_success _ _ _ _ success
    refine ⟨?_, spec.2⟩
    simpa only [word, Nat.mod_eq_of_lt ‹_›] using spec.1
  · cases success

theorem sub_success (packed : Word) (index : Fin 4) (value result : Word)
    (success : sub packed index value = .ok result) :
    (get result index).val + value.val = (get packed index).val ∧
      ∀ other, other ≠ index → get result other = get packed other := by
  unfold sub at success
  split at success
  · have spec := set_success _ _ _ _ success
    have bound : (get packed index).val - value.val < 2^256 :=
      Nat.lt_of_le_of_lt (Nat.sub_le _ _) (get packed index).isLt
    have equation : (get result index).val = (get packed index).val - value.val := by
      simpa only [word, Nat.mod_eq_of_lt bound] using spec.1
    exact ⟨by omega, spec.2⟩
  · cases success

end LidoSRv3.Audit.Source.Packed64x4
