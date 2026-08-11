import LidoSRv3.Audit.Source.EthFlowCorrespondence

namespace LidoSRv3.Tests.EthFlowMutants

open Verity
open LidoSRv3.Audit.SolidityEthFlow

def sender : Address := 10
def recipient : Address := 20

example : sourceRoute sender 11 2 5 recipient =
    .committed ⟨10, 1, recipient⟩ := by decide

/-- Negative mutant: forwarding all supplied value to the vault duplicates the
refund and violates conservation. -/
def duplicateRefundMutant : Route := ⟨11, 1, recipient⟩
example : duplicateRefundMutant.vaultValue.val +
    duplicateRefundMutant.refundValue.val ≠ 11 := by decide

/-- Negative mutant: a lateral refund destination is rejected by the exact
source-recipient correspondence. -/
def lateralRecipientMutant : Route := ⟨10, 1, 99⟩
example : lateralRecipientMutant.refundRecipient ≠
    effectiveRefundRecipient sender recipient := by decide

/-- Negative mutant: insufficient fee cannot commit. -/
example : sourceRoute sender 9 2 5 recipient = .reverted "INSUFFICIENT_FEE" := by decide

/-- Negative mutant: zero requested recipient must fall back to the caller. -/
example : sourceRoute sender 11 2 5 0 = .committed ⟨10, 1, sender⟩ := by decide

end LidoSRv3.Tests.EthFlowMutants
