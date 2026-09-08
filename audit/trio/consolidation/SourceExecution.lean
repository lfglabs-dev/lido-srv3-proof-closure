import audit.trio.consolidation.Spec

/-!
# Bounded consolidation source execution

An independent bounded model of the remaining external-control surface in the
vault path pinned at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `WithdrawalVault` constructor, lines 63--78 (both immutable addresses are
  nonzero), and `WithdrawalVaultEIP7685` constructor, lines 34--40;
* `_getFeeFromContract`, lines 83--95 (the fee `STATICCALL` may fail);
* `_callAddConsolidationRequest`, lines 113--121 (any value-bearing `CALL`
  may fail and reverts the whole entrypoint); and
* `preservesEthBalance`, `WithdrawalVault.sol` lines 81--85.

`requireClosedExit` is deliberately named: a finite result list and fuel bound
are evidence that every external request reached a success/failure response.
It is an obligation, not an axiom or a trust-manifest escape.
-/

namespace audit.trio.consolidation

structure ConstructorArgs where
  lido : Word
  consolidationGateway : Word
  consolidationRequest : Word
  deriving DecidableEq, Repr

def constructorConditions (args : ConstructorArgs) : Bool :=
  args.lido.val != 0 && args.consolidationGateway.val != 0 &&
    args.consolidationRequest.val != 0

inductive ExternalResult (α : Type) where
  | success (value : α)
  | failure
  deriving DecidableEq, Repr

inductive SourceExecutionError where
  | invalidConstructor
  | staticcallFailed
  | vaultGuard (error : VaultError)
  | callFailed (index : Nat)
  deriving DecidableEq, Repr

inductive SourceExecutionOutcome where
  /-- The bound or supplied external-result prefix did not close the loop. -/
  | openExit
  /-- All source failures roll the payable credit and prior calls back. -/
  | reverted (error : SourceExecutionError) (vaultBalance : Nat)
  /-- The modifier accepted the final balance. -/
  | committed (pairs : List (Pubkey × Pubkey)) (vaultBalance : Nat)
  deriving DecidableEq, Repr

private def firstCallFailure : Nat → List (ExternalResult Unit) → Option Nat
  | _, [] => none
  | index, .failure :: _ => some index
  | index, .success _ :: rest => firstCallFailure (index + 1) rest

/-- Bounded execution of the pinned vault entrypoint. `initialBalance` is the
balance before the payable frame credit. Revert arms therefore expose exactly
that snapshot. On success, exact-fee validation makes the total CALL debit
equal `msg.value`; the explicit equality check is the modifier assertion. -/
def executeSourceBounded (fuel : Nat) (args : ConstructorArgs)
    (feeRead : ExternalResult Word) (callResults : List (ExternalResult Unit))
    (msgValue : Word) (sources targets : List Pubkey)
    (initialBalance : Nat) : SourceExecutionOutcome :=
  if !constructorConditions args then
    .reverted .invalidConstructor initialBalance
  else match feeRead with
    | .failure => .reverted .staticcallFailed initialBalance
    | .success fee =>
        match validateVaultAdd fee msgValue sources targets with
        | .error error => .reverted (.vaultGuard error) initialBalance
        | .ok pairs =>
            if pairs.length > fuel || callResults.length < pairs.length then
              .openExit
            else
              match firstCallFailure 0 (callResults.take pairs.length) with
              | some index => .reverted (.callFailed index) initialBalance
              | none =>
                  let finalBalance := initialBalance + msgValue.val -
                    pairs.length * fee.val
                  if finalBalance = initialBalance then
                    .committed pairs finalBalance
                  else .reverted (.vaultGuard
                    (.incorrectFee (word (pairs.length * fee.val)) msgValue))
                    initialBalance

/-- Named environmental obligation for the bounded model: execution reaches a
closed committed or reverted source exit, rather than exhausting fuel or an
underspecified CALL-result prefix. -/
def requireClosedExit (fuel : Nat) (args : ConstructorArgs)
    (feeRead : ExternalResult Word) (callResults : List (ExternalResult Unit))
    (msgValue : Word) (sources targets : List Pubkey)
    (initialBalance : Nat) : Prop :=
  executeSourceBounded fuel args feeRead callResults msgValue sources targets
    initialBalance ≠ .openExit

