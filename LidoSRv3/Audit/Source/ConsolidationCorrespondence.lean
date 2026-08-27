import Verity.Core

/-!
# Pinned consolidation-request correspondence

This is a source-shaped model of `lidofinance/core` at
`af095e48bbc1c3841c2c9936219c8461af01056b`, specifically

* `WithdrawalVault.addConsolidationRequests`, lines 199--208;
* `WithdrawalVaultEIP7685._addConsolidationRequests`, lines 56--73;
* `WithdrawalVaultEIP7685._callAddConsolidationRequest`, lines 113--121;
* `WithdrawalVaultEIP7685._requireExactFee`, lines 123--127; and
* `WithdrawalVaultEIP7685._validatePublicKey`, lines 97--101.

The model begins after the constructor nonzero-address guards and covers the
vault entrypoint: gateway authorization, nonempty equal-length arrays, exact
48-byte keys, checked `requestsCount * fee`, one value-bearing CALL of
`source ‖ target` per pair, and one `ConsolidationRequestAdded` event per
successful CALL. Gateway grouping, quota, SSZ witnesses, and refunds are
outside this slice. No Yul, EVM, runtime-bytecode, or cryptographic claim is
made.
-/

namespace LidoSRv3.Audit.SolidityConsolidation

open Verity

abbrev Word := Verity.Core.Uint256

def publicKeyBytes : Word := Verity.Core.Uint256.ofNat 48

def consolidationRequestAddress : Nat :=
  0x0000BBdDc7CE488642fb579F8B00f3a590007251

def consolidationRequestAddedTopic : Nat :=
  0x67fce43957b4e9e86198cf87c600a0a6c3de7d0f56b0571062d93a853e4e9f73

structure Request where
  source : Word
  target : Word
  sourceLen : Word
  targetLen : Word
  deriving DecidableEq, Repr

def validRequest (request : Request) : Bool :=
  request.sourceLen == publicKeyBytes && request.targetLen == publicKeyBytes

/-- Word-level `source ‖ target` payload. Each key is identified by a word
and independently required to be 48 bytes wide. -/
def payload (request : Request) : List Word :=
  [request.source, request.target]

/-- Swapped target then source payload; used only to prove packing order matters. -/
def swappedPayload (request : Request) : List Word :=
  [request.target, request.source]

theorem payload_ne_swapped (request : Request) (h : request.source ≠ request.target) :
    payload request ≠ swappedPayload request := by
  unfold payload swappedPayload
  intro heq
  injection heq with h1 _
  exact h h1

structure CallObs where
  target : Word
  value : Word
  input : List Word
  deriving DecidableEq, Repr

structure EventObs where
  topic : Word
  payload : List Word
  deriving DecidableEq, Repr

structure Observables where
  calls : List CallObs
  events : List EventObs
  payloads : List (List Word)
  requestCount : Nat
  feePaid : Word
  deriving DecidableEq, Repr

inductive SourceOutcome where
  | reverted (reason : String)
  | committed (obs : Observables)
  deriving DecidableEq, Repr

structure Inputs where
  caller : Word
  gateway : Word
  requestTarget : Word
  fee : Word
  msgValue : Word
  sources : List Word
  targets : List Word
  sourceLens : List Word
  targetLens : List Word
  deriving DecidableEq, Repr

def zipRequests (sources targets sourceLens targetLens : List Word) :
    Option (List Request) :=
  if sources.length = targets.length ∧
      sourceLens.length = sources.length ∧
      targetLens.length = targets.length then
    some ((sources.zip targets).zip (sourceLens.zip targetLens) |>.map
      fun p => Request.mk p.1.1 p.1.2 p.2.1 p.2.2)
  else
    none

/-- A successful zip produces exactly one `Request` per source (equivalently
per target/length, since the guard forces all four lists to the same
length). Used to transport `sources.length ≠ 0` onto `requests.length`. -/
theorem zipRequests_some_length {sources targets sourceLens targetLens : List Word}
    {requests : List Request}
    (h : zipRequests sources targets sourceLens targetLens = some requests) :
    requests.length = sources.length := by
  unfold zipRequests at h
  split at h
  · next hcond =>
      obtain ⟨h1, h2, h3⟩ := hcond
      injection h with h
      subst h
      simp [List.length_zip, h1, h2, h3]
  · cases h

