import LidoSRv3.Audit.Guarantees.PReserve1

/-!
Kill-lines pinning the P-RESERVE-1 guarantee registration and the
Wave-1 registered parent (`source_spend_preserves_withdrawal_reserve`)
as a re-exported passthrough. Any regression in the underlying spend
model, freshness invariant, or effective-reserve function breaks the
kill-line test surface.
-/

namespace LidoSRv3.Tests.GuaranteesPReserve1DeclarationKillLines

open LidoSRv3.Audit.Guarantees.PReserve1
open LidoSRv3.Audit.Guarantees

/-! ## Guarantee-plane declaration -/

theorem guarantee_id : guarantee.id = Id.pReserve1 := rfl

theorem guarantee_checkedLayers :
    guarantee.checkedLayers =
      [CheckedLayer.model, CheckedLayer.source, CheckedLayer.verityTx] := rfl

/-! ## Wave-1 registered parent kill-line passthrough

    Under a fresh withdrawal-queue cache, any committed
    `modelWithdrawDepositableEther` spend:
    (1) passed the scoped guards,
    (2) spent a nonzero amount,
    (3) took it from the depositable partitions only,
    (4) left the live queue-facing withdrawals reserve unchanged. -/

theorem source_spend_preserves_withdrawal_reserve_restated
    (inputs : LidoSRv3.Audit.SolidityReserve.WithdrawInputs)
    (before after : LidoSRv3.Audit.SolidityReserve.ReserveState)
    (amount live : LidoSRv3.Audit.SolidityReserve.Word)
    (hfresh : LidoSRv3.Audit.SolidityReserve.freshQueueCache before live)
    (h : LidoSRv3.Audit.SolidityReserve.modelWithdrawDepositableEther
      inputs before amount =
        LidoSRv3.Audit.SolidityReserve.SourceOutcome.committed after) :
    LidoSRv3.Audit.SolidityReserve.scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      LidoSRv3.Audit.SolidityReserve.withdrawalPartitionSpendInvariant
        before after amount ∧
      LidoSRv3.Audit.SolidityReserve.liveEffectiveWithdrawalsReserve after live =
        LidoSRv3.Audit.SolidityReserve.liveEffectiveWithdrawalsReserve
          before live :=
  source_spend_preserves_withdrawal_reserve inputs before after amount live hfresh h

end LidoSRv3.Tests.GuaranteesPReserve1DeclarationKillLines
