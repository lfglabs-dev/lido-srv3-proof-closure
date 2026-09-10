import audit.trio.consolidation.Spec

/-!
# Bounded consolidation source execution

An independent, hand-authored bounded model component for part of the external
control surface in the
vault path pinned at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `WithdrawalVault` constructor, lines 63--78 (both immutable addresses are
  nonzero), and `WithdrawalVaultEIP7685` constructor, lines 34--40;
* `_getFeeFromContract`, lines 83--95 (the fee `STATICCALL` may fail);
* `_callAddConsolidationRequest`, lines 113--121 (any value-bearing `CALL`
  may fail and reverts the whole entrypoint); and
* `preservesEthBalance`, `WithdrawalVault.sol` lines 81--85.

The constructors are deployment-time checks, not guards rerun by the runtime
entrypoint.  The runtime model below therefore takes an explicit deployment
witness and checks the caller before the inherited body. `feeRead` and
`callResults` are supplied outcomes: this file
does not interpret real `STATICCALL`/`CALL`, returndata, revert propagation,
events, EVM rollback, code identity, or deployment provenance.

At that pin, runtime error precedence is `NotConsolidationGateway`, then
`ZeroArgument`, `ArraysLengthMismatch`, `FeeReadFailed`/`FeeInvalidData`,
checked fee-multiplication overflow, `IncorrectFee`, source/target
`InvalidPublicKeyLength`, and finally `RequestAdditionFailed`. The supplied
`feeRead : ExternalResult Word` starts after the returndata-shape check, so its
failure arm represents `FeeReadFailed`; `FeeInvalidData` remains outside this
component rather than being silently claimed.

The model is intentionally not an error-faithful interpreter. In particular,
it consumes `feeRead` before calling the separately defined pure guard model,
whereas Solidity checks the empty and array-length guards before the
`STATICCALL`. Also, its synthetic final-balance mismatch is represented with a
`VaultError.incorrectFee`; pinned Solidity would fail the modifier's `assert`
with a panic after the body. These guard-order and modifier-failure differences
are residuals, not correspondence claims.

`requireClosedExit` is deliberately named: a finite result list and fuel bound
are evidence that every external request reached a success/failure response.
It is an obligation, not an axiom or a trust-manifest escape.

Consequently, the theorem in this file is only an invariant of this bounded
model component. It is not real source-level execution correspondence and does
not identify this model with the independent specification in `Spec.lean`, nor
does it close the remaining execution or Bus/Gateway/Vault composition
obligations.
-/

namespace audit.trio.consolidation

structure ConstructorArgs where
  lido : Word
  treasury : Word
  triggerableWithdrawalsGateway : Word
  consolidationGateway : Word
  withdrawalRequest : Word
  consolidationRequest : Word
  deriving DecidableEq, Repr

def constructorConditions (args : ConstructorArgs) : Bool :=
  -- Solidity runs the base constructor first, then the derived constructor.
  args.withdrawalRequest.val != 0 && args.consolidationRequest.val != 0 &&
    args.lido.val != 0 && args.treasury.val != 0 &&
    args.triggerableWithdrawalsGateway.val != 0 &&
    args.consolidationGateway.val != 0

/-- Successful construction is a premise of runtime execution. This witness
does not establish which bytecode was deployed at any address. -/
structure DeployedVault where
  args : ConstructorArgs
  constructorAccepted : constructorConditions args = true

inductive ExternalResult (α : Type) where
  | success (value : α)
  | failure
  deriving DecidableEq, Repr

inductive SourceExecutionError where
  | notConsolidationGateway
  | staticcallFailed
  | vaultGuard (error : VaultError)
  | invalidPubkey
  | callFailed (index : Nat)
  deriving DecidableEq, Repr

inductive SourceExecutionOutcome where
  /-- The bound or supplied external-result prefix did not close the loop. -/
  | openExit
  /-- All source failures roll the payable credit and prior calls back. -/
  | reverted (error : SourceExecutionError) (vaultBalance : Nat)
  /-- The modifier accepted the final balance. Each committed pair is the
  caller-side `(source, target)` and the matching 96-byte callee payload
  `abi.encodePacked(sourcePubkey, targetPubkey)`. -/
  | committed (pairs : List (Pubkey × Pubkey)) (payloads : List (List Nat))
      (vaultBalance : Nat)
  deriving DecidableEq, Repr