def requestCall (target fee : Word) (request : Request) : CallObs :=
  { target := target, value := fee, input := payload request }

def requestEvent (request : Request) : EventObs :=
  { topic := Verity.Core.Uint256.ofNat consolidationRequestAddedTopic
    payload := payload request }

def swappedRequestCall (target fee : Word) (request : Request) : CallObs :=
  { target := target, value := fee, input := swappedPayload request }

def swappedCommitObservables (target fee msgValue : Word) (requests : List Request) :
    Observables :=
  { calls := requests.map (swappedRequestCall target fee)
    events := requests.map requestEvent
    payloads := requests.map swappedPayload
    requestCount := requests.length
    feePaid := msgValue }

def commitObservables (target fee msgValue : Word) (requests : List Request) :
    Observables :=
  { calls := requests.map (requestCall target fee)
    events := requests.map requestEvent
    payloads := requests.map payload
    requestCount := requests.length
    feePaid := msgValue }

theorem commitObservables_ne_swapped (target fee msgValue : Word)
    (requests : List Request)
    (hne : requests.length = 1)
    (hdist : ∀ r ∈ requests, r.source ≠ r.target) :
    commitObservables target fee msgValue requests ≠
      swappedCommitObservables target fee msgValue requests := by
  obtain ⟨r, hr⟩ := List.length_eq_one_iff.mp hne
  subst hr
  intro heq
  have hcalls := congrArg Observables.calls heq
  simp only [commitObservables, swappedCommitObservables, requestCall, swappedRequestCall,
    List.map_cons, List.map_nil] at hcalls
  injection hcalls with hcall _
  injection hcall with _ _ hinput
  exact payload_ne_swapped r (hdist r List.mem_cons_self) hinput

/-- Independent pinned-source interpreter. It does not call the Verity
transaction or any shared execution helper besides the constructors above. -/
def sourceRun (inputs : Inputs) : SourceOutcome :=
  if inputs.caller == inputs.gateway then
    if inputs.sources.length == 0 then
      .reverted "ZeroArgument(sourcePubkeys)"
    else
      match zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens with
      | none => .reverted "ArraysLengthMismatch"
      | some requests =>
          if requests.all validRequest then
            if (requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 : Bool) then
              if inputs.msgValue.val == requests.length * inputs.fee.val then
                .committed (commitObservables inputs.requestTarget inputs.fee
                  inputs.msgValue requests)
              else .reverted "IncorrectFee"
            else .reverted "Panic(0x11): checked multiplication overflow"
          else .reverted "InvalidPublicKeyLength"
  else .reverted "NotConsolidationGateway"

/-- **Model mutant: exact-fee guard dropped.** Identical to `sourceRun`
except the pinned `_requireExactFee` check (`inputs.msgValue.val ==
requests.length * inputs.fee.val`, `WithdrawalVaultEIP7685` 123--127) is
removed, so a gateway-authorized, nonempty, 48-byte-aligned batch commits
even when `msg.value` does not equal `count * fee` -- in particular a
`fee = 0` batch with nonzero `msg.value`, which still satisfies the
registered parent's `hGatewayAdmittedNonzero` premise. This mutant exists
only so that `fee_blind_commit_kill_line_refutes_parent` can refute the
registered parent's hypothesis-conditioned committed-arm conjunction on a
mutant of its own model; it is never the model of record. -/
def sourceRunFeeBlind (inputs : Inputs) : SourceOutcome :=
  if inputs.caller == inputs.gateway then
    if inputs.sources.length == 0 then
      .reverted "ZeroArgument(sourcePubkeys)"
    else
      match zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens with
      | none => .reverted "ArraysLengthMismatch"
      | some requests =>
          if requests.all validRequest then
            if (requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 : Bool) then
              .committed (commitObservables inputs.requestTarget inputs.fee
                inputs.msgValue requests)
            else .reverted "Panic(0x11): checked multiplication overflow"
          else .reverted "InvalidPublicKeyLength"
  else .reverted "NotConsolidationGateway"

