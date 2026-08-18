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

def requestCall (target fee : Word) (request : Request) : CallObs :=
  { target := target, value := fee, input := payload request }

def requestEvent (request : Request) : EventObs :=
  { topic := Verity.Core.Uint256.ofNat consolidationRequestAddedTopic
    payload := payload request }

def commitObservables (target fee msgValue : Word) (requests : List Request) :
    Observables :=
  { calls := requests.map (requestCall target fee)
    events := requests.map requestEvent
    payloads := requests.map payload
    requestCount := requests.length
    feePaid := msgValue }

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
exposes no prefix of those effects. -/
theorem source_consolidation_preserves_eligibility_value_atomicity
    (inputs : Inputs) :
    (∀ obs, sourceRun inputs = .committed obs →
      ∃ requests,
        zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens = some requests ∧
        inputs.caller = inputs.gateway ∧
        inputs.sources.length ≠ 0 ∧
        requests.all validRequest = true ∧
        requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
        inputs.msgValue.val = requests.length * inputs.fee.val ∧
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
                            injection hobs with hobs
                            exact ⟨requests, hZip, hEq, hPos, hValid, hBound,
                              hFee, hobs.symm⟩
                        · cases hobs
                    · cases hobs
                · cases hobs
    · cases hobs
  · intro reason hrev hok
    rcases hok with ⟨hEq, hPos, requests, hZip, hValid, hBound, hFee⟩
    unfold sourceRun at hrev
    simp [hEq, hPos, hZip, hValid, hBound, hFee, beq_iff_eq] at hrev

end LidoSRv3.Audit.SolidityConsolidation
