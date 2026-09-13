import LidoSRv3.Audit.Source.TrioReserve1.Packing

/-! # Kill-lines for `TrioReserve1.Packing` uint128 pack/unpack

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Lido UnstructuredStorageExt.sol:20-46 packed uint128
pair pack/low/high semantics. -/

namespace LidoSRv3.Tests.TrioReserve1PackingKillLines

open LidoSRv3.Audit.Source.TrioReserve1.Packing

/-- **Kill-line: `width = 2^128`.**

A mutant that changed the width would break the packed layout. -/
theorem width_pinned : width = 2 ^ 128 := rfl

/-- **Kill-line: `low` extracts modulo width.** -/
theorem low_composition (w : Nat) :
    low w = w % width := rfl

/-- **Kill-line: `high` extracts as `word / width % width`.** -/
theorem high_composition (w : Nat) :
    high w = w / width % width := rfl

/-- **Kill-line: `pack lo hi = lo % width + width * (hi % width)`
composition.** -/
theorem pack_composition (lo hi : Nat) :
    pack lo hi = lo % width + width * (hi % width) := rfl

/-- **Kill-line: `low (pack lo hi) = lo % width` round-trip.** -/
theorem low_pack_kill (lo hi : Nat) :
    low (pack lo hi) = lo % width :=
  low_pack lo hi

/-- **Kill-line: `high (pack lo hi) = hi % width` round-trip.** -/
theorem high_pack_kill (lo hi : Nat) :
    high (pack lo hi) = hi % width :=
  high_pack lo hi

/-- **Kill-line: overflow of high wraps to zero.** -/
theorem high_wrap_kill :
    high (pack 7 width) = 0 :=
  high_wrap

/-- **Kill-line: `pack 0 0 = 0` (identity zero).** -/
theorem pack_zero : pack 0 0 = 0 := rfl

/-- **Kill-line: `pack 1 0 = 1` (low-word only).** -/
theorem pack_one_zero : pack 1 0 = 1 := rfl

/-- **Kill-line: `pack 0 1 = 2^128` (high-word only).** -/
theorem pack_zero_one : pack 0 1 = 2 ^ 128 := by decide

#print axioms width_pinned
#print axioms low_composition
#print axioms high_composition
#print axioms pack_composition
#print axioms low_pack_kill
#print axioms high_pack_kill
#print axioms high_wrap_kill
#print axioms pack_zero_one

end LidoSRv3.Tests.TrioReserve1PackingKillLines
