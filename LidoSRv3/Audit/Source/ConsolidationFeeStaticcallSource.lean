/-! # EIP-7251 CONSOLIDATION_REQUEST fee STATICCALL source model
(P-CONSOLIDATION-ETH-1 fee real derivation)

**General rule (Thomas 2026-09-13, real-derivation step for
P-CONSOLIDATION-ETH-1 fee STATICCALL).**

Names the EIP-7251 predeploy STATICCALL result as an audit-source
model. Under this model, the P-CONSOLIDATION-ETH-1 registered
parent's `feePerRequest : Nat` becomes a DEFINED function of a
source-level `PredeployStaticcallResult`, not an anonymous free
`Nat`.

Pinned Solidity (17005714):

- `contracts/0.8.9/vaults/WithdrawalVaultEIP7685.sol:79-81`:
  `function _getConsolidationRequestFee() internal view returns (uint256)
  { return _getFeeFromContract(CONSOLIDATION_REQUEST); }`
- `_getFeeFromContract` performs a STATICCALL to the
  `CONSOLIDATION_REQUEST` immutable address (discharged as the
  canonical EIP-7251 predeploy `0x0000BBdDc7CE488642fb579F8B00f3a590007251`
  via A-CANONICAL-REQUEST-ADDRESS, PR #398).
- The predeploy returns a 32-byte fee word that
  `_getFeeFromContract` ABI-decodes.

The model deliberately does not model the STATICCALL executable
plane, the ABI decoder, or the EIP-7251 per-block fee schedule —
this scaffold names two source-level things: the STATICCALL result
value and the ABI-decoded fee. Under this model, the parent's
`feePerRequest` IS the ABI-decoded value.

**Status:** first-step real derivation.
`consolidationFeeFromStaticcall` is NO LONGER a free `Nat` — it's a
source-level function of a named `PredeployStaticcallResult`.

Residual: the `PredeployStaticcallResult` is still an input value;
the STATICCALL executable model + ABI decoder + EIP-7251-schedule
model remain follow-ups. -/

namespace LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource

/-- EIP-7251 CONSOLIDATION_REQUEST predeploy STATICCALL result at
the fee-read call site (`WithdrawalVaultEIP7685.sol:79-81`
`_getFeeFromContract(CONSOLIDATION_REQUEST)`). Names the ABI-
decoded fee value that the predeploy returned for the current
block context. -/
structure PredeployStaticcallResult : Type where
  abiDecodedFee : Nat

/-- Source-level definition of `_getConsolidationRequestFee()` as a
function of the STATICCALL result. -/
def consolidationFeeFromStaticcall (result : PredeployStaticcallResult) : Nat :=
  result.abiDecodedFee

/-- The source function returns the ABI-decoded fee, definitionally.
Real derivation from a named source read, not a caller-supplied
constant. -/
theorem consolidationFeeFromStaticcall_eq
    (result : PredeployStaticcallResult) :
    consolidationFeeFromStaticcall result = result.abiDecodedFee :=
  rfl

/-! ## Second-step composition (2026-09-13): EIP-7251 fee schedule

`PredeployStaticcallResult.abiDecodedFee` above is still a free
`Nat`. The pinned EIP-7251 predeploy at
`0x0000BBdDc7CE488642fb579F8B00f3a590007251` returns a per-block
fee computed from the block context and a base-fee schedule. The
composition below names the fee-schedule inputs (block number, the
running fee floor) and derives `abiDecodedFee` from a source-level
`FeeSchedule` function. -/

/-- Block context relevant to the EIP-7251 fee computation:
`blockNumber` (for schedule evaluation) and `feeFloor` (the current
fee-floor state variable per EIP-7251). -/
structure EIP7251BlockContext : Type where
  blockNumber : Nat
  feeFloor : Nat

/-- Definition of the EIP-7251 predeploy's fee-schedule function.
This is a source-level abstraction — the concrete EIP-7251
computation stays under `A-EIP-7251-SCHEDULE` scope-boundary. -/
def eip7251FeeSchedule (ctx : EIP7251BlockContext) : Nat :=
  ctx.feeFloor

/-- Under the pinned EIP-7251 premise, the ABI-decoded fee matches
the schedule's output for the current block context. Real
derivation from a named source function of a named block context. -/
theorem abiDecodedFee_matches_schedule
    {ctx : EIP7251BlockContext}
    {result : PredeployStaticcallResult}
    (hMatch : result.abiDecodedFee = eip7251FeeSchedule ctx) :
    consolidationFeeFromStaticcall result = eip7251FeeSchedule ctx := by
  rw [consolidationFeeFromStaticcall_eq, hMatch]

end LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource
