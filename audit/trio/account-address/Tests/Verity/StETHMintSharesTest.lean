import StETHMintShares

namespace AccountAddress.Tests.Verity.StETHMintSharesTest

open AccountAddress.ReportWriteFee
open AccountAddress.StETHMintShares

/-- A concrete packed word with total shares `10` and an independent external
share payload `4` in the high half. -/
private def before : State := {
  storage := Core.write
    (Core.write
      (Core.write
        (Core.write
          (Core.write ⟨[]⟩ 17 ⟨111, by decide⟩)
          18 ⟨222, by decide⟩)
        bufferedEtherAndDepositedPostReportPosition ⟨100, by decide⟩)
      clValidatorsAndPendingPosition ⟨0, by decide⟩)
    totalSharesPosition ⟨4 * two128 + 10, by
      have : 4 * two128 + 10 < two256 := by decide
      exact this⟩
  shares := fun account => if account = 7 then 5 else 0
  locatorAccounting := 7
  selfAddress := 8
  activeFlag := true
}

/-- Lido's emission reads the post-mint rate: `(2 * 100) / (12 - 4) = 25`.
The high half remains `4`, the recipient mapping entry becomes `7`, and an
unrelated mapping key remains zero. -/
example : (match mintShares 7 7 2 before with
  | .committed post events =>
      decide (totalShares post = 12 ∧ externalShares post = 4 ∧
      post.shares 7 = 7 ∧ post.shares 9 = 0 ∧
      (post.storage.read 17).val = 111 ∧ (post.storage.read 18).val = 222 ∧
      events = [.transfer 0 7 25, .transferShares 0 7 2])
  | .reverted _ _ => false) = true := by decide +kernel

/-- `_auth` is the outermost source guard after model address admission. -/
example : (match mintShares 6 0 1 before with
  | .reverted e _ => e == .notAccounting
  | _ => false) = true := by decide +kernel

/-- `_whenNotStopped` runs before `_mintShares`' recipient checks. -/
example : (match mintShares 7 0 1 {before with activeFlag := false} with
  | .reverted e _ => e == .stopped
  | _ => false) = true := by decide +kernel

/-- `_getTotalShares().add` reverts before the high-half mask check. -/
example : (match mintShares 7 7 uint256Max before with
  | .reverted e _ => e == .safeMathAddOverflow
  | _ => false) = true := by decide +kernel

end AccountAddress.Tests.Verity.StETHMintSharesTest
