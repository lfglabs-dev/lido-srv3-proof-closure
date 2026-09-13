import LidoSRv3.Audit.Model.EthWorld

/-! # Kill-lines for `Model.EthWorld.zeroUnmodeled` + `authorizedFrames`

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the mixed-flow zero-out and authorized-frame extraction semantics
in the E1 ETH-world inventory. -/

namespace LidoSRv3.Tests.ModelEthWorldZeroUnmodeledKillLines

open LidoSRv3.Audit.Model.EthWorld

/-- Concrete authorized frame for topupLidoPull with value 100. -/
def topupFrame : AuthorizedValueFrame :=
  { route := .topupLidoPull, value := 100 }

/-- **Kill-line: `zeroUnmodeled (.authorized f) = .authorized f` (passthrough).** -/
theorem zeroUnmodeled_authorized (f : AuthorizedValueFrame) :
    zeroUnmodeled (.authorized f) = .authorized f := rfl

/-- **Kill-line: `zeroUnmodeled` zeros ownerWithdrawal value.** -/
theorem zeroUnmodeled_ownerWithdrawal (r v : Nat) :
    zeroUnmodeled (.ownerWithdrawal r v) = .ownerWithdrawal r 0 := rfl

/-- **Kill-line: `zeroUnmodeled` zeros treasuryMint value.** -/
theorem zeroUnmodeled_treasuryMint (v : Nat) :
    zeroUnmodeled (.treasuryMint v) = .treasuryMint 0 := rfl

/-- **Kill-line: `zeroUnmodeled` zeros opsTransfer value.** -/
theorem zeroUnmodeled_opsTransfer (v : Nat) :
    zeroUnmodeled (.opsTransfer v) = .opsTransfer 0 := rfl

/-- **Kill-line: `authorizedFrames []` = []** -/
theorem authorizedFrames_empty : authorizedFrames [] = [] := rfl

/-- **Kill-line: `authorizedFrames [.authorized f] = [f]`.** -/
theorem authorizedFrames_single_authorized :
    authorizedFrames [.authorized topupFrame] = [topupFrame] := rfl

/-- **Kill-line: `authorizedFrames` skips ownerWithdrawal.** -/
theorem authorizedFrames_skip_ownerWithdrawal :
    authorizedFrames [.ownerWithdrawal 5 100] = [] := rfl

/-- **Kill-line: `authorizedFrames` skips treasuryMint.** -/
theorem authorizedFrames_skip_treasuryMint :
    authorizedFrames [.treasuryMint 100] = [] := rfl

/-- **Kill-line: `authorizedFrames` skips opsTransfer.** -/
theorem authorizedFrames_skip_opsTransfer :
    authorizedFrames [.opsTransfer 100] = [] := rfl

/-- **Kill-line: mixed list — extraction preserves order and count.** -/
theorem authorizedFrames_mixed :
    authorizedFrames [.authorized topupFrame, .ownerWithdrawal 5 100,
                     .authorized topupFrame, .treasuryMint 50]
      = [topupFrame, topupFrame] := rfl

/-- **Kill-line: `isPositive` on value 100 is True.** -/
theorem isPositive_100 : AuthorizedValueFrame.isPositive topupFrame := by decide

/-- **Kill-line: `isPositive` on value 0 is False.** -/
theorem isPositive_zero_frame :
    ¬ AuthorizedValueFrame.isPositive ({ route := .topupLidoPull, value := 0 }) := by decide

#print axioms zeroUnmodeled_authorized
#print axioms zeroUnmodeled_ownerWithdrawal
#print axioms authorizedFrames_mixed
#print axioms isPositive_100
#print axioms isPositive_zero_frame

end LidoSRv3.Tests.ModelEthWorldZeroUnmodeledKillLines