theorem commitObservables_binds (target fee msgValue : Word)
    (requests : List Request) :
    let obs := commitObservables target fee msgValue requests
    obs.requestCount = requests.length ∧
      obs.feePaid = msgValue ∧
      obs.calls.length = requests.length ∧
      obs.events.length = requests.length ∧
      obs.payloads = requests.map payload ∧
      obs.calls.map (·.input) = requests.map payload ∧
      obs.events.map (·.payload) = requests.map payload := by
  simp [commitObservables, requestCall, requestEvent, payload]

/-- A committed source run binds one CALL and one event per pair, pays exactly
`msg.value`, and records `source ‖ target` as the memory payload. A revert
exposes no prefix of those effects.

`fee = 0` is not a revert of `sourceRun` itself: pinned `_requireExactFee`
(`WithdrawalVaultEIP7685` 123--127) is only `msg.value == count * fee`, so
in isolation a gateway-authorized nonempty 48-byte batch with `fee = 0` and
`msg.value = 0` commits (see `Tests/ConsolidationTxMutants.lean`'s
`_requireExactFee(0)` vector on the Verity transaction, which still holds).
Under the caller-supplied `hGatewayAdmittedNonzero` premise -- the gateway
entrypoint (`ConsolidationGateway.sol:189`) rejects `msg.value = 0` before
ever reaching this vault call, so any run this theorem is invoked on with
`caller = gateway` has `msg.value ≠ 0` -- the committed branch's own
`msg.value = count * fee` equality forces `fee ≠ 0` (a zero fee times a
nonempty batch is zero `msg.value`, contradicting the premise). That is the
`inputs.fee.val ≠ 0` conjunct below: it is a property of runs that satisfy
the hypothesis, not a change to `sourceRun`'s decision tree. Two negative
results pin this down. `gateway_admitted_nonzero_kill_line` is
premise-necessity evidence: dropped, the same conjunct is false of
`sourceRun` on a concrete free batch (whose witness violates the premise, so
it does not by itself refute the hypothesis-conditioned parent).
`fee_blind_commit_kill_line_refutes_parent` is the parent-refuting
kill-line: on the mutant interpreter `sourceRunFeeBlind` (exact-fee guard
dropped), a batch that satisfies the premise commits while the parent's
committed-arm conjunction is false of that commit. -/
theorem source_consolidation_preserves_eligibility_value_atomicity
    (inputs : Inputs)
    (hGatewayAdmittedNonzero : inputs.caller = inputs.gateway →
      inputs.msgValue.val ≠ 0) :
    (∀ obs, sourceRun inputs = .committed obs →
      ∃ requests,
        zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens = some requests ∧
        inputs.caller = inputs.gateway ∧
        inputs.sources.length ≠ 0 ∧
        requests.all validRequest = true ∧
        requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
        inputs.msgValue.val = requests.length * inputs.fee.val ∧
        inputs.fee.val ≠ 0 ∧
        obs = commitObservables inputs.requestTarget inputs.fee
          inputs.msgValue requests) ∧
    (∀ reason, sourceRun inputs = .reverted reason →
      ¬ (inputs.caller = inputs.gateway ∧
          inputs.sources.length ≠ 0 ∧
          ∃ requests,
            zipRequests inputs.sources inputs.targets
              inputs.sourceLens inputs.targetLens = some requests ∧
            requests.all validRequest = true ∧
            requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
            inputs.msgValue.val = requests.length * inputs.fee.val)) := by
  constructor
  · intro obs hobs
    unfold sourceRun at hobs
    split at hobs
    · next hCaller =>
        have hEq : inputs.caller = inputs.gateway := beq_iff_eq.mp hCaller
        have hMsgNonzero : inputs.msgValue.val ≠ 0 := hGatewayAdmittedNonzero hEq
        split at hobs
        · cases hobs
        · next hNonempty =>
            have hPos : inputs.sources.length ≠ 0 := by
              intro hlen
              simp [hlen] at hNonempty
            split at hobs
            · cases hobs
            · next requests hZip =>
                split at hobs
                · next hValid =>
                    split at hobs
                    · next hBoundB =>
                        have hBound :
                            requests.length * inputs.fee.val ≤
                              Verity.Core.MAX_UINT256 :=
                          of_decide_eq_true hBoundB
                        split at hobs
                        · next hFeeB =>
                            have hFee : inputs.msgValue.val =
                                requests.length * inputs.fee.val :=
                              beq_iff_eq.mp hFeeB
                            have hLenPos : requests.length ≠ 0 :=
                              zipRequests_some_length hZip ▸ hPos
                            have hFeeNonzero : inputs.fee.val ≠ 0 := by
                              intro hZeroFee
                              exact hMsgNonzero (by simp [hFee, hZeroFee])
                            injection hobs with hobs
                            exact ⟨requests, hZip, hEq, hPos, hValid,
                              hBound, hFee, hFeeNonzero, hobs.symm⟩
                        · cases hobs
                    · cases hobs
                · cases hobs
    · cases hobs
  · intro reason hrev hok
    rcases hok with ⟨hEq, hPos, requests, hZip, hValid, hBound, hFee⟩
    unfold sourceRun at hrev
    simp [hEq, hPos, hZip, hValid, hBound, hFee, beq_iff_eq] at hrev

