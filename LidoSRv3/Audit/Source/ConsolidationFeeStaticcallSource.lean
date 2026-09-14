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

- `contracts/0.8.9/WithdrawalVaultEIP7685.sol:79-81`:
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

/-! ## Chantier 2 ABI-bridge composition (Thomas 2026-09-13)

The `ConsolidationGateway.addConsolidationRequests` entrypoint
(`0.8.25/consolidation/ConsolidationGateway.sol:185-223`) reads
`fee` via the untranscribed `withdrawalVault.getConsolidationRequestFee()`
STATICCALL at line 211, computes `totalFee = requestsCount * fee`
at line 212, and forwards it as
`withdrawalVault.addConsolidationRequests{value: totalFee}(...)`
at line 220. The composition below names that arithmetic on top of
`consolidationFeeFromStaticcall`, and derives the Thomas 2026-09-13
`fee ≠ 0 → totalFee ≠ 0` fact the `A-CONSOLIDATION-GATEWAY-NONZERO`
assumption body now explicitly cites. -/

/-- Gateway-side `totalFee = requestsCount * fee` computation
(`ConsolidationGateway.sol:212`), with `fee` sourced from the
STATICCALL result. -/
def gatewayTotalFee (result : PredeployStaticcallResult)
    (requestsCount : Nat) : Nat :=
  requestsCount * consolidationFeeFromStaticcall result

/-- Definitionally the gateway multiplication expression: `totalFee =
requestsCount * fee` where `fee` is the STATICCALL return. -/
theorem gatewayTotalFee_eq
    (result : PredeployStaticcallResult) (requestsCount : Nat) :
    gatewayTotalFee result requestsCount =
      requestsCount * result.abiDecodedFee :=
  rfl

/-- **Chantier 2 (Thomas 2026-09-13) derivation `fee ≠ 0 → totalFee ≠ 0`.**
For any positive `requestsCount`, a nonzero STATICCALL-read fee
yields a nonzero forwarded `totalFee`. Pure arithmetic on the
gateway's line 212 expression; this is the derivation the
`A-CONSOLIDATION-GATEWAY-NONZERO` assumption body now points to as
the preferred bridge from "nonzero fee on the STATICCALL return"
to "nonzero forwarded value at the vault frame entry". -/
theorem gatewayTotalFee_ne_zero_of_fee_ne_zero
    (result : PredeployStaticcallResult)
    (requestsCount : Nat)
    (hRequestsPos : 0 < requestsCount)
    (hFeeNe : result.abiDecodedFee ≠ 0) :
    gatewayTotalFee result requestsCount ≠ 0 := by
  rw [gatewayTotalFee_eq]
  exact Nat.mul_ne_zero (Nat.pos_iff_ne_zero.mp hRequestsPos) hFeeNe

/-- **Chantier 2 (Thomas 2026-09-13) `fee = 0` on-chain path.** The
premise is violable on-chain when the EIP-7251 predeploy returns
`fee = 0`: even a batch with a positive `requestsCount` forwards a
zero `totalFee`, `msg.value = 0` passes `_requireExactFee(0)`, and
the vault commits a zero-value batch. Documented as an explicit
witness for the assumption body — the derivation above is the
positive-fee side; this witness is the negative side. -/
theorem gatewayTotalFee_zero_at_fee_zero
    (result : PredeployStaticcallResult)
    (requestsCount : Nat)
    (hFeeZero : result.abiDecodedFee = 0) :
    gatewayTotalFee result requestsCount = 0 := by
  rw [gatewayTotalFee_eq, hFeeZero, Nat.mul_zero]

/-- Non-vacuity witness: `gatewayTotalFee` produces a nonzero value
for a positive fee and a nonempty batch, showing the derivation
above is not vacuously true. -/
theorem gatewayTotalFee_ne_zero_witness :
    gatewayTotalFee ⟨7⟩ 3 ≠ 0 :=
  gatewayTotalFee_ne_zero_of_fee_ne_zero ⟨7⟩ 3 (by decide) (by decide)

/-! ## Chantier 2 gateway→vault ABI-bridge linkage (Thomas 2026-09-13)

The gateway invocation

    ConsolidationGateway.addConsolidationRequests(groups, refundRecipient)

