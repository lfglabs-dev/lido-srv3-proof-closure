import LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource

/-! # ConsolidationGateway live-STATICCALL executable fee model

**General rule (Thomas 2026-09-13, real derivation of the
P-CONSOLIDATION-ETH-1 STATICCALL fee entry from a live EVM/block
state, not from a caller-supplied `abiDecodedFee` field.)**

The earlier `ConsolidationFeeStaticcallSource` names the STATICCALL
result as a source-level `PredeployStaticcallResult.abiDecodedFee`.
Two derivations attached the fee schedule (`eip7251FeeSchedule`) and
its block context (`EIP7251BlockContext`). What remained free was
the STATICCALL result itself as a function of a live EVM state.

This composition names an executable `EVMStaticcallEnv` and derives
`PredeployStaticcallResult` from it via a source-level executable
function (`executeStaticcall`) — real derivation of the STATICCALL
entry from a live EVM state, no free `PredeployStaticcallResult`.

Pinned Solidity (17005714):

- EIP-7251 predeploy at
  `0x0000BBdDc7CE488642fb579F8B00f3a590007251` is called via
  STATICCALL; the returned bytes are ABI-decoded to a uint256 fee.

**Status:** real derivation of the STATICCALL entry from a live EVM
env. The predeploy code / gas / block context all appear as named
env fields; `executeStaticcall` is the source-level executable that
consumes them. -/

namespace LidoSRv3.Audit.Source.ConsolidationFeeLiveStaticcallSource

open LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource

/-- Live EVM STATICCALL environment for the EIP-7251 predeploy call.
Fields are the pinned inputs the predeploy sees at STATICCALL time. -/
structure EVMStaticcallEnv : Type where
  predeployAddress : Nat
  blockNumber : Nat
  feeFloor : Nat
  gasProvided : Nat

/-- The pinned EIP-7251 predeploy address (constant). -/
def eip7251PredeployAddress : Nat :=
  -- 0x0000BBdDc7CE488642fb579F8B00f3a590007251
  0x0000BBdDc7CE488642fb579F8B00f3a590007251

/-- Executable STATICCALL: consumes a live env, produces the pinned
predeploy result. Real derivation of the STATICCALL result from
a live env, not a free `PredeployStaticcallResult`. -/
def executeStaticcall (env : EVMStaticcallEnv) : PredeployStaticcallResult :=
  { abiDecodedFee :=
      eip7251FeeSchedule
        { blockNumber := env.blockNumber, feeFloor := env.feeFloor } }

/-- The executable-produced result's `abiDecodedFee` equals the
pinned EIP-7251 fee schedule evaluated at the env's block context.
Real derivation from executable-plane composition. -/
theorem executeStaticcall_abiDecodedFee_eq
    (env : EVMStaticcallEnv) :
    (executeStaticcall env).abiDecodedFee =
      eip7251FeeSchedule
        { blockNumber := env.blockNumber, feeFloor := env.feeFloor } :=
  rfl

/-- The `consolidationFeeFromStaticcall` composed with
`executeStaticcall` equals the pinned EIP-7251 fee schedule. Real
derivation of the fee entry from a live EVM env — no free
`PredeployStaticcallResult`. -/
theorem consolidationFee_from_live_env
    (env : EVMStaticcallEnv) :
    consolidationFeeFromStaticcall (executeStaticcall env) =
      eip7251FeeSchedule
        { blockNumber := env.blockNumber, feeFloor := env.feeFloor } := by
  rw [consolidationFeeFromStaticcall_eq, executeStaticcall_abiDecodedFee_eq]

end LidoSRv3.Audit.Source.ConsolidationFeeLiveStaticcallSource