/-- **Premise-necessity evidence for the registered `hGatewayAdmittedNonzero`
premise** (not the parent-refuting kill-line). Drop the premise and the
strengthened conjunct it earns -- "every committed run has a nonzero fee" --
is false of `sourceRun` unconditionally: a gateway-authorized, nonempty,
48-byte-aligned batch with `fee = 0` and `msg.value = 0` commits (pinned
`_requireExactFee(0)` passes). This is the same free-batch witness
`report/P-CONSOLIDATION-1.md` issue 18 and
`Tests/ConsolidationTxMutants.lean`'s `_requireExactFee(0)` vector exercise.
Scope note: `freeBatchWitness` has `caller = gateway` but `msg.value = 0`,
so it VIOLATES the parent's premise and therefore refutes only the
hypothesis-free projection of the parent's committed arm, not the
hypothesis-conditioned parent itself. The parent-refuting kill-line is
`fee_blind_commit_kill_line_refutes_parent` below, which keeps the premise
satisfied and falsifies the parent's committed-arm conjunction on the mutant
interpreter `sourceRunFeeBlind`. -/
private def freeBatchWitness : Inputs :=
  { caller := Verity.Core.Uint256.ofNat 7
    gateway := Verity.Core.Uint256.ofNat 7
    requestTarget := Verity.Core.Uint256.ofNat consolidationRequestAddress
    fee := Verity.Core.Uint256.ofNat 0
    msgValue := Verity.Core.Uint256.ofNat 0
    sources := [Verity.Core.Uint256.ofNat 11]
    targets := [Verity.Core.Uint256.ofNat 21]
    sourceLens := [publicKeyBytes]
    targetLens := [publicKeyBytes] }

theorem gateway_admitted_nonzero_kill_line :
    ¬ (∀ (inputs : Inputs) (obs : Observables),
        sourceRun inputs = .committed obs → inputs.fee.val ≠ 0) := by
  intro h
  have hcommit : sourceRun freeBatchWitness = .committed
      (commitObservables freeBatchWitness.requestTarget freeBatchWitness.fee
        freeBatchWitness.msgValue
        [{ source := Verity.Core.Uint256.ofNat 11
           target := Verity.Core.Uint256.ofNat 21
           sourceLen := publicKeyBytes, targetLen := publicKeyBytes }]) := by
    decide
  exact h freeBatchWitness _ hcommit (by decide)

