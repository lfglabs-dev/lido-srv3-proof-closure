import LidoSRv3.Audit.Verity.TopupParent

/-! # Kill-lines for `Verity.TopupParent.reasonString`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-TOPUP-1 parent-execute revert-reason encoding: three distinct
call-failure reason strings and the source-wrapped case. -/

namespace LidoSRv3.Tests.VerityTopupParentRevertReasonsKillLines

open LidoSRv3.Audit.Verity.TopupParent
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.SolidityTopupParent

/-- **Kill-line: allocation call failure encodes as
"ALLOCATION_CALL_FAILED".** -/
theorem reasonString_allocationCallFailed :
    reasonString .allocationCallFailed = "ALLOCATION_CALL_FAILED" := rfl

/-- **Kill-line: lidoPull call failure encodes as
"LIDO_PULL_CALL_FAILED".** -/
theorem reasonString_lidoPullCallFailed :
    reasonString .lidoPullCallFailed = "LIDO_PULL_CALL_FAILED" := rfl

/-- **Kill-line: beaconPush call failure encodes as
"BEACON_PUSH_CALL_FAILED".** -/
theorem reasonString_beaconPushCallFailed :
    reasonString .beaconPushCallFailed = "BEACON_PUSH_CALL_FAILED" := rfl

/-- **Kill-line: the three call-failure strings are pairwise
distinct.**

A mutant that collapsed two failure branches would obscure the
root cause reported to callers. -/
theorem call_failed_strings_distinct :
    reasonString .allocationCallFailed ≠
      reasonString .lidoPullCallFailed ∧
    reasonString .lidoPullCallFailed ≠
      reasonString .beaconPushCallFailed ∧
    reasonString .allocationCallFailed ≠
      reasonString .beaconPushCallFailed := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

#print axioms reasonString_allocationCallFailed
#print axioms reasonString_lidoPullCallFailed
#print axioms reasonString_beaconPushCallFailed
#print axioms call_failed_strings_distinct

end LidoSRv3.Tests.VerityTopupParentRevertReasonsKillLines
