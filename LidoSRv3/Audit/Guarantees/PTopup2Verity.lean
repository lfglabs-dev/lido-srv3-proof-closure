import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Verity.Topup2DistributionTx

namespace LidoSRv3.Audit.Guarantees.PTopup2

open LidoSRv3.Audit.Verity.Topup2DistributionTx in
/-- **P-TOPUP-2, Verity plane.**  If the memory arrays decode, `observe` of
`allocate` equals `sourceView` of the same source run.

If the four memory arrays decode to equal-length `effective` /
`pending` / `requested` / live per-key `topUpLimits` within the caller-
supplied `maxValidators` bound, then `observe` of
`allocate` (persisted allocation array plus remaining/used slots) equals
`sourceView` of the same `sourceRun`. Limits are normalized to gwei here;
the live wei conversion and SSZ remain outside this theorem.

`maxValidators : Nat` is the caller-supplied bound, sourced from the pinned
`uint64 $.maxValidatorsPerTopUp` (`TopUpGateway.sol:42`, packed slot 0 of
`TopupPackedStorage`). Callers under the pinned initializer supply
`maxValidatorsPerTopUp = 32`; other deployments admit any `uint64` value
within `Nat.min uint64Max`. -/
theorem verity_tx_simulates_topup2_spec
    (effective pending requested topUpLimits : List Word)
    (maxValidators : Nat)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : Verity.ContractState)
    (hEff : readArray state "effective" effectiveBase effective.length = some effective)
    (hPend : readArray state "pending" pendingBase pending.length = some pending)
    (hReq : readArray state "requested" requestedBase requested.length = some requested)
    (hLimits : readArray state "topUpLimits" limitsBase topUpLimits.length = some topUpLimits)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length ∧
      requested.length = topUpLimits.length)
    (hMax : requested.length ≤ maxValidators) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocate requested.length maxValidators
            target minTopUp remainingCap moduleLimit valueGwei).run state) =
      sourceView effective pending requested topUpLimits
        target minTopUp remainingCap moduleLimit valueGwei :=
  verity_tx_simulates_pinned_source
    effective pending requested topUpLimits maxValidators
    target minTopUp remainingCap moduleLimit
    valueGwei state hEff hPend hReq hLimits hLen hMax

end LidoSRv3.Audit.Guarantees.PTopup2
