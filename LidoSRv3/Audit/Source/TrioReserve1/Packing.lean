import Lean.Elab.Tactic.Omega

/-!
Physical word arithmetic for pinned Lido `UnstructuredStorageExt.sol:20-46`.
The setters truncate: there is no uint128-overflow guard in that library.
These lemmas describe numeric projections; the bitwise/Verity storage relation
is a separate obligation, not asserted here.
-/
namespace LidoSRv3.Audit.Source.TrioReserve1.Packing

def width : Nat := 2 ^ 128

def low (word : Nat) : Nat := word % width

def high (word : Nat) : Nat := word / width % width

/-- Numeric interpretation of `(high << 128) | (low & UINT128_LOW_MASK)`
stored into an EVM word. Both inputs truncate to 128 bits. -/
def pack (lo hi : Nat) : Nat := lo % width + width * (hi % width)

theorem width_pos : 0 < width := by decide

theorem low_bound (word : Nat) : low word < width :=
  Nat.mod_lt _ width_pos

theorem high_bound (word : Nat) : high word < width :=
  Nat.mod_lt _ width_pos

theorem low_pack (lo hi : Nat) : low (pack lo hi) = lo % width := by
  simp [low, pack, Nat.add_mod]

theorem high_pack (lo hi : Nat) : high (pack lo hi) = hi % width := by
  simp [high, pack, Nat.add_mul_div_left _ _ width_pos,
    Nat.div_eq_of_lt (Nat.mod_lt lo width_pos)]

/-- A concrete counterexample to interpreting the packed setter as a checked cast. -/
theorem high_wrap : high (pack 7 width) = 0 := by
  simp [high_pack]

/-- Arbitrarily large counters cannot affect the companion buffered field. -/
theorem companion_preserved (buffer counter : Nat) :
    low (pack buffer counter) = low buffer := low_pack _ _

end LidoSRv3.Audit.Source.TrioReserve1.Packing
