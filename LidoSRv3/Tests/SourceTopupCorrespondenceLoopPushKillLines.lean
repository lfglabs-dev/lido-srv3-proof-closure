import LidoSRv3.Audit.Source.TopupCorrespondence

/-!
Kill-lines pinning `Source.TopupCorrespondence.loopPushed` (the
BeaconChainDepositor.sol:79-107 push loop) and `allocationLoop`
(StakingRouter.sol:722-734 allocation guards) at Lido core pin
17005714.
-/

namespace LidoSRv3.Tests.SourceTopupCorrespondenceLoopPushKillLines

open LidoSRv3.Audit.SolidityTopup

/-! ## `loopPushed` — BeaconChainDepositor.sol:79-107. -/

theorem loopPushed_empty_pubkeys :
    loopPushed [] [] = 0 := rfl

theorem loopPushed_empty_amounts :
    loopPushed [48] [] = 0 := rfl

theorem loopPushed_zero_amount_skipped :
    loopPushed [48] [0] = 0 := rfl

theorem loopPushed_single_positive :
    loopPushed [48] [100] = 100 := rfl

theorem loopPushed_mix_of_zero_and_positive :
    loopPushed [48, 48] [100, 0] = 100 := by decide

theorem loopPushed_two_positive :
    loopPushed [48, 48] [100, 200] = 300 := by decide

/-! ## `allocationLoop` — StakingRouter.sol:722-734 guard loop. -/

theorem allocationLoop_empty_allocs (cfg : SourceTopupConfig) (limits : List Nat) :
    allocationLoop cfg [] limits = none := rfl

theorem allocationLoop_empty_limits_alignment_fails
    (cfg : SourceTopupConfig)
    (hGwei : cfg.gwei ≠ 0)
    (hMod : 1 % cfg.gwei ≠ 0) :
    allocationLoop cfg [1] [] = some .revertAmountNotAlignedToGwei := by
  simp [allocationLoop, hMod]

theorem allocationLoop_empty_limits_index_oob
    (cfg : SourceTopupConfig)
    (hZero : 0 % cfg.gwei = 0) :
    allocationLoop cfg [0] [] = some .revertTopUpLimitIndexOutOfBounds := by
  simp [allocationLoop, hZero]

theorem allocationLoop_alignment_first :
    allocationLoop pinnedConfig [1] [1000000000] =
      some .revertAmountNotAlignedToGwei := by decide

theorem allocationLoop_exceeds_limit :
    allocationLoop pinnedConfig [2000000000] [1000000000] =
      some .revertAllocationExceedsLimit := by decide

theorem allocationLoop_success :
    allocationLoop pinnedConfig [1000000000] [2000000000] = none := by decide

end LidoSRv3.Tests.SourceTopupCorrespondenceLoopPushKillLines