private def firstCallFailure : Nat → List (ExternalResult Unit) → Option Nat
  | _, [] => none
  | index, .failure :: _ => some index
  | index, .success _ :: rest => firstCallFailure (index + 1) rest

/-- Bounded component for the pinned runtime entrypoint. `initialBalance` is the
balance before the payable frame credit. Revert arms therefore expose exactly
that supplied snapshot. This representation of rollback is definitional, not a
proof about EVM rollback. On success, exact-fee validation makes the modeled
CALL debit equal `msg.value`; the explicit equality check represents the
modifier assertion. -/
def executeSourceBounded (fuel : Nat) (deployment : DeployedVault)
    (caller : Word)
    (feeRead : ExternalResult Word) (callResults : List (ExternalResult Unit))
    (msgValue : Word) (sources targets : List Pubkey)
    (initialBalance : Nat) : SourceExecutionOutcome :=
  if caller != deployment.args.consolidationGateway then
    .reverted .notConsolidationGateway initialBalance
  else match feeRead with
    | .failure => .reverted .staticcallFailed initialBalance
    | .success fee =>
        match validateVaultAdd fee msgValue sources targets with
        | .error error => .reverted (.vaultGuard error) initialBalance
        | .ok pairs =>
            -- Callee input of `_callAddConsolidationRequest` is the packed
            -- 96-byte blob, not the word identity. Wrapping identities are
            -- not 48-byte keys and cannot form a payload.
            match packedPayloads pairs with
            | none => .reverted .invalidPubkey initialBalance
            | some payloads =>
                if pairs.length > fuel || callResults.length < pairs.length then
                  .openExit
                else
                  match firstCallFailure 0 (callResults.take pairs.length) with
                  | some index => .reverted (.callFailed index) initialBalance
                  | none =>
                      let finalBalance := initialBalance + msgValue.val -
                        pairs.length * fee.val
                      if finalBalance = initialBalance then
                        .committed pairs payloads finalBalance
                      else .reverted (.vaultGuard
                        (.incorrectFee (word (pairs.length * fee.val)) msgValue))
                        initialBalance

/-- Named environmental obligation for the bounded model: execution reaches a
closed committed or reverted source exit, rather than exhausting fuel or an
underspecified CALL-result prefix. -/
def requireClosedExit (fuel : Nat) (deployment : DeployedVault) (caller : Word)
    (feeRead : ExternalResult Word) (callResults : List (ExternalResult Unit))
    (msgValue : Word) (sources targets : List Pubkey)
    (initialBalance : Nat) : Prop :=
  executeSourceBounded fuel deployment caller feeRead callResults msgValue sources targets
    initialBalance ≠ .openExit

/-- Caller/callee boundary: a committed hop's payloads are exactly the
96-byte packed blobs of the accepted pairs. Wrapping identities never
reach this constructor. -/
theorem committed_payloads_are_packed
    (fuel : Nat) (deployment : DeployedVault) (caller : Word)
    (feeRead : ExternalResult Word) (callResults : List (ExternalResult Unit))
    (msgValue : Word) (sources targets : List Pubkey) (initialBalance : Nat)
    (pairs : List (Pubkey × Pubkey)) (payloads : List (List Nat))
    (balance : Nat)
    (h : executeSourceBounded fuel deployment caller feeRead callResults
        msgValue sources targets initialBalance =
          .committed pairs payloads balance) :
    packedPayloads pairs = some payloads ∧
      payloads.length = pairs.length ∧
      ∀ payload ∈ payloads, payload.length = 96 := by
  unfold executeSourceBounded at h
  split at h
  · contradiction
  next hconstructor =>
    cases feeRead with
    | failure => simp at h
    | success fee =>
        cases hguard : validateVaultAdd fee msgValue sources targets with
        | error _ => simp [hguard] at h
        | ok accepted =>
            simp [hguard] at h
            cases hpayloads : packedPayloads accepted with
            | none => simp [hpayloads] at h
            | some acceptedPayloads =>
                simp [hpayloads] at h
                split at h
                · contradiction
                next hbound =>
                  cases hfailure : firstCallFailure 0
                      (callResults.take accepted.length) with
                  | some _ => simp [hfailure] at h
                  | none =>
                      simp [hfailure] at h
                      split at h
                      · next =>
                          injection h with hpairs hpayloadsEq _
                          have heach := packedPayloads_each_96 accepted acceptedPayloads hpayloads
                          rw [← hpairs, ← hpayloadsEq]
                          exact ⟨hpayloads, heach.1, heach.2⟩
                      · contradiction

