import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Verity.Topup2DistributionTx

namespace LidoSRv3.Audit.Guarantees.PTopup2

/-! ## Vocabulary for the registered Verity statement -/

open LidoSRv3.Audit.Verity.Topup2DistributionTx in
/-- "The memory array `name` at `base` decodes to `xs`": `readArray` over
`xs.length` words returns exactly `xs`. -/
abbrev MemoryArrayDecodes (state : Verity.ContractState) (name : String) (base : Nat)
    (xs : List Word) : Prop :=
  readArray state name base xs.length = some xs

open LidoSRv3.Audit.Verity.Topup2DistributionTx in
/-- **P-TOPUP-2, Verity plane.**  If the memory arrays decode, `observe` of
`allocate` equals `sourceView` of the same source run.

If the four memory arrays decode to equal-length `effective` /
`pending` / `requested` / live per-key `topUpLimits` within
`maxValidatorsPerTopUp`, then `observe` of
`allocate` (persisted allocation array plus remaining/used slots) equals
`sourceView` of the same `sourceRun`. Limits are normalized to gwei here;
the live wei conversion and SSZ remain outside this theorem. -/
theorem verity_tx_simulates_topup2_spec
    (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : Verity.ContractState)
    (hEff : MemoryArrayDecodes state "effective" effectiveBase effective)
    (hPend : MemoryArrayDecodes state "pending" pendingBase pending)
    (hReq : MemoryArrayDecodes state "requested" requestedBase requested)
    (hLimits : MemoryArrayDecodes state "topUpLimits" limitsBase topUpLimits)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length ∧
      requested.length = topUpLimits.length)
    (hMax : requested.length ≤ maxValidatorsPerTopUp) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocate requested.length target minTopUp remainingCap moduleLimit valueGwei).run
          state) =
      sourceView effective pending requested topUpLimits
        target minTopUp remainingCap moduleLimit valueGwei :=
  verity_tx_simulates_pinned_source
    effective pending requested topUpLimits target minTopUp remainingCap moduleLimit
    valueGwei state hEff hPend hReq hLimits hLen hMax

end LidoSRv3.Audit.Guarantees.PTopup2
