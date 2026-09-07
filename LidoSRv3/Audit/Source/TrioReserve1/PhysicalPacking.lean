import LidoSRv3.Audit.Source.TrioReserve1.Live
import LidoSRv3.Audit.Source.TrioReserve1.Packing
import Init.Data.Nat.Bitwise.Lemmas
import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.PhysicalPacking
open Live

/-- Source mask/shift/OR, followed by the EVM word truncation at SSTORE.
UnstructuredStorageExt.sol:44-46; inputs need not fit uint128. -/
def sourcePack (low high : Nat) : Word :=
  word ((high <<< 128) ||| (low &&& (2^128 - 1)))

/-- Numeric packing in the live executor equals the pinned bitwise expression,
including high-counter truncation and arbitrary uint256 inputs. -/
theorem pack_matches_bitwise (low high : Nat) : pack low high = sourcePack low high := by
  apply Verity.Core.Uint256.ext
  unfold sourcePack pack word
  rw [Nat.and_two_pow_sub_one_eq_mod]
  rw [← Nat.shiftLeft_add_eq_or_of_lt (Nat.mod_lt low (by decide : 0 < 2^128)) high]
  rw [Nat.shiftLeft_eq]
  simp only [Verity.Core.Uint256.val_ofNat, Verity.Core.Uint256.modulus,
    Verity.Core.UINT256_MODULUS, width]
  omega

/-- The low physical field is bounded for every world, independently of which
writer produced the word. This does not imply an untruncated accounting sum. -/
theorem physical_low_bound (w : World) (ctx : Context) (slot : Nat) :
    (w.core.readContractSlot ctx.self.val slot).val % width < width :=
  Nat.mod_lt _ (by decide)

theorem physical_high_bound (w : World) (ctx : Context) (slot : Nat) :
    (w.core.readContractSlot ctx.self.val slot).val / width < width := by
  have h := (w.core.readContractSlot ctx.self.val slot).isLt
  unfold width Verity.Core.UINT256_MODULUS at *
  omega

/-- Field projections of the executor's written word retain the source's
truncation. There is no assumption that callers supply a narrow counter. -/
theorem low_pack (low high : Nat) : (pack low high).val % width = low % width := by
  unfold pack word
  simp only [Verity.Core.Uint256.val_ofNat, Verity.Core.Uint256.modulus,
    Verity.Core.UINT256_MODULUS, width]
  omega

theorem high_pack (low high : Nat) : (pack low high).val / width = high % width := by
  unfold pack word
  simp only [Verity.Core.Uint256.val_ofNat, Verity.Core.Uint256.modulus,
    Verity.Core.UINT256_MODULUS, width]
  omega

end LidoSRv3.Audit.Source.TrioReserve1.PhysicalPacking
