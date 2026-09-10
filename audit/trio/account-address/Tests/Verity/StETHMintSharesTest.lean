import StETHMintShares

namespace AccountAddress.Tests.Verity.StETHMintSharesTest

open AccountAddress.ReportWriteFee
open AccountAddress.StETHMintShares

/-- A concrete packed word with total shares `10` and an independent external
share payload `4` in the high half. -/
private def before : State := {
  storage := Core.write ⟨[]⟩ totalSharesPosition ⟨4 * two128 + 10, by
    have : 4 * two128 + 10 < two256 := by decide
    exact this⟩
  shares := fun account => if account = 7 then 5 else 0
  internalEther := 100
  accounting := 7
  steth := 8
  stopped := false
}

/-- Lido's emission reads the post-mint rate: `(2 * 100) / (12 - 4) = 25`.
The high half remains `4`, the recipient mapping entry becomes `7`, and an
unrelated mapping key remains zero. -/
example : match mintShares 7 7 2 before with
  | .committed post events =>
      totalShares post = 12 ∧ externalShares post = 4 ∧
      post.shares 7 = 7 ∧ post.shares 9 = 0 ∧
      events = [.transfer 0 7 25, .transferShares 0 7 2]
  | .reverted _ _ => False := by decide

/-- `_auth` is the outermost Lido.sol:895 guard. -/
example : mintShares 6 0 1 before = .reverted .notAccounting before := by decide

/-- `_whenNotStopped` runs before `_mintShares`' recipient checks. -/
example : mintShares 7 0 1 { before with stopped := true } =
    .reverted .stopped { before with stopped := true } := by decide

/-- `_getTotalShares().add` reverts before the high-half mask check. -/
example : mintShares 7 7 uint256Max before = .reverted .safeMathAddOverflow before := by decide

end AccountAddress.Tests.Verity.StETHMintSharesTest
