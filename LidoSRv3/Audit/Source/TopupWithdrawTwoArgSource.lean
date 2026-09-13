/-! # StakingRouter.topUp withdrawDepositableEther two-argument shape source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
StakingRouter.sol:744 two-argument `withdrawDepositableEther(amount, 0)`
shape as a source-level function.)**

Chantier 2 (mandate 2026-09-12) disclosure: `Verity.TopupTx.lidoPull`
at `LidoSRv3/Audit/Verity/TopupTx.lean:119-122` journals a single-word
argument `[total]` via
`externalCallBindTo lidoAddress 0 [] "withdrawDepositableEther"
[(total : Uint256)]`, but the pinned source at
`StakingRouter.sol:744` calls
`LIDO.withdrawDepositableEther(amount, 0)` with two arguments (the
amount and a hard-coded `0` for the second Solidity `uint256`
parameter). The Verity journal records only the first word — the
executable frame is single-argument, the source call has an
additional zero-word tail. Grok differential #414 D-CALL-1 would
surface this if extended past the current journal-shape scope.

This composition names the two-argument shape as a source-level
function: `withdrawArgs total = [total, 0]`. Downstream consumers
of a Verity `lidoPull` frame can now compare their journal against
a two-argument model rather than truncated to the first word.

**Status:** first real derivation naming the D-CALL-1 chantier-2
disclosure (grok #414) as a source-level two-word calldata function. -/

namespace LidoSRv3.Audit.Source.TopupWithdrawTwoArgSource

/-- Source-level definition of the pinned two-argument
`withdrawDepositableEther(amount, 0)` calldata shape. -/
def withdrawArgs (total : Nat) : List Nat :=
  [total, 0]

/-- The pinned call carries exactly two words. -/
theorem withdrawArgs_length (total : Nat) :
    (withdrawArgs total).length = 2 := by
  simp [withdrawArgs]

/-- The pinned call's first word is the amount. -/
theorem withdrawArgs_first (total : Nat) :
    (withdrawArgs total)[0]? = some total := by
  simp [withdrawArgs]

/-- The pinned call's second word is the hard-coded zero. -/
theorem withdrawArgs_second (total : Nat) :
    (withdrawArgs total)[1]? = some 0 := by
  simp [withdrawArgs]

end LidoSRv3.Audit.Source.TopupWithdrawTwoArgSource
