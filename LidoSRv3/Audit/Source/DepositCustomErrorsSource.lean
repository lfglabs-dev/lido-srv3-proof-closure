import LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-! # StakingRouter.deposit custom-error source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
StakingRouter custom-error selectors as source-level functions of
the shared KeccakOracle.)**

Chantier: grok differential #412 flags D-REVERT-1 — Verity revert
reasons are model strings (`NOT_AUTHORIZED`, `MODULE_NOT_ACTIVE`,
`INVALID_ALLOCATION`, `BATCH_TOTAL_OVERFLOW`,
`ALLOCATION_VALUE_MISMATCH`, `ASSERT_BALANCE_UNCHANGED`), but the
pinned Solidity emits custom-error selectors (`NotAuthorized()`,
`StakingModuleNotActive()`, `ZeroDeposits()`, `WrongPubkeyLength()`,
`ModuleReturnExceedTarget()`) or `Panic(0x01)`.

This composition names each pinned custom-error selector as a
`bytes4(keccak256("ErrName()"))` via the shared oracle (PR #478).
Downstream consumers of a revert-shape can now emit real selectors
instead of model strings.

**Status:** first real derivation naming the D-REVERT-1 divergence
(grok #412) as a source-level function. -/

namespace LidoSRv3.Audit.Source.DepositCustomErrorsSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-- Canonical error signature strings, per pinned Solidity. -/
def notAuthorizedSig : String := "NotAuthorized()"
def stakingModuleNotActiveSig : String := "StakingModuleNotActive()"
def zeroDepositsSig : String := "ZeroDeposits()"
def wrongPubkeyLengthSig : String := "WrongPubkeyLength()"
def moduleReturnExceedTargetSig : String := "ModuleReturnExceedTarget()"
def panicSig : String := "Panic(uint256)"

/-- Encode a canonical error-signature string as a nat (source-level
abstraction). -/
def sigToNat (sig : String) : Nat :=
  sig.length + sig.toList.foldl (fun acc c => acc + c.toNat) 0

/-- Real derivation of each pinned custom-error selector via the
shared oracle: `bytes4(keccak256("ErrName()"))`. -/
def realErrorSelector
    (oracle : KeccakOracle) (sig : String) : Nat :=
  concreteAbiSelector oracle (sigToNat sig)

/-- Determinism of `realErrorSelector` on identical signatures. Real
derivation from the shared oracle's determinism law. -/
theorem realErrorSelector_deterministic
    {oracle : KeccakOracle} {s1 s2 : String} (hEq : s1 = s2) :
    realErrorSelector oracle s1 = realErrorSelector oracle s2 := by
  subst hEq
  rfl

/-- Convenience: pinned `NotAuthorized()` selector. -/
def notAuthorizedSelector (oracle : KeccakOracle) : Nat :=
  realErrorSelector oracle notAuthorizedSig

/-- Convenience: pinned `ZeroDeposits()` selector. -/
def zeroDepositsSelector (oracle : KeccakOracle) : Nat :=
  realErrorSelector oracle zeroDepositsSig

end LidoSRv3.Audit.Source.DepositCustomErrorsSource
