import LidoSRv3.Audit.Source.TopupCorrespondence

/-!
Kill-lines pinning P-TOPUP-1 `Source.TopupCorrespondence` block-cap
identities and `Outcome` projection truth-tables at Lido core pin
17005714 (StakingRouter.sol:696-706, source lines 722-734).
-/

namespace LidoSRv3.Tests.SourceTopupCorrespondenceBlockCapKillLines

open LidoSRv3.Audit.SolidityTopup

/-! ## `uint256Modulus` — pinned to 2^256. -/

theorem uint256Modulus_val : uint256Modulus = 2 ^ 256 := rfl

/-! ## `maxTopUpPerBlockWei` is the parametric product of the two config /
    input words (StakingRouter.sol:696). -/

theorem maxTopUpPerBlockWei_reduces
    (cfg : SourceTopupConfig) (inp : SourceTopupInput) :
    maxTopUpPerBlockWei cfg inp = inp.maxTopUpPerBlockGwei * cfg.gwei := rfl

/-! ## `smDepositableEthAmount` is a min of the two source-line-700 quantities. -/

theorem smDepositableEthAmount_reduces
    (cfg : SourceTopupConfig) (inp : SourceTopupInput) :
    smDepositableEthAmount cfg inp =
      min inp.moduleAllocationEth (maxTopUpPerBlockWei cfg inp) := rfl

/-! ## `smDepositableEthAmountRounded` — StakingRouter.sol:706 rounding. -/

theorem smDepositableEthAmountRounded_reduces
    (cfg : SourceTopupConfig) (inp : SourceTopupInput) :
    smDepositableEthAmountRounded cfg inp =
      smDepositableEthAmount cfg inp -
        smDepositableEthAmount cfg inp % cfg.gwei := rfl

/-! ## `totalAllocated` reduces to `allocSum inp.allocations`. -/

theorem totalAllocated_reduces (inp : SourceTopupInput) :
    totalAllocated inp = allocSum inp.allocations := rfl

/-! ## `Outcome.reverts` truth-table across all committed vs revert branches. -/

theorem outcome_committedNoTopUp_not_reverts :
    Outcome.reverts .committedNoTopUp = false := rfl

theorem outcome_committedTopUp_not_reverts :
    Outcome.reverts (.committedTopUp 0 0 0 0) = false := rfl

theorem outcome_revertLidoZeroAmount_reverts :
    Outcome.reverts .revertLidoZeroAmount = true := rfl

theorem outcome_revertArrayLengthMismatch_reverts :
    Outcome.reverts .revertArrayLengthMismatch = true := rfl

theorem outcome_revertInvalidPublicKeyLength_reverts :
    Outcome.reverts .revertInvalidPublicKeyLength = true := rfl

theorem outcome_revertAmountTooLarge_reverts :
    Outcome.reverts .revertAmountTooLarge = true := rfl

theorem outcome_revertInsufficientRouterBalance_reverts :
    Outcome.reverts .revertInsufficientRouterBalance = true := rfl

theorem outcome_revertAssertBalanceUnchanged_reverts :
    Outcome.reverts .revertAssertBalanceUnchanged = true := rfl

/-! ## `Outcome.pulled` and `Outcome.pushed` on the committed branches. -/

theorem outcome_pulled_committedTopUp :
    Outcome.pulled (.committedTopUp 5 100 200 300) = 100 := rfl

theorem outcome_pushed_committedTopUp :
    Outcome.pushed (.committedTopUp 5 100 200 300) = 200 := rfl

theorem outcome_pulled_committedNoTopUp :
    Outcome.pulled .committedNoTopUp = 0 := rfl

theorem outcome_pushed_committedNoTopUp :
    Outcome.pushed .committedNoTopUp = 0 := rfl

end LidoSRv3.Tests.SourceTopupCorrespondenceBlockCapKillLines
