import LidoSRv3.Audit.Source.Topup2Uint64BoundsSource

/-! # StakingRouter.topUp:706 gwei-rounding source model

**General rule (Thomas 2026-09-13, real derivation of the pinned
StakingRouter.topUp:706 gwei-rounding step.)**

Chantier 4 (per mandate): the pinned StakingRouter.topUp at line 706
rounds each per-key limit DOWN to the nearest gwei boundary before
gating on the block cap. This composition names the rounding step
as `roundDownToGwei wei = wei - (wei % 10^9)`.

**Status:** first real derivation of the pinned line-706 rounding
past a free Nat. -/

namespace LidoSRv3.Audit.Source.Topup2RoundingSource

open LidoSRv3.Audit.Source.Topup2Uint64BoundsSource

/-- Pinned rounding-down-to-gwei step. -/
def roundDownToGwei (wei : Nat) : Nat :=
  wei - (wei % gweiToWeiFactor)

/-- The rounded value is a multiple of gweiToWeiFactor. -/
theorem roundDownToGwei_mod_zero (wei : Nat) :
    roundDownToGwei wei % gweiToWeiFactor = 0 := by
  unfold roundDownToGwei
  have hMod : wei % gweiToWeiFactor ≤ wei := Nat.mod_le wei gweiToWeiFactor
  have hSub : wei - wei % gweiToWeiFactor
              = gweiToWeiFactor * (wei / gweiToWeiFactor) := by
    have hDivMod : wei = gweiToWeiFactor * (wei / gweiToWeiFactor)
                        + wei % gweiToWeiFactor := (Nat.div_add_mod wei gweiToWeiFactor).symm
    omega
  rw [hSub]
  exact Nat.mul_mod_right gweiToWeiFactor (wei / gweiToWeiFactor)

/-- The rounded value is at most the original. -/
theorem roundDownToGwei_le (wei : Nat) : roundDownToGwei wei ≤ wei := by
  unfold roundDownToGwei
  exact Nat.sub_le wei (wei % gweiToWeiFactor)

/-- If wei is already a multiple of gwei, rounding is idempotent. -/
theorem roundDownToGwei_of_mod_zero
    {wei : Nat} (hMod : wei % gweiToWeiFactor = 0) :
    roundDownToGwei wei = wei := by
  unfold roundDownToGwei
  rw [hMod]
  simp

end LidoSRv3.Audit.Source.Topup2RoundingSource
