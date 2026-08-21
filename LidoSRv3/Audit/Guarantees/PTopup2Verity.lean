import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Verity.Topup2DistributionTx

namespace LidoSRv3.Audit.Guarantees.PTopup2

/-- If the four memory arrays decode to equal-length `effective` /
`pending` / `requested` / live per-key `topUpLimits` within
`maxValidatorsPerTopUp`, then `observe` of
`allocate` (persisted allocation array plus remaining/used slots) equals
`sourceView` of the same `sourceRun`. Limits are normalized to gwei here;
the live wei conversion and SSZ remain outside this theorem. -/
theorem verity_tx_simulates_topup2_spec
    (effective pending requested topUpLimits :
      List LidoSRv3.Audit.Source.Topup2.Word)
    (target minTopUp remainingCap moduleLimit valueGwei :
      LidoSRv3.Audit.Source.Topup2.Word)
    (state : Verity.ContractState)
    (hEff : LidoSRv3.Audit.Verity.Topup2DistributionTx.readArray state "effective"
      LidoSRv3.Audit.Verity.Topup2DistributionTx.effectiveBase effective.length =
        some effective)
    (hPend : LidoSRv3.Audit.Verity.Topup2DistributionTx.readArray state "pending"
      LidoSRv3.Audit.Verity.Topup2DistributionTx.pendingBase pending.length =
        some pending)
    (hReq : LidoSRv3.Audit.Verity.Topup2DistributionTx.readArray state "requested"
      LidoSRv3.Audit.Verity.Topup2DistributionTx.requestedBase requested.length =
        some requested)
    (hLimits : LidoSRv3.Audit.Verity.Topup2DistributionTx.readArray state "topUpLimits"
      LidoSRv3.Audit.Verity.Topup2DistributionTx.limitsBase topUpLimits.length =
        some topUpLimits)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length ∧
      requested.length = topUpLimits.length)
    (hMax : requested.length ≤ LidoSRv3.Audit.Verity.Topup2DistributionTx.maxValidatorsPerTopUp) :
    LidoSRv3.Audit.Verity.Topup2DistributionTx.observe
        (List.replicate requested.length 0) remainingCap
        ((LidoSRv3.Audit.Verity.Topup2DistributionTx.allocate requested.length
          target minTopUp remainingCap moduleLimit valueGwei).run
        state) =
      LidoSRv3.Audit.Verity.Topup2DistributionTx.sourceView effective pending
        requested topUpLimits target minTopUp remainingCap moduleLimit valueGwei :=
  LidoSRv3.Audit.Verity.Topup2DistributionTx.verity_tx_simulates_pinned_source
    effective pending requested topUpLimits target minTopUp remainingCap moduleLimit
    valueGwei state hEff hPend hReq hLimits hLen hMax

end LidoSRv3.Audit.Guarantees.PTopup2
