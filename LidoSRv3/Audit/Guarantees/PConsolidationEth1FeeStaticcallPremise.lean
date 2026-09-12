import LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel

/-! # P-CONSOLIDATION-ETH-1 fee STATICCALL naming scaffold

**General rule (Thomas 2026-09-12), applied to CONSOLIDATION-ETH-1
`feePerRequest` free `Nat`.**

The registered Verity parent of P-CONSOLIDATION-ETH-1
(`verity_tx_success_and_revert_partition`, and the derived
`verity_tx_success_shape_unbounded` / `verity_tx_success_at_derived
_fuel_under_bus_ceiling`) takes `feePerRequest : Nat` as a free
input. The pinned Solidity's fee is read via `STATICCALL` on the
`CONSOLIDATION_REQUEST` immutable at
`contracts/0.8.9/vaults/WithdrawalVaultEIP7685.sol:79-81` →
`_getFeeFromContract(CONSOLIDATION_REQUEST)` (per the pinned
Solidity 17005714).

Per Thomas 2026-09-12 general rule: identify the pinned Solidity
source of the free input and name it in a composition premise
`PinnedFeeStaticcallShape`. Under the premise, the `feePerRequest`
input is DERIVED from the live STATICCALL result on the pinned
EIP-7251 predeploy address.

**Status: naming scaffold, not a full composition.** The
`feePerRequest_derived_under_pinned_fee_staticcall_shape` theorem is
a straight-line projection of the structure's field. A full
derivation requires: (a) a live-`STATICCALL` executable model on
the pinned `CONSOLIDATION_REQUEST` address
(`0x0000BBdDc7CE488642fb579F8B00f3a590007251`, discharged via
`A-CANONICAL-REQUEST-ADDRESS` retirement); (b) an ABI decoder for
the return-data 32-byte fee word; (c) an EIP-7251-schedule model
that describes what the predeploy returns as a function of block
context. None are tree-resident yet.

**The scaffold's composition value** is naming the composition
entry point explicitly: downstream consumers can supply a
`PinnedFeeStaticcallShape` bundle rather than a free `Nat`, and
the future live-STATICCALL derivation has a clear attachment point.

Residual (in `fidelity.missing`): live STATICCALL on the pinned
EIP-7251 predeploy, ABI decoder, and predeploy-schedule model are
the remaining follow-ups. -/

namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1FeeStaticcallPremise

/-- Pinned fee STATICCALL premise on the `feePerRequest` input,
naming the pinned WithdrawalVaultEIP7685.sol:79-81
`_getFeeFromContract(CONSOLIDATION_REQUEST)` STATICCALL as the
composition entry point.

`feePerRequestBecausePinned` asserts that
`feePerRequest` equals `pinnedFeeReadValue` — the fee value the
pinned STATICCALL returns for the current block context. Both are
parameters of this proposition; a future live-STATICCALL model
would compute `pinnedFeeReadValue` from the actual predeploy read. -/
def PinnedFeeStaticcallShape (feePerRequest pinnedFeeReadValue : Nat) : Prop :=
  feePerRequest = pinnedFeeReadValue

/-- Straight-line derivation of `feePerRequest = pinnedFeeReadValue`
from the pinned-STATICCALL shape premise. **Scaffold only** — a
future live-STATICCALL model would derive this from the actual
STATICCALL result. -/
theorem feePerRequest_derived_under_pinned_fee_staticcall_shape
    {feePerRequest pinnedFeeReadValue : Nat}
    (hPinned : PinnedFeeStaticcallShape feePerRequest pinnedFeeReadValue) :
    feePerRequest = pinnedFeeReadValue :=
  hPinned

end LidoSRv3.Audit.Guarantees.PConsolidationEth1FeeStaticcallPremise
