import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Verity.Topup2DistributionTx

namespace LidoSRv3.Audit.Guarantees.PTopup2

/-- Headline composed closure theorem for P-TOPUP-2. The executable
memory-array transaction evaluates checked top-up limits, consumes the
module-share/block budget left to right, persists allocations through
`writeMapUint` and remaining/used through `writeSlot`, and its
committed/reverted observables are exactly the pinned-source batch. -/
theorem verity_tx_simulates_topup2_spec
    (effective pending requested : List LidoSRv3.Audit.Source.Topup2.Word)
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
    (hLen : effective.length = pending.length ∧ pending.length = requested.length) :
    LidoSRv3.Audit.Verity.Topup2DistributionTx.observe
        (List.replicate requested.length 0) remainingCap
        ((LidoSRv3.Audit.Verity.Topup2DistributionTx.allocate requested.length
          target minTopUp remainingCap moduleLimit valueGwei).run
        state) =
      LidoSRv3.Audit.Verity.Topup2DistributionTx.sourceView effective pending
        requested target minTopUp remainingCap moduleLimit valueGwei :=
  LidoSRv3.Audit.Verity.Topup2DistributionTx.verity_tx_simulates_pinned_source
    effective pending requested target minTopUp remainingCap moduleLimit
    valueGwei state hEff hPend hReq hLen

end LidoSRv3.Audit.Guarantees.PTopup2