theorem unauthorized_caller_closes (fuel : Nat) (deployment : DeployedVault)
    (caller : Word) (feeRead : ExternalResult Word)
    (callResults : List (ExternalResult Unit)) (msgValue : Word)
    (sources targets : List Pubkey) (initialBalance : Nat)
    (h : caller ≠ deployment.args.consolidationGateway) :
    executeSourceBounded fuel deployment caller feeRead callResults msgValue
      sources targets initialBalance =
        .reverted .notConsolidationGateway initialBalance := by
  simp [executeSourceBounded, h]

theorem staticcall_failure_closes (fuel : Nat) (deployment : DeployedVault)
    (caller : Word)
    (callResults : List (ExternalResult Unit)) (msgValue : Word)
    (sources targets : List Pubkey) (initialBalance : Nat)
    (h : caller = deployment.args.consolidationGateway) :
    executeSourceBounded fuel deployment caller .failure callResults msgValue sources targets
      initialBalance = .reverted .staticcallFailed initialBalance := by
  simp [executeSourceBounded, h]

/-- Caller rejection and fee `STATICCALL` failure discharge the named
closure obligation without consuming loop fuel or requiring any CALL results.
This keeps the two pre-loop source failures visibly distinct from an open
bounded exit. -/
theorem preloop_failures_requireClosedExit (fuel : Nat)
    (deployment : DeployedVault) (caller : Word)
    (callResults : List (ExternalResult Unit))
    (msgValue : Word) (sources targets : List Pubkey) (initialBalance : Nat) :
    (caller ≠ deployment.args.consolidationGateway →
      requireClosedExit fuel deployment caller (.success (word 0)) callResults msgValue
        sources targets initialBalance) ∧
    (caller = deployment.args.consolidationGateway →
      requireClosedExit fuel deployment caller .failure callResults msgValue sources targets
        initialBalance) := by
  constructor
  · intro hconstructor
    unfold requireClosedExit
    rw [unauthorized_caller_closes (h := hconstructor)]
    simp
  · intro hconstructor
    unfold requireClosedExit
    rw [staticcall_failure_closes (h := hconstructor)]
    simp

/-- The named closed-exit obligation yields a bounded-model invariant: every
modeled failure contains the supplied entry snapshot, while every modeled
commit satisfies the represented final-balance equality. It establishes no
Solidity/EVM execution correspondence or rollback fact. -/
theorem closed_exit_bounded_model_balance_invariant
    (fuel : Nat) (deployment : DeployedVault) (caller : Word)
    (feeRead : ExternalResult Word)
    (callResults : List (ExternalResult Unit)) (msgValue : Word)
    (sources targets : List Pubkey) (initialBalance : Nat)
    (hclosed : requireClosedExit fuel deployment caller feeRead callResults msgValue sources
      targets initialBalance) :
    (∃ error, executeSourceBounded fuel deployment caller feeRead callResults msgValue sources
        targets initialBalance = .reverted error initialBalance) ∨
      (∃ pairs payloads, executeSourceBounded fuel deployment caller feeRead callResults
          msgValue sources targets initialBalance =
            .committed pairs payloads initialBalance) := by
  unfold requireClosedExit at hclosed
  cases hrun : executeSourceBounded fuel deployment caller feeRead callResults msgValue sources
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
              cases hpayloads : packedPayloads pairs <;> simp_all
              next payloads =>
                split at hrun <;> simp_all
                next hbound =>
                  cases hfailure : firstCallFailure 0
                      (callResults.take pairs.length) <;> simp_all
                  next => split at hrun <;> simp_all
      simp [hbalance] at hrun ⊢
  | committed pairs payloads balance =>
      right
      refine ⟨pairs, payloads, ?_⟩
      have hbalance : balance = initialBalance := by
        unfold executeSourceBounded at hrun
        split at hrun <;> simp_all
        next hconstructor =>
          cases feeRead <;> simp_all
          next fee =>
            cases hguard : validateVaultAdd fee msgValue sources targets <;>
              simp_all
            next accepted =>
              cases hpayloads : packedPayloads accepted <;> simp_all
              next acceptedPayloads =>
                split at hrun <;> simp_all
                next hbound =>
                  cases hfailure : firstCallFailure 0
                      (callResults.take accepted.length) <;> simp_all
                  next => split at hrun <;> simp_all
      simp [hbalance] at hrun ⊢

end audit.trio.consolidation