theorem constructor_failure_closes (fuel : Nat) (args : ConstructorArgs)
    (feeRead : ExternalResult Word) (callResults : List (ExternalResult Unit))
    (msgValue : Word) (sources targets : List Pubkey) (initialBalance : Nat)
    (h : constructorConditions args = false) :
    executeSourceBounded fuel args feeRead callResults msgValue sources targets
      initialBalance = .reverted .invalidConstructor initialBalance := by
  simp [executeSourceBounded, h]

theorem staticcall_failure_closes (fuel : Nat) (args : ConstructorArgs)
    (callResults : List (ExternalResult Unit)) (msgValue : Word)
    (sources targets : List Pubkey) (initialBalance : Nat)
    (h : constructorConditions args = true) :
    executeSourceBounded fuel args .failure callResults msgValue sources targets
      initialBalance = .reverted .staticcallFailed initialBalance := by
  simp [executeSourceBounded, h]

/-- Constructor rejection and fee `STATICCALL` failure discharge the named
closure obligation without consuming loop fuel or requiring any CALL results.
This keeps the two pre-loop source failures visibly distinct from an open
bounded exit. -/
theorem preloop_failures_requireClosedExit (fuel : Nat)
    (args : ConstructorArgs) (callResults : List (ExternalResult Unit))
    (msgValue : Word) (sources targets : List Pubkey) (initialBalance : Nat) :
    (constructorConditions args = false →
      requireClosedExit fuel args (.success (word 0)) callResults msgValue
        sources targets initialBalance) ∧
    (constructorConditions args = true →
      requireClosedExit fuel args .failure callResults msgValue sources targets
        initialBalance) := by
  constructor
  · intro hconstructor
    unfold requireClosedExit
    rw [constructor_failure_closes (h := hconstructor)]
    simp
  · intro hconstructor
    unfold requireClosedExit
    rw [staticcall_failure_closes (h := hconstructor)]
    simp

/-- The named closed-exit obligation yields the source-level atomicity and
`preservesEthBalance` correspondence: every closed failure restores the entry
snapshot, while every commit satisfies the modifier's balance equality. -/
theorem closed_exit_atomicity_and_preservesEthBalance
    (fuel : Nat) (args : ConstructorArgs) (feeRead : ExternalResult Word)
    (callResults : List (ExternalResult Unit)) (msgValue : Word)
    (sources targets : List Pubkey) (initialBalance : Nat)
    (hclosed : requireClosedExit fuel args feeRead callResults msgValue sources
      targets initialBalance) :
    (∃ error, executeSourceBounded fuel args feeRead callResults msgValue sources
        targets initialBalance = .reverted error initialBalance) ∨
      (∃ pairs, executeSourceBounded fuel args feeRead callResults msgValue
          sources targets initialBalance = .committed pairs initialBalance) := by
  unfold requireClosedExit at hclosed
  cases hrun : executeSourceBounded fuel args feeRead callResults msgValue sources
      targets initialBalance with
  | openExit => exact False.elim (hclosed hrun)
  | reverted error balance =>
      left
      refine ⟨error, ?_⟩
      have hbalance : balance = initialBalance := by
        unfold executeSourceBounded at hrun
        split at hrun <;> simp_all
        next hconstructor =>
          cases feeRead <;> simp_all
          next fee =>
            cases hguard : validateVaultAdd fee msgValue sources targets <;>
              simp_all
            next pairs =>
              split at hrun <;> simp_all
              next hbound =>
                cases hfailure : firstCallFailure 0
                    (callResults.take pairs.length) <;> simp_all
                next => split at hrun <;> simp_all
      simp [hbalance] at hrun ⊢
  | committed pairs balance =>
      right
      refine ⟨pairs, ?_⟩
      have hbalance : balance = initialBalance := by
        unfold executeSourceBounded at hrun
        split at hrun <;> simp_all
        next hconstructor =>
          cases feeRead <;> simp_all
          next fee =>
            cases hguard : validateVaultAdd fee msgValue sources targets <;>
              simp_all
            next accepted =>
              split at hrun <;> simp_all
              next hbound =>
                cases hfailure : firstCallFailure 0
                    (callResults.take accepted.length) <;> simp_all
                next => split at hrun <;> simp_all
      simp [hbalance] at hrun ⊢

end audit.trio.consolidation