/-- Concrete batch for the fee-blind mutant: gateway-authorized, one valid
48-byte pair, `fee = 0`, and `msg.value = 1`. Unlike `freeBatchWitness`,
this witness SATISFIES the registered parent's `hGatewayAdmittedNonzero`
premise (`caller = gateway → msg.value ≠ 0`), so the refutation below is in
scope for the hypothesis-conditioned parent. -/
private def feeBlindWitness : Inputs :=
  { caller := Verity.Core.Uint256.ofNat 7
    gateway := Verity.Core.Uint256.ofNat 7
    requestTarget := Verity.Core.Uint256.ofNat consolidationRequestAddress
    fee := Verity.Core.Uint256.ofNat 0
    msgValue := Verity.Core.Uint256.ofNat 1
    sources := [Verity.Core.Uint256.ofNat 11]
    targets := [Verity.Core.Uint256.ofNat 21]
    sourceLens := [publicKeyBytes]
    targetLens := [publicKeyBytes] }

/-- **Kill-line refuting the registered parent on a mutant of its own
model.** The registered parent
`source_consolidation_preserves_eligibility_value_atomicity` concludes, for
every `inputs` satisfying `hGatewayAdmittedNonzero` and every committed
`sourceRun inputs`, a conjunction whose `inputs.fee.val ≠ 0` conjunct is
earned by the exact-fee guard. On the mutant interpreter `sourceRunFeeBlind`
(that guard dropped, nothing else changed) the parent's hypothesis-conditioned
committed-arm predicate is FALSE: `feeBlindWitness` satisfies the premise
(`caller = gateway`, `msg.value = 1 ≠ 0`), the mutant commits it, every
fee-independent conjunct of the parent's committed arm still holds of that
commit (zip, caller, nonempty, 48-byte-valid, `uint256` bound, canonical
observables), yet `inputs.fee.val = 0`, so the full committed-arm
conjunction fails. Equivalently, the negated final conjunct below is the
negation of the parent's committed-arm predicate applied to the mutant
commit. This is the load-bearing bar's required shape: a counterexample
witness to the SAME hypothesis-conditioned predicate the parent proves,
evaluated on a mutant of the parent's own model -- not the hypothesis-free
projection that `gateway_admitted_nonzero_kill_line` covers. -/
theorem fee_blind_commit_kill_line_refutes_parent :
    ∃ (inputs : Inputs) (obs : Observables),
      (inputs.caller = inputs.gateway → inputs.msgValue.val ≠ 0) ∧
      sourceRunFeeBlind inputs = .committed obs ∧
      (∃ requests,
          zipRequests inputs.sources inputs.targets
            inputs.sourceLens inputs.targetLens = some requests ∧
          inputs.caller = inputs.gateway ∧
          inputs.sources.length ≠ 0 ∧
          requests.all validRequest = true ∧
          requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
          obs = commitObservables inputs.requestTarget inputs.fee
            inputs.msgValue requests) ∧
      inputs.fee.val = 0 ∧
      ¬ (∃ requests,
          zipRequests inputs.sources inputs.targets
            inputs.sourceLens inputs.targetLens = some requests ∧
          inputs.caller = inputs.gateway ∧
          inputs.sources.length ≠ 0 ∧
          requests.all validRequest = true ∧
          requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
          inputs.msgValue.val = requests.length * inputs.fee.val ∧
          inputs.fee.val ≠ 0 ∧
          obs = commitObservables inputs.requestTarget inputs.fee
            inputs.msgValue requests) := by
  refine ⟨feeBlindWitness,
    commitObservables feeBlindWitness.requestTarget feeBlindWitness.fee
      feeBlindWitness.msgValue
      [{ source := Verity.Core.Uint256.ofNat 11
         target := Verity.Core.Uint256.ofNat 21
         sourceLen := publicKeyBytes, targetLen := publicKeyBytes }],
    fun _ => by native_decide, by native_decide,
    ⟨[{ source := Verity.Core.Uint256.ofNat 11
        target := Verity.Core.Uint256.ofNat 21
        sourceLen := publicKeyBytes, targetLen := publicKeyBytes }],
      by native_decide, by native_decide, by native_decide, by native_decide,
      by native_decide, rfl⟩,
    by native_decide, ?_⟩
  rintro ⟨requests, _, _, _, _, _, _, hFeeNe, _⟩
  exact hFeeNe (by native_decide)

end LidoSRv3.Audit.SolidityConsolidation