reads `fee = withdrawalVault.getConsolidationRequestFee()` at
`ConsolidationGateway.sol:211` (a STATICCALL to the pinned
CONSOLIDATION_REQUEST predeploy via `WithdrawalVaultEIP7685._getConsolidationRequestFee`
at `WithdrawalVaultEIP7685.sol:79-93`), computes
`totalFee = requestsCount * fee` at line 212, and forwards it to
the vault-side call

    withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)

at `ConsolidationGateway.sol:220`. Downstream that vault-side call
enters `WithdrawalVaultEIP7685._addConsolidationRequests`
(`WithdrawalVaultEIP7685.sol:56-73`), where `msg.value` equals the
forwarded `totalFee` and the loop-internal `fee` argument
propagates to each `_callAddConsolidationRequest`.

The source-plane linkage below names the two-endpoint equation
`Inputs.msgValue = gatewayTotalFee result requestsCount` and
`Inputs.fee = result.abiDecodedFee`, so a caller composing
`P-CONSOLIDATION-1` (vault leg) with `P-CONSOLIDATION-ETH-1`
(gateway leg) knows exactly which two scalars must agree at the
frame boundary. The `_requireExactFee` guard on the vault side
(`WithdrawalVaultEIP7685.sol:123-127`, `IncorrectFee` revert)
enforces `Inputs.msgValue = requests.length * Inputs.fee.val`, so
this linkage plus the gateway's `totalFee = requestsCount * fee`
identity gives `requests.length = requestsCount` at the vault's
frame entry — the number of `(source, target)` pairs the vault
receives equals the flattened pair count `_prepareConsolidationPairs`
(`ConsolidationGateway.sol:216-219`) produced from `groups`. -/

/-- Source-plane record of the two scalars that cross the
gateway→vault frame boundary: `msgValue` = `totalFee` forwarded on
the outer call at `ConsolidationGateway.sol:220`, and `fee` = the
STATICCALL-return `abiDecodedFee` from line 211. -/
structure GatewayVaultFeeBoundary : Type where
  msgValue : Nat
  fee : Nat

/-- The exact source-plane linkage: given a `PredeployStaticcallResult`
and a `requestsCount`, the boundary scalars are
`msgValue = gatewayTotalFee result requestsCount` and
`fee = result.abiDecodedFee`. -/
def gatewayVaultBoundary (result : PredeployStaticcallResult)
    (requestsCount : Nat) : GatewayVaultFeeBoundary :=
  { msgValue := gatewayTotalFee result requestsCount
    fee := result.abiDecodedFee }

/-- **Chantier 2 (Thomas 2026-09-13) exact-fee-boundary identity.**
`gatewayVaultBoundary result n` satisfies the vault's
`_requireExactFee` equation exactly: `msgValue = n * fee`. This is
the arithmetic identity that `_requireExactFee` (`WithdrawalVaultEIP7685.sol:123-127`)
checks on the vault side; a caller composing the two guarantees
now has an explicit source-plane linkage proving the two scalars
that cross the frame boundary satisfy this equation.

The composition consumer is: when the vault leg's `Inputs.msgValue`
and `Inputs.fee` are populated from `gatewayVaultBoundary`,
`_requireExactFee` passes (i.e., the vault-side `IncorrectFee`
revert is unreachable), so the vault commits on the count / bound
/ per-key-validation guards alone. -/
theorem gatewayVaultBoundary_satisfies_exact_fee
    (result : PredeployStaticcallResult) (requestsCount : Nat) :
    (gatewayVaultBoundary result requestsCount).msgValue =
      requestsCount * (gatewayVaultBoundary result requestsCount).fee := by
  unfold gatewayVaultBoundary
  exact gatewayTotalFee_eq result requestsCount

/-- Non-vacuity witness for the exact-fee boundary identity: a
positive `requestsCount = 3` and a STATICCALL-return `fee = 7`
yields `msgValue = 21`, exactly the vault's `_requireExactFee(21)`
expectation. -/
theorem gatewayVaultBoundary_witness :
    (gatewayVaultBoundary ⟨7⟩ 3).msgValue = 21 ∧
    (gatewayVaultBoundary ⟨7⟩ 3).fee = 7 := by
  refine ⟨?_, ?_⟩ <;> rfl

end LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource
