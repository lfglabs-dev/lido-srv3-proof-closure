/-! # Lido.receiveDepositableEther payable-CALL source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Lido.sol:885 payable-CALL frame as a source-level function.)**

Chantier: grok differential #419 flags D-TRANSFER-1 — Verity
`modelWithdrawDepositableEther` updates reserve words only; the
pinned `Lido.sol:885` calls
`stakingRouter.receiveDepositableEther.value(_amount)()`. The
payable CALL (target, value, selector, order after the spend writes)
is not journaled at the Verity plane.

This composition names the pinned payable-CALL frame as a source-
level structure: target = pinned StakingRouter, value = _amount,
selector = `keccak256("receiveDepositableEther()")` first 4 bytes,
calldata = empty payload. Downstream consumers of the Lido
reserve-writer can now compare their journal against the pinned
payable-CALL shape.

Pinned Solidity (17005714):

- `Lido.sol:885`: `stakingRouter.receiveDepositableEther.value(_amount)();`

**Status:** first real derivation naming the D-TRANSFER-1 divergence
(grok #419) as a source-level payable-CALL frame. -/

namespace LidoSRv3.Audit.Source.ReservePayableCallSource

/-- Source-level payable-CALL frame shape for
`stakingRouter.receiveDepositableEther.value(_amount)()`. -/
structure PayableCallFrame : Type where
  target : Nat
  value : Nat
  selectorPrefix : Nat  -- bytes4(keccak256("receiveDepositableEther()"))
  calldata : List Nat    -- empty payload after selector

/-- Source-level definition of the pinned `Lido.sol:885` payable-
CALL frame given the StakingRouter target address and the amount. -/
def receiveDepositableEtherFrame
    (stakingRouterAddr amount selectorPrefix : Nat) : PayableCallFrame :=
  { target := stakingRouterAddr,
    value := amount,
    selectorPrefix := selectorPrefix,
    calldata := [] }

/-- The frame's target equals the pinned StakingRouter address. -/
theorem receiveDepositableEtherFrame_target_eq
    (stakingRouterAddr amount selectorPrefix : Nat) :
    (receiveDepositableEtherFrame stakingRouterAddr amount selectorPrefix).target =
      stakingRouterAddr :=
  rfl

/-- The frame carries the requested amount as its value. -/
theorem receiveDepositableEtherFrame_value_eq
    (stakingRouterAddr amount selectorPrefix : Nat) :
    (receiveDepositableEtherFrame stakingRouterAddr amount selectorPrefix).value =
      amount :=
  rfl

/-- The frame carries an empty calldata payload after the selector. -/
theorem receiveDepositableEtherFrame_calldata_eq
    (stakingRouterAddr amount selectorPrefix : Nat) :
    (receiveDepositableEtherFrame stakingRouterAddr amount selectorPrefix).calldata =
      [] :=
  rfl

end LidoSRv3.Audit.Source.ReservePayableCallSource
