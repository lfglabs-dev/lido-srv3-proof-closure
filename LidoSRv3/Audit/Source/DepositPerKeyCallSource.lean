/-! # BeaconChainDepositor per-key deposit-frame source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
BeaconChainDepositor.sol:57 per-key deposit-frame semantics as a
source-level function.)**

Chantier: grok differential #412 flags D-CALL-1 — Verity
`DepositNFrameTx.execute` journals one `depositToBeacon` frame per
batch carrying `keys * DEPOSIT_SIZE`, but the pinned source journals
one `IDepositContract.deposit{value: 32 ether}(publicKey, ...)`
per key (`BeaconChainDepositor.sol:57`) followed by a two-argument
`withdrawDepositableEther(depositsValue, actualDepositsCount)`.

This composition names the per-key deposit-frame shape as a source-
level function: `perKeyDepositFrames n = List.replicate n ⟨DEPOSIT_SIZE⟩`.
Downstream consumers of a batch context can expand a per-batch
aggregate into `n` per-key frames matching the pinned Solidity
journal shape.

Pinned Solidity (17005714):

- `BeaconChainDepositor.sol:57`:
  `IDepositContract.deposit{value: 32 ether}(publicKey, wc, sig, root)`
  called once per key in the loop.
- `StakingRouter.sol:988-991`:
  `LIDO.withdrawDepositableEther(depositsValue, actualDepositsCount)`
  two-argument shape.

**Status:** first real derivation naming the D-CALL-1 divergence
(grok #412) as a source-level function. -/

namespace LidoSRv3.Audit.Source.DepositPerKeyCallSource

/-- Pinned `DEPOSIT_SIZE` constant (32 ether = 32 * 10^18 wei). -/
def depositSize : Nat := 32 * 10 ^ 18

/-- Source-level per-key deposit frame: a single frame carrying
`DEPOSIT_SIZE` value. -/
structure PerKeyDepositFrame : Type where
  value : Nat

/-- Source-level per-key journal: `n` deposit frames, each carrying
`DEPOSIT_SIZE`. Real derivation of the pinned
`BeaconChainDepositor.sol:57` loop semantics. -/
def perKeyDepositFrames (n : Nat) : List PerKeyDepositFrame :=
  List.replicate n { value := depositSize }

/-- The per-key journal has exactly `n` frames. -/
theorem perKeyDepositFrames_length (n : Nat) :
    (perKeyDepositFrames n).length = n := by
  simp [perKeyDepositFrames, List.length_replicate]

/-- Each per-key frame carries `DEPOSIT_SIZE`. -/
theorem perKeyDepositFrames_value (n i : Nat) (h : i < n) :
    (perKeyDepositFrames n)[i]?.map PerKeyDepositFrame.value = some depositSize := by
  simp [perKeyDepositFrames, h]

/-- Source-level `withdrawDepositableEther` argument shape: two
words `(depositsValue, actualDepositsCount)`. -/
structure WithdrawArgs : Type where
  depositsValue : Nat
  actualDepositsCount : Nat

/-- Real derivation of the pinned
`StakingRouter.sol:988-991` two-argument shape. -/
def realWithdrawArgs
    (perKeyValue actualDepositsCount : Nat) : WithdrawArgs :=
  { depositsValue := actualDepositsCount * perKeyValue,
    actualDepositsCount := actualDepositsCount }

/-- Under the pinned `perKeyValue = DEPOSIT_SIZE` premise, the
withdrawal-args' `depositsValue` equals `actualDepositsCount *
DEPOSIT_SIZE`. -/
theorem realWithdrawArgs_depositsValue_eq
    (actualDepositsCount : Nat) :
    (realWithdrawArgs depositSize actualDepositsCount).depositsValue =
      actualDepositsCount * depositSize :=
  rfl

end LidoSRv3.Audit.Source.DepositPerKeyCallSource
